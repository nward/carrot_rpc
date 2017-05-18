# Common functionality for Client and Server.
module CarrotRpc::ClientServer
  # @overload queue_name(new_name)
  #   @note Default naming not performed. Class must pass queue name.
  #
  #   Allows for class level definition of queue name.
  #
  #   @param new_name [String] the queue name for the class.
  #   @return [String] `new_name`
  #
  # @overload queue_name
  #   The current queue name previously set with `#queue_name(new_name)`.
  #
  #   @return [String]
  def queue_name(*args)
    if args.length == 0
      @queue_name
    elsif args.length == 1
      @queue_name = args[0]
    else
      fail ArgumentError,
           "queue_name(new_name) :: new_name or queue_name() :: " \
           "current_name are the only ways to call queue_name"
    end
  end

  # @overload queue_options(options)
  #
  #   Allows for custom queue options, such as durable.
  #
  #   @options params [Hash] a hash of options to pass to bunny.
  #
  # @overload queue_options
  #   The current queue options previously set with `#queue_options(options)`.
  #
  #   @return [Hash]
  def queue_options(*args)
    if args.length == 0
      @queue_options || {}
    elsif args.length == 1
      @queue_options = args[0]
    else
      fail ArgumentError,
           "queue_options(options) :: options or queue_options() :: " \
           "current_options are the only ways to call queue_options"
    end
  end

  def test_queue_name(name, append_name = false)
    return name unless append_name
    if name
      "#{name}_test"
    else
      fail CarrotRpc::Exception::InvalidQueueName
    end
  end
end
