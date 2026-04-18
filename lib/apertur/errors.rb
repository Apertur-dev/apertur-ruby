# frozen_string_literal: true

module Apertur
  # Base error class for all Apertur API errors.
  #
  # @attr_reader [Integer, nil] status_code the HTTP status code
  # @attr_reader [String, nil] code the error code returned by the API
  class Error < StandardError
    attr_reader :status_code, :code

    # @param message [String] the error message
    # @param status_code [Integer, nil] the HTTP status code
    # @param code [String, nil] the API error code
    def initialize(message, status_code: nil, code: nil)
      super(message)
      @status_code = status_code
      @code = code
    end
  end

  # Raised when the API returns a 401 Unauthorized response.
  class AuthenticationError < Error
    def initialize(message = "Authentication failed")
      super(message, status_code: 401, code: "AUTHENTICATION_FAILED")
    end
  end

  # Raised when the API returns a 404 Not Found response.
  class NotFoundError < Error
    def initialize(message = "Not found")
      super(message, status_code: 404, code: "NOT_FOUND")
    end
  end

  # Raised when the API returns a 429 Too Many Requests response.
  #
  # @attr_reader [Integer, nil] retry_after seconds to wait before retrying
  class RateLimitError < Error
    attr_reader :retry_after

    # @param message [String] the error message
    # @param retry_after [Integer, nil] seconds to wait before retrying
    def initialize(message = "Rate limit exceeded", retry_after: nil)
      super(message, status_code: 429, code: "RATE_LIMIT")
      @retry_after = retry_after
    end
  end

  # Raised when the API returns a 400 Bad Request response.
  class ValidationError < Error
    def initialize(message = "Validation failed")
      super(message, status_code: 400, code: "VALIDATION_ERROR")
    end
  end
end
