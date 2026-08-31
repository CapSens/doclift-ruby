module Doclift
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class ConnectionError < Error
    attr_reader :cause_class

    def initialize(message, cause_class: nil)
      @cause_class = cause_class
      super(message)
    end
  end

  class ApiError < Error
    attr_reader :status, :details

    def initialize(status:, message: nil, details: {})
      @status = status
      @details = details
      super(message || "Doclift API error #{status}")
    end

    class << self
      def from_response(status, parsed_body)
        error_class_for(status).new(
          status: status,
          message: message_from(parsed_body),
          details: parsed_body.is_a?(Hash) ? parsed_body : {},
        )
      end

      private

      def error_class_for(status)
        case status
        when 400, 401 then BadRequestError
        when 403 then AuthenticationError
        when 404 then NotFoundError
        when 409 then ConflictError
        when 422 then ValidationError
        when 500..599 then ServerError
        else ApiError
        end
      end

      def message_from(parsed_body)
        return nil unless parsed_body.is_a?(Hash)

        single = parsed_body["error"]
        return single if single.is_a?(String) && !single.empty?

        multiple = parsed_body["errors"]
        return multiple.join(", ") if multiple.is_a?(Array) && !multiple.empty?

        nil
      end
    end
  end

  class BadRequestError < ApiError; end
  class AuthenticationError < ApiError; end
  class NotFoundError < ApiError; end
  class ConflictError < ApiError; end

  class ValidationError < ApiError
    def invalid_variables
      value = details["invalid_variables"]
      value.is_a?(Array) ? value : []
    end
  end

  class ServerError < ApiError; end
end
