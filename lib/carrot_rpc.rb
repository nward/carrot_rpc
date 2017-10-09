# gem dependencies
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/hash/except"
require "active_support/dependencies/autoload"
require "active_support/notifications"
require "bunny"

# standard library
require "json"
require "optparse"

# project
require "carrot_rpc/version"

# An opinionated approach to doing Remote Procedure Call (RPC) with RabbitMQ and the bunny gem. CarrotRpc serves as a
# way to streamline the RPC workflow so developers can focus on the implementation and not the plumbing when working
# with RabbitMQ.
module CarrotRpc
  extend ActiveSupport::Autoload

  autoload :CLI
  autoload :ClientActions
  autoload :ClientServer
  autoload :Configuration
  autoload :Error
  autoload :Exception
  autoload :Format
  autoload :HashExtensions
  autoload :Reply
  autoload :RpcClient
  autoload :RpcServer
  autoload :ServerRunner
  autoload :Scrub
  autoload :TaggedLog

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Resets the configuration back to a new instance. Should only be used in testing.
  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield configuration
  end

  # Attempts to start a connection to the existing Bunny object.
  # @return [Bunny::Session]
  def self.connect
    bunny = configuration.bunny
    bunny.start unless bunny.open?
  end
end
