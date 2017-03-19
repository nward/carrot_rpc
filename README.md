<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [CarrotRpc](#carrotrpc)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [Server](#server)
    - [Client](#client)
  - [Usage](#usage)
    - [Writing Servers](#writing-servers)
    - [Writing Clients](#writing-clients)
      - [Using request threading in clients](#using-request-threading-in-clients)
      - [Errors](#errors)
    - [Support for JSONAPI::Resources](#support-for-jsonapiresources)
  - [Development](#development)
  - [Contributing](#contributing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# CarrotRpc

An opinionated approach to doing Remote Procedure Call (RPC) with RabbitMQ and the bunny gem. CarrotRpc serves as a way to streamline the RPC workflow so developers can focus on the implementation and not the plumbing when working with RabbitMQ.

[![Code Climate](https://codeclimate.com/github/C-S-D/carrot_rpc/badges/gpa.svg)](https://codeclimate.com/github/C-S-D/carrot_rpc)
[![Circle CI](https://circleci.com/gh/C-S-D/carrot_rpc.svg?style=svg)](https://circleci.com/gh/C-S-D/carrot_rpc)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'carrot_rpc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install carrot_rpc

## Configuration
There's two modes for CarrotRpc: server and client. The server is run via command line, and the client is run in your ruby application during the request / response lifecycle (like your Rails Controller).
### Server
The server is configured via command line and run in it's own process. Note: the server process will attempt to start a connection with Bunny automatically.

Carrot is easy to run via command line:
```bash
carrot_rpc
```
By typing in `carrot_rpc -h` you will see all the command line options:
```bash
Usage: server [options]

Process options:
    -d, --daemonize               run daemonized in the background (default: false)
        --pidfile PIDFILE         the pid filename
        --autoload_rails VALUE    loads rails env by default. Uses Rails Logger by default.
        --logfile VALUE           relative path and name for Log file. Overrides Rails logger.
        --loglevel VALUE          levels of loggin: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
        --rabbitmq_url VALUE      connection string to RabbitMQ 'amqp://user:pass@host:10000/vhost'
        --thread-request VARIABLE Copies the current request into VARIABLE Thread local variable, where it can be retrieved with `Thread.thread_variable_get(<VARIABLE>)`

Ruby options:
    -I, --include PATH            an additional $LOAD_PATH
        --debug                   set $DEBUG to true
        --warn                    enable warnings

Common options:
    -h, --help
    -v, --version
```


### Client
Clients are configured by initializing `CarrotRpc::Configuration`. The most common way in Rails is to setup an initializer in `/config/initializers/carrot_rpc.rb`

```ruby
CarrotRpc.configure do |config|
  # Required on the client to connect to RabbitMQ.
  # Bunny defaults to connecting to ENV['RABBITMQ_URL']. See Bunny docs.
  config.bunny = Bunny.new
  # Set the log level. Ruby Logger Docs http://ruby-doc.org/stdlib-2.2.0/libdoc/logger/rdoc/Logger.html
  config.loglevel = Logger::INFO
  # Create a new logger or use the Rails logger.
  # When using Rails, use a tagged log to make it easier to track RPC.
  config.logger = CarrotRpc::TaggedLog.new(logger: Rails.logger, tags: ["Carrot RPC Client"])
  # Set a Proc to allow manipulation of the params on the RpcClient before the request is sent.
  config.before_request = proc { |params| params.merge(foo: "bar") }
  # Number of seconds to wait before a RPC Client request timesout. Default 5 seconds.
  config.rpc_client_timeout = 5
  # Formats hash keys to stringified and replaces "_" with "-". Default is `:none` for no formatting.
  config.rpc_client_request_key_format = :dasherize
  # Formats hash keys to stringified and replaces "-" with "_". Default is `:none` for no formatting.
  config.rpc_client_response_key_format = :underscore

  # Don't use. Server implementation only. The values below are set via CLI:
  # config.logfile = nil
  # config.pidfile = nil
  # config.thread_request_variable = nil
end
```

Depending upon your webserver of choice you'll want to make sure that the conneciton to RabbitMQ via Bunny is made after the server Process forks because Bunny immediately threads after the `start()` method.

Here's an example of how to do so with Puma.

```ruby
# config/puma.rb

on_worker_boot do
  CarrotRpc.configure do |config|
    # Each worker should have it's own connection to RabbitMQ.
    config.bunny = Bunny.new
  end
  CarrotRpc.connect
end
```

Similarly with Sidekiq
```ruby
# config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  CarrotRpc.connect
end
```

If you want to run RpcClient in the rails console, you'll want to make a connection only on Rails console start.
```ruby
# config/application.rb

module FooApplication
  class Application < Rails::Application
    # Only attempt to connect with Bunny in the console!!!
    console do
      CarrotRpc.connect
    end
  end
end
```

## Usage
### Writing Servers
Carrot CLI will look for your servers in `app/servers` directory. This directory should not be autoloaded by the host application. Very important to declare the name of the queue with `queue_name`. The name must be the same as what's implemented in the `Client`.


Example Server: `app/servers/car_server.rb`
```ruby
class CarServer < CarrotRpc::RpcServer
  queue_name "car_queue"

  def show(params)
    # ...do something
    Car.find(params[:id]).to_json
  end
end
```
The method can return any data that can be stringified. But CarrotRPC uses [JSON RPC 2.0](http://www.jsonrpc.org/specification) as protocol for the message workflow.

With a standard Rails configuration `app/servers` will be marked as `eager_load: true` because `app` is `eager_load: true`.  This is a problem because `Rails.application.eager_load!` is called when running `carrot_rpc`, which would lead to `app/servers/**/*.rb` being double loaded.  To prevent the double loading, `app/servers` itself needs to be added as
a non-eager-load path, but still a load path.

In `config/application.rb`
```ruby
module MyApp
  class Application < Rails::Application
    config.paths.add "app/servers",
                     # `app/servers` MUST NOT be an eager_load path (to override the setting inherited from "app"), so
                     # that `carrot_rpc` does not double load `app/servers/**/*.rb` when first loading Rails and the
                     # servers.
                     eager_load: false,
                     # A load path so `carrot_rpc` can find load path ending in `app/servers` to scan for servers to
                     # load
                     load_path: true
  end
end
```

### Writing Clients
Clients are not run in the CLI, and are typlically invoked during a request / response lifecycle in a web application. In the case of Rails, Clients would most likely be used in a controller action. Clients should be written in the `app/clients` directory of the host application, and should be autoloaded by Rails. The name of the queue to send messages to must be declared with `queue_name`.

Example Client: `app/clients/cars_client.rb`
```ruby
  class CarClient < CarrotRpc::RpcClient
    queue_name "car_queue"
    # optional hook to modify params before submission
    before_request proc { |params| params.merge(foo: "bar") }

    # By default RpcClient defines the following Railsy inspired methods:
    # def show(params)
    # def index(params)
    # def create(params)
    # def update(params)
    # You can easily add your own like so:
    def foo_method(params)
      remote_call('foo_method', params)
    end
  end
```

Example Rails Controller:
```ruby
class CarsController < ApplicationController
  queue_name "car_queue"

  def show
    car_client = CarClient.new
    result = car_client.show({id: 1})
  end
end
```

One way to implement a RpcClient is to override the default configuration.
```ruby
config = CarrotRPC.configuration.clone
# Now only this one object will format keys as dashes
config.rpc_client_response_key_format = :dasherize

car_client = CarClient.new(config)
```
By duplicating the `Configuration` instance you can override the global configuration and pass a custom configuration to the RpcClient instance.

#### Using request threading in clients

If you run the server with `--thread-request VARIABLE`, you can retrieve that variable in the `before_request` callback, such as to pass along important meta data:

```sh
carrot_rpc --thread-request carrot_rpc_server_request_message
```

Example Client: `app/clients/profile_client.rb`
```
# Allows calls to other RPC server's profile resource.
class ProfileClient < CarrotRpc::RpcClient
  before_request ->(params){
    request_message = Thread.current.thread_variable_get(:carrot_rpc_server_request_message)

    if request_message
      meta = params[:meta] || {}
      # beam is test meta data specific to Elixir
      meta = meta.merge(beam: request_message[:params][:meta][:beam])
      params.merge(meta: meta)
    else
      params
    end
  }
end
```

#### Errors
If a JSON-RPC error is returned, a CarrotRpc::Error exception is raised with the appropriate attributes set. If a malformed JSON-RPC error is returned (i.e. code or message are missing), an CarrotRpc::Exception::InvalidResponse exception is raised.

### Support for JSONAPI::Resources
In the case that you're writing an application that uses the `jsonapi-resources` gem and you want the `RpcServer` to have the same functionality, then we got you covered. All you need to do is import a few modules. See [jsonapi-resources](https://github.com/cerebris/jsonapi-resources) for details on how to implement resources for your models.

Example Server with JSONAPI functionality:
```ruby
class CarServer < CarrotRpc::RpcServer
  extend CarrotRpc::RpcServer::JSONAPIResources::Actions
  include CarrotRpc::RpcServer::JSONAPIResources

  # declare the actions to enable
  actions: :create, :destroy, :index, :show, :update

  # Context so it can build urls
  def base_url
    "http://foo.com"
  end

  # Context to find the resource and create links.
  def controller
    "api/cars"
  end

  # JSONAPI::Resource example: `app/resources/car_resource.rb`
  def resource_klass
    CarResource
  end

  queue_name "car_queue"

  def show(params)
    # ...do something
    Car.find(params[:id]).to_json
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/carrot_rpc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
