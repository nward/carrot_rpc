# Library for standardizing the RabbitMQ RPC workflow.
module CarrotRpc
  # Wrap the Logger object with convenience methods.
  class TaggedLog
    attr_reader :logger, :tags

    def initialize(logger: , tags:)
      @logger = logger
      @tags = *tags
    end

    # Dyanmically define logger methods with a tagged reference. Makes filtering of logs possible.
    %i(debug info warn error fatal uknown).each do |level|
      define_method(level) do |msg|
        logger.tagged(tags) { logger.send(level, msg) }
      end
    end
  end
end
