# Base RPC Server class. Other Servers should inherit from this.
class CarrotRpc::RpcServer
  autoload :JSONAPIResources, "carrot_rpc/rpc_server/jsonapi_resources"

  using CarrotRpc::HashExtensions

  attr_reader :channel, :server_queue, :logger, :thread_request_variable
  # method_reciver => object that receives the method. can be a class or anything responding to send

  extend CarrotRpc::ClientServer
  include CarrotRpc::Reply

  # Documentation advises not to share a channel connection. Create new channel for each server instance.
  def initialize(config: nil, block: true)
    # create a channel and exchange that both client and server know about
    config ||= CarrotRpc.configuration
    @thread_request_variable = config.thread_request_variable
    @channel = config.bunny.create_channel
    @logger = config.logger
    @block = block
    setup_queue(config)
    @exchange = @channel.default_exchange
  end

  # start da server!
  # method => object that receives the method. can be a class or anything responding to send
  def start
    # subscribe is like a callback
    @server_queue.subscribe(block: @block) do |delivery_info, properties, payload|
      consume(delivery_info, properties, payload)
    end
  end

  def process_request(request_message, properties:)
    maybe_thread_request(request_message: request_message) do
      method = request_message[:method]
      handler = method_handler(method)

      send handler,
           method:          method,
           properties:      properties,
           request_message: request_message
    end
  end

  private

  def call_found_method(method:, properties:, request_message:)
    result = send(method, request_message[:params])
  rescue CarrotRpc::Error => rpc_server_error
    logger.error(rpc_server_error)

    reply_error rpc_server_error.serialized_message,
                properties:      properties,
                request_message: request_message
  else
    reply_result result,
                 properties:      properties,
                 request_message: request_message
  end

  def consume(_delivery_info, properties, payload) # rubocop:disable Metrics/MethodLength
    queue_name = server_queue.name
    correlation_id = properties[:correlation_id]
    extra = { correlation_id: correlation_id }

    ActiveSupport::Notifications.instrument("server.#{queue_name}.consume", extra: extra) do
      logger.tagged("server", "queue=#{queue_name}", "correlation_id=#{correlation_id}") do
        logger.debug "Receiving request: #{payload}"

        # rubocop:disable Lint/RescueException
        begin
          request_message = JSON.parse(payload).with_indifferent_access

          process_request(request_message, properties: properties)
        rescue Exception => exception
          logger.error(exception)
        end
        # rubocop:enable Lint/RescueException
      end
    end
  end

  def maybe_thread_request(request_message:)
    if thread_request_variable
      thread_request(request_message: request_message, &Proc.new)
    else
      yield
    end
  end

  def method_handler(method)
    if respond_to? method
      :call_found_method
    else
      :reply_method_not_found
    end
  end

  def setup_queue(config)
    queue_name = self.class.test_queue_name(self.class.queue_name, config.server_test_mode)
    @server_queue = @channel.queue(queue_name, self.class.queue_options)
  end

  def thread_request(request_message:)
    logger.debug "Threading request (#{request_message.inspect}) " \
                   "in Thread.current.thread_variable_get(#{thread_request_variable.inspect})"

    Thread.current.thread_variable_set(thread_request_variable, request_message)

    begin
      yield
    ensure
      Thread.current.thread_variable_set(thread_request_variable, nil)
    end
  end
end
