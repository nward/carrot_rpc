# Publishes properly formatted replies to consumed requests
module CarrotRpc::Reply
  private

  def reply(properties:, response_message:)
    payload = response_message.to_json

    logger.debug "Publishing response: #{payload}"

    @exchange.publish payload,
                      correlation_id: properties.correlation_id,
                      routing_key: properties.reply_to
  end

  # See http://www.jsonrpc.org/specification#error_object
  def reply_error(error, properties:, request_message:)
    response_message = { error: error, id: request_message[:id], jsonrpc: "2.0" }

    reply properties: properties,
          response_message: response_message
  end

  def reply_method_not_found(method:, properties:, request_message:)
    error = CarrotRpc::Error.new code: CarrotRpc::Error::Code::METHOD_NOT_FOUND,
                                 data: {
                                   method: method
                                 },
                                 message: "Method not found"
    logger.error(error)

    if request_message.has_key? :id
      reply_error error.serialized_message,
                  properties:      properties,
                  request_message: request_message
    end
  end

  # See http://www.jsonrpc.org/specification#response_object
  def reply_result(result, properties:, request_message:)
    if result && result.is_a?(Hash) && result["errors"]
      reply_result_with_errors(result, properties: properties, request_message: request_message)
    else
      reply_result_without_errors(result, properties: properties, request_message: request_message)
    end
  end

  def reply_result_with_errors(result, properties:, request_message:)
    scrubbed_result = result.merge(
      "errors" => CarrotRpc::Scrub.errors(result.fetch("errors"))
    )
    reply_error({ code: 422, data: scrubbed_result, message: "JSONAPI error" },
                properties: properties,
                request_message: request_message)
  end

  def reply_result_without_errors(result, properties:, request_message:)
    response_message = { id: request_message[:id], jsonrpc: "2.0", result: result }

    reply properties: properties,
          response_message: response_message
  end
end
