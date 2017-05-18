<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Changelog](#changelog)
  - [v1.0.0](#v100)
    - [Incompatible Changes](#incompatible-changes)
  - [v0.8.1](#v081)
    - [Enhancements](#enhancements)
  - [v0.8.0](#v080)
    - [Enhancements](#enhancements-1)
  - [v0.7.1](#v071)
    - [Bug Fixes](#bug-fixes)
  - [v0.7.0](#v070)
    - [Bug Fixes](#bug-fixes-1)
    - [Incompatible Changes](#incompatible-changes-1)
  - [v0.6.0](#v060)
    - [Enhancements](#enhancements-2)
  - [v0.5.1](#v051)
    - [Bug Fixes](#bug-fixes-2)
  - [v0.5.0](#v050)
    - [Enhancements](#enhancements-3)
    - [Incompatible Changes](#incompatible-changes-2)
  - [v0.4.1](#v041)
    - [Bug Fixes](#bug-fixes-3)
  - [v0.4.0](#v040)
    - [Enhancements](#enhancements-4)
    - [Bug Fixes](#bug-fixes-4)
    - [Incompatible Changes](#incompatible-changes-3)
  - [v0.3.0](#v030)
    - [Enhancements](#enhancements-5)
    - [Bug Fixes](#bug-fixes-5)
  - [v0.2.3](#v023)
    - [Enhancements](#enhancements-6)
    - [Bug Fixes](#bug-fixes-6)
    - [Upgrading](#upgrading)
  - [v0.2.1](#v021)
    - [Bug Fixes](#bug-fixes-7)
  - [v0.2.0](#v020)
    - [Enhancements](#enhancements-7)
    - [Bug Fixes](#bug-fixes-8)
    - [Incompatible Changes](#incompatible-changes-4)
  - [v0.1.2](#v012)
    - [Enhancements](#enhancements-8)
    - [Bug Fixes](#bug-fixes-9)
  - [v0.1.1](#v011)
    - [Enhancements](#enhancements-9)
    - [Bug Fixes](#bug-fixes-10)
    - [Incompatible Changes](#incompatible-changes-5)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Changelog
All significant changes in the project are documented here.

## v1.0.0
### Incompatible Changes
* [#48](https://github.com/C-S-D/carrot_rpc/pull/48) - Remove queue for correlation_id when RpcClient#wait_for_result raises an exception. -[@nward](https://github.com/nward)
* [#50](https://github.com/C-S-D/carrot_rpc/pull/50) - Raise an exception for error responses to let consuming application handle response. -[@nward](https://github.com/nward)
* [#52](https://github.com/C-S-D/carrot_rpc/pull/52) - Allow custom queue options to be set -[@nward](https://github.com/nward)
* [#53](https://github.com/C-S-D/carrot_rpc/pull/53) - Rename keys for any hashes inside arrays. Fixes issue [#35](https://github.com/C-S-D/carrot_rpc/issues/35) -[@thewalkingtoast](https://github.com/thewalkingtoast)

## v0.8.1
### Enhancements
* Update to Ruby 2.2.6 and have tests run for Ruby 2.3 and 2.4.

## v0.8.0
### Enhancements
* Don't assume that Bunny already has a connection to RabbitMQ.
* Attempt to start Bunny for the servers
* This allows the implementing application to decide when to start the connection when using a forking web server

## v0.7.1
### Bug Fixes
* [#40](https://github.com/C-S-D/carrot_rpc/pull/41) - Deletes Queues immediately after the last consumer is unsubscribed. Reduces memory load. API remains the same. - [@shamil614](https://github.com/C-S-D/carrot_rpc/pull/34)

## v0.7.0
### Bug Fixes
* [#38](https://github.com/C-S-D/carrot_rpc/pull/38) - The `until quit` busy-wait loop consumes ~1 core for each instance of `carrot_rpc` as the default `sleep 0` does the minimal amount of sleep before waking up to check the boolean `quit`.  I've replaced it with an `IO.pipe` and `IO.select` that does not consume any resources while it waits. **NOTE: A Queue could not be used here because the MRI VM blocks use of Mutexes inside signal handlers to prevent deadlocks because the Mutex code is not-reentrant (i.e signal-interrupt-safe).  If a Queue is used the thread silently fails with an exception and the signal is ignored.** - [@KronicDeth](https://github.com/KronicDeth)

### Incompatible Changes
* [#38](https://github.com/C-S-D/carrot_rpc/pull/38) - Removal of the busy-wait removes the `-s` (`--runloop_sleep`) option as it is no longer needed. - [@KronicDeth](https://github.com/KronicDeth)

## v0.6.0
### Enhancements
* [#34](https://github.com/C-S-D/carrot_rpc/pull/34) - `--server_test_mode` options for `carrot_rpc` sets `CarrotRpc.configuration.server_test_mode` to `true`.  When `server_test_mode` is true, `_test` is appended to the queue name used by `CarrotRpc::RpcServer` and `CarrotRpc::RpcClient`, so that tests don't use the same queue as production or development. - [@shamil614](https://github.com/C-S-D/carrot_rpc/pull/34)
* [#36](https://github.com/C-S-D/carrot_rpc/pull/36) - Request in thread-local variable, so it can be used for client request - [@KronicDeth](https://github.com/KronicDeth)  
  * `carrot_rpc --thread-request VARIABLE` allows the request payload to be put in a Thread-local `VARIABLE, so that client that are invoked during an RPC server request can use parts of the request, most importantly, parts of "meta" in their own requests. This is needed to pass along ownership information for db_connection in Ecto 2.0.
  * Tag the log with the correlation_id, as it can be filtered for then.
  * Clarify whether a request or response is being published or received, so that server vs client logging can be distinguished.

## v0.5.1
### Bug Fixes
* [#31](https://github.com/C-S-D/carrot_rpc/pull/31) - If the server does not respond to a method in the `request_message`, then return a "Method not found" JSONRPC 2.0 error instead of the server crashing with `NoMethodError` exception. - [@KronicDeth](https://github.com/KronicDeth)

## v0.5.0
### Enhancements
* [#25](https://github.com/C-S-D/carrot_rpc/pull/25) - [@shamil614](https://github.com/shamil614)
  * Timeout RpcClient requests when response is not received. 
  * Default timeout is 5 seconds.
  * Timeout is configurable.
* [#27](https://github.com/C-S-D/carrot_rpc/pull/27) - [@shamil614](https://github.com/shamil614)
  * Simplify RpcClient usage.
  * Each request which goes through `RpcClient.remote_request` ultimately needs to use a unique `reply_queue` on eqch request.
  * By closing the channel and opening a new channel on each request we ensure that cleanup takes place by the deletion of the `reply_queue`.
* [#29](https://github.com/C-S-D/carrot_rpc/pull/29) - [@shamil614](https://github.com/shamil614)
  * Implementations of the RpcClient need to be flexible with the key formatter.
  * Formatting can be set globally via `Configuration`, overridden via passing Configuration object upon initializing client, or redefine `response_key_formatter` `request_key_formatter` methods.

### Incompatible Changes
* [#27](https://github.com/C-S-D/carrot_rpc/pull/27) - [@shamil614](https://github.com/shamil614)
  * Calling `rpc_client.start` and `rpc_client.channel.close` are no longer required when calling `rpc_client.remote_call` or the methods that call it (`index` `create`, etc).
  * Calling `rpc_client.channel.close` after `rpc_client.remote_call` will cause an Exception to be raised as the channel is already closed.
* [#29](https://github.com/C-S-D/carrot_rpc/pull/29) - [@shamil614](https://github.com/shamil614)
  * Replaced hard coded key formatter in place of a configurable option. 
  * Need to set the following in config to maintain previous behavior
  ```ruby
   CarrotRpc.configure do |config|
     # RpcServers expect the params to be dashed.
     config.rpc_client_request_key_format = :dasherize
     # In most cases the RpcClient instances use JSONAPI::Resource classes and the keys need to be transformed.
     config.rpc_client_response_key_format = :underscore
   end
  ```

## v0.4.1
### Bug Fixes
* [#23](https://githb.com/C-S-D/carrot_rpc/pull/23) - [@shamil614](https://github.com/shamil614)
  * Fixes errors for non-hash results being called with hash methods.
  * RPC client parses response to account for jsonrpc error object as well as jsonrpc result object.

## v0.4.0

### Enhancements
* [#20](https://githb.com/C-S-D/carrot_rpc/pull/20) - `config.before_request` may be set with a `#call(params) :: params` that is passed the `params` and returns altered `params` that are published to the queue. - [@shamil614](https://github.com/shamil614)

### Bug Fixes
* [#19](https://githb.com/C-S-D/carrot_rpc/pull/19) - [@KronicDeth](http://github.com/kronicdeth)
  * Put JSONAPI errors documents into the JSONRPC error fields instead of returning as normal results as consumers, such as `Rpc.Generic.Client` are expecting all errors to be in JSONRPC's error field and not have to check if the non-error `result` contains a JSONAPI level error.  This achieves parity with the behavior in the Elixir `Rpc.Generic.Server`.
  * Scrub JSONAPI error fields that are `nil` so they don't get transmitted as `null`.  JSONAPI spec is quite clear that `null` columns shouldn't be transmitted except in the case of `null` data to signal a missing singleton resource.  This achieves compatibility with the error parsing in `Rpc.Generic.Client` in Elixir.
  
### Incompatible Changes
* [#20](https://githb.com/C-S-D/carrot_rpc/pull/20) - `base_url`, which must be implemented by any RPC server that `include CarrotRpc::RpcServer::JSONAPIResources`, changes from `base_url() :: String` to `base_url(JSONAPI::OperationResult, JSONAPI::Request) :: String` - [@shamil614](https://github.com/shamil614)

## v0.3.0

### Enhancements
* [#11](https://githb.com/C-S-D/carrot_rpc/pull/11) - Add CodeClimate badge to README - [@thewalkingtoast](https://github.com/thewalkingtoast)
* [#13](https://githb.com/C-S-D/carrot_rpc/pull/13) - Document `queue_name` - [@shamil614](https://github.com/shamil614)
* [#14](https://githb.com/C-S-D/carrot_rpc/pull/14) - Pass `rpc_request: true` in the `JSONAPI::Request` `context`, so resources can differentiate between API and RPC calls - [@shamil614](https://github.com/shamil614)

### Bug Fixes
* [#12](https://githb.com/C-S-D/carrot_rpc/pull/12) - Pass `request` to `render_errors` when handling exceptions in `CarrotRpc::RpcServer::JSONAPIResources` - [@shamil614](https://github.com/shamil614)
* [#15](https://githb.com/C-S-D/carrot_rpc/pull/15) - Fix argument error bug when passing block to `CarrotRpc::TaggedLog` methods by allowing either a message or a block like standard `Logger` interface - [@shamil614](https://github.com/shamil614)
* [#17](https://githb.com/C-S-D/carrot_rpc/pull/17) - New rubocop versions add new cops or deprecate old config settings, so it is not safe to have `"rubocop"` without a version in the gemspec. - [@KronicDeth](http://github.com/kronicdeth)

## v0.2.3

### Enhancements
* [#9](https://github.com/C-S-D/carrot_rpc/pull/9) - [@KronicDeth](http://github.com/kronicdeth)
  * `CarrotRpc::RpcServer` subclasses can `include CarrotRpc::RpcServer::JSONAPIResources` to get
    [`JSONAPI::ActsAsResourceController`](https://github.com/cerebris/jsonapi-resources/blob/8e85d68dfbaf9181344c7618b0b29b4cfd362034/lib/jsonapi/acts_as_resource_controller.rb)
    helper methods for processing JSONAPI requests in server methods.
  * The primary entry point is `#process_request_params`, which expects an `ActionController::Parameters`
    (to do strong parameters) with `:action` set to the method name and `:controller` set to the name of the
    controller that corresponds to the `JSONAPI::Resource` subclass, such as `"api/v1/post"` to load `API::V1::PostResource`.
  * You need to define the following methods:
    * `base_url`
    * `resource_klass`
  * `CarrotRpc::RpcServer` subclasses, when including `CarrotRpc::Rpc::JSONAPIResources` can
    `extend CarrotRpc::Rpc::JSONAPIResources::Actions` to gain access to an `actions` DSL that takes a
    list of actions and defines methods that call `process_request_params` with the correct options.
  * You need to define the following methods:
    * `base_url`
    * `controller`
    * `resource_klass`

### Bug Fixes
* [#9](https://github.com/C-S-D/carrot_rpc/pull/9) - [@KronicDeth](http://github.com/KronicDeth)
  * `CarrotRpc::Error` was moved from the incorrect `lib/carrot_rpc/rpc_server/error.rb`
    path to the correct `lib/carrot_rpc/error.rb` path.
  * `CarrotRpc::Error::Code` was moved from the incorrect `lib/carrot_rpc/rpc_server/error/code.rb`
    path to the correct `lib/carrot_rpc/error/code.rb` path.

### Upgrading
* [#9](https://github.com/C-S-D/carrot_rpc/pull/9) - [@KronicDeth](http://github.com/KronicDeth)
  * If you previously loaded `CarrotRpc::Error` directly with `require "carrot_rpc/rpc_server/error"` you now need to
    `require "carrot_rpc/error"`, which is the corrected path.  `CarrotRpc::Error` is autoloaded, so you don't need to require it.
  * If you previously loaded `CarrotRpc::Error::Code` directly with `require "carrot_rpc/rpc_server/error/code"`
    you now need to `require "carrot_rpc/error/code"`, which is the corrected path.  `CarrotRpc::Error::Code` is
    autoloaded, so you don't need to require it.


## v0.2.1

### Bug Fixes
* [#6](https://github.com/C-S-D/carrot_rpc/pull/6) - [@shamil614](https://github.com/shamil614)
  * Error class not loaded in RpcServer
  * RpcServer should not rename json keys
  * RpcClient dasherizes keys before serializing hash to json. Better conformity to json property naming conventions.
  * RpcClient underscores keys after receiving response from server. Better conformity to ruby naming conventions.
* [#7](https://github.com/C-S-D/carrot_rpc/pull/7) - [@shamil614](https://github.com/shamil614)
  * Make sure hash keys are strings before renaming


## v0.2.0

### Enhancements
* [#5](https://github.com/C-S-D/carrot_rpc/pull/5) - [@KronicDeth](http://github.com/KronicDeth)
  * Gems ordered and documented in gemspec and `Gemfile`
  * Temorpary (`#`) files removed from git
  * Rubocop is enabled and used on CircleCI
    * Unused variables are prefixed with `_`
    * `fail` is used instead of `raise` when first raising an exception
    * Remove usage of deprecated methods
    * Print error if `byebug` can't be loaded instead of failing silently, but CLI still starts
    * Stop shadowing outer local variables in blocks
    * Remove unused assignments
    * Set and enforce max line length to 120
    * Use `find` instead of `select {}.first` for better performance
    * `queue_name` will retrieve the current queue name while `queue_name(new_name)` will set it.
    * Align hashes
    * Align parameters
    * Favor symbolic `&&` over `and`. (They have different precedence too)
    * Remove block comments
    * Assign to variable outside conditionals instead of on each branch
    * Remove extra empty lines
    * Don't favor guard clauses as they prevent break pointing the body and guard separately and obscure bodies that don't have code coverage.
    * Remove extra spacing
    * Correct indentation
    * Freeze `CarrotRpc::VERSION` so it is immutable
    * Use `until` instead of negated `while`
    * Use `_` to separate digits in large numerals
    * Use `( )` for sigils
    * Remove redundant `self.` for method calls
    * Use `%r{}` instead of `//` for regexps
    * Use newlines instead of `;`
    * Add spacing around blocks and braces
    * Enforce double quotes for all strings as double quotes work for strings in both Ruby and Elixir. (Single quotes are for Char Lists in Elixir)
    * Use `&:<method>` instead of calling a non-args method in blocks
    * Use `attr_reader` instead of trivial accessor methods
    * Remove unneed interpolation
    * Use double quotes instead of `%q`
    * Use `%w` for word arrays
    * Extract methods to lower to AbcSize metric and Method Length
    * Extract classes and modules to lower Class Length
    * Use `const_get` and `constantize` instead of security risk `eval`
  * Enable all RSpec 3 recommended options
    * Fix order-dependency of specs.
  * Use `autoload` to delay loading
  * Use compact class and module children to prevent parent from being missed when loading.
  * Add `rake spec`
  * Add Luke Imhoff as an author
  * Set gem home page to this repository
  * Semantic block delimiters, so we always think about procedural vs functional blocks to make Elixir coding easier.

### Bug Fixes
* [#5](https://github.com/C-S-D/carrot_rpc/pull/5) - [@KronicDeth](http://github.com/KronicDeth)
  * `ClientServer::ClassMethods` has been moved under `CarrotRpc` namespace as `CarrotRpc::ClientServer`
  * `HashExtensions` has been moved under `CarrotRpc` namespace as `CarrotRpc::HashExtensions`

### Incompatible Changes
* [#5](https://github.com/C-S-D/carrot_rpc/pull/5) - [@KronicDeth](http://github.com/KronicDeth)
  * `ClientServer::ClassMethods` renamed to `CarrotRpc::ClientServer`
  * `HashExtensions` renamed to `CarrotRpc::HashExtensions`
  * `ClientServer::ClassMethods#get_queue_name` renamed to `CarrotRpc::ClientServer#queue_name()` (no args is the reader, one argument is the writer)

## v0.1.2

### Enhancements
* [#4](https://github.com/C-S-D/carrot_rpc/pull1) - [@shamil614](https://github.com/shamil614)
  * Rename the keys in the parsed payload from '-' to '_'
  * Added integration specs to test functionality
  * Logging to test.log file
  * Setup for circleci integration tests to rabbitmq

### Bug Fixes
* [#4](https://github.com/C-S-D/carrot_rpc/pull1) - [@shamil614](https://github.com/shamil614)
  * Some require statements not properly loading modules
  * Consistent use of require vs require_relative

## v0.1.1

### Enhancements
* [#1](https://github.com/C-S-D/carrot_rpc/pull1) - [@shamil614](https://github.com/shamil614)
  * `CarrotRpc.configuration.bunny` can be set to custom
    [`Bunny` instance](http://www.rubydoc.info/gems/bunny/Bunny#new-class_method).
  * `CarrotRpc::RpcClient` and `CarrotRpc::RpcServer` subclasses can set their queue name with the `queue_name` class
    method. (It can be retrieved with `get_queue_name`.
  * `carrot_rpc`'s `--autoload_rails` boolean flag determines whether to load Rails environment.  The Rails path is
    assumed to the be the current working directory.
  * If a `CarrotRpc::RpcServer` method invoked from a JSON RPC `:method` raises an `CarrotRpc::Error`, then that error
    is converted to a JSON RPC error and sent back to the client.

### Bug Fixes
* [#1](https://github.com/C-S-D/carrot_rpc/pull/1) - [@shamil614](https://github.com/shamil614)
  * Send `jsonrpc` key instead of incorrect `json_rpc` key in JSON RPC response messages
  * All files under `bin` are marked as gem executables instead of just `carrot_rpc`
  * Fix files not loading properly when using `carrot_rpc`
  * Fix bug in logger file setup
  * The logger for each `CarrotRpc::RpcServer` is set before the server is started in
    `CarrotRpc::ServerRunner#run_servers` to prevent a race condition where `#start` may try to use the logger.

### Incompatible Changes
* [#1](https://github.com/C-S-D/carrot_rpc/pull/1) - [@shamil614](https://github.com/shamil614)
  * `CarrotRpc.configuration.bunny` **MUST** be set to a
    [`Bunny` instance](http://www.rubydoc.info/gems/bunny/Bunny#new-class_method), usually using `Bunny.new`.
  * `CarrotRpc::RpcClient` and `CarrotRpc::RpcServer` subclasses **MUST** set their queue name with the `queue_name`
    class method.
  * `:channel` keyword argument is no longer accepted in `CarrotRpc::RpcClient.new`.  The channel had already been
    created from the `config.bunny.create_channel`, so the keyword argument was unused.
  * `CarrotRpc::RpcClient#logger` is now read-only and is set from `config.logger`.
  * `CarrotRpc::RpcServer#logger` is now read-only and is set from `config.logger`.
  * `CarrotRpc.configuration.logger` is set to the `CarrotRpc::ServerServer#logger`.
  * `carrot_rpc`'s `--rails_path PATH` flag has been replaced with `--autoload_rails` boolean flag that automatically
     assumes the Rails path is the current working directory.
  * `CarrotRpc.connfiguration.rails_path` no longer exists.  The Rails path is assumed to be the current working
    directory.
