# Various exceptions that can be invoked for CarrotRpc gem.
module CarrotRpc::Exception
  # Exception to be raised when the client timesout waiting for a response.
  class RpcClientTimeout < StandardError; end
  class InvalidQueueName < StandardError; end
  class InvalidResponse < StandardError; end
end
