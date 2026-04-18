# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "securerandom"

module Apertur
  # Low-level HTTP wrapper around Net::HTTP for communicating with the Apertur API.
  #
  # Handles JSON serialization, Bearer token authentication, multipart uploads,
  # and error mapping.
  class HttpClient
    # @param base_url [String] the API base URL (e.g. "https://api.aptr.ca")
    # @param token [String] the Bearer token (API key or OAuth token)
    def initialize(base_url, token)
      @base_url = base_url.chomp("/")
      @token = token
    end

    # Perform an API request and return the parsed JSON response.
    #
    # @param method [Symbol] HTTP method (:get, :post, :patch, :put, :delete)
    # @param path [String] the API path (e.g. "/api/v1/stats")
    # @param body [Hash, nil] request body to be serialized as JSON
    # @param query [Hash, nil] query parameters
    # @param headers [Hash] additional request headers
    # @param read_timeout [Integer, Float, nil] override the per-request
    #   read timeout (seconds). Defaults to the connection default (60s).
    # @return [Hash, Array, nil] parsed JSON response, or nil for 204
    # @raise [Apertur::Error] on API errors
    def request(method, path, body: nil, query: nil, headers: {}, read_timeout: nil)
      uri = build_uri(path, query)
      req = build_request(method, uri, headers)

      if body
        req["Content-Type"] = "application/json"
        req.body = body.is_a?(String) ? body : JSON.generate(body)
      end

      response = execute(uri, req, read_timeout: read_timeout)
      handle_response(response)
    end

    # Perform an API request and return the raw response body as a binary String.
    #
    # @param method [Symbol] HTTP method
    # @param path [String] the API path
    # @param query [Hash, nil] query parameters
    # @return [String] raw response body (binary)
    # @raise [Apertur::Error] on API errors
    def request_raw(method, path, query: nil)
      uri = build_uri(path, query)
      req = build_request(method, uri)

      response = execute(uri, req)
      handle_error(response) unless response.is_a?(Net::HTTPSuccess)
      response.body
    end

    # Perform a multipart/form-data upload request.
    #
    # @param path [String] the API path
    # @param file_data [String] raw file bytes
    # @param filename [String] the filename to use in the multipart part
    # @param mime_type [String] the MIME type of the file
    # @param fields [Hash] additional form fields
    # @param headers [Hash] additional request headers
    # @return [Hash, Array, nil] parsed JSON response
    # @raise [Apertur::Error] on API errors
    def request_multipart(path, file_data, filename:, mime_type:, fields: {}, headers: {})
      uri = build_uri(path)
      boundary = "AperturRubySDK#{SecureRandom.hex(16)}"

      body = build_multipart_body(boundary, file_data, filename, mime_type, fields)

      req = build_request(:post, uri, headers)
      req["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      req.body = body

      response = execute(uri, req)
      handle_response(response)
    end

    private

    # @param path [String]
    # @param query [Hash, nil]
    # @return [URI]
    def build_uri(path, query = nil)
      url = "#{@base_url}#{path}"
      if query && !query.empty?
        params = query.reject { |_, v| v.nil? }.map { |k, v| "#{URI.encode_www_form_component(k)}=#{URI.encode_www_form_component(v)}" }
        url += "?#{params.join("&")}" unless params.empty?
      end
      URI.parse(url)
    end

    # @param method [Symbol]
    # @param uri [URI]
    # @param extra_headers [Hash]
    # @return [Net::HTTPRequest]
    def build_request(method, uri, extra_headers = {})
      klass = case method
              when :get    then Net::HTTP::Get
              when :post   then Net::HTTP::Post
              when :patch  then Net::HTTP::Patch
              when :put    then Net::HTTP::Put
              when :delete then Net::HTTP::Delete
              else raise ArgumentError, "Unsupported HTTP method: #{method}"
              end

      req = klass.new(uri)
      req["Authorization"] = "Bearer #{@token}" if @token && !@token.empty?
      req["User-Agent"] = "apertur-sdk-ruby/#{Apertur::VERSION}"
      req["Accept"] = "application/json"

      extra_headers.each { |k, v| req[k] = v }
      req
    end

    # @param uri [URI]
    # @param req [Net::HTTPRequest]
    # @param read_timeout [Integer, Float, nil] optional override for
    #   +Net::HTTP#read_timeout+ (seconds).
    # @return [Net::HTTPResponse]
    def execute(uri, req, read_timeout: nil)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 30
      http.read_timeout = read_timeout || 60
      http.request(req)
    end

    # @param response [Net::HTTPResponse]
    # @return [Hash, Array, nil]
    def handle_response(response)
      handle_error(response) unless response.is_a?(Net::HTTPSuccess)

      return nil if response.code == "204" || response.body.nil? || response.body.empty?

      JSON.parse(response.body)
    end

    # @param response [Net::HTTPResponse]
    # @raise [Apertur::Error]
    def handle_error(response)
      body = begin
               JSON.parse(response.body)
             rescue StandardError
               {}
             end

      message = body["message"] || "HTTP #{response.code}"
      code = body["code"]

      case response.code.to_i
      when 401
        raise AuthenticationError, message
      when 404
        raise NotFoundError, message
      when 429
        retry_after = response["Retry-After"]&.to_i
        raise RateLimitError.new(message, retry_after: retry_after)
      when 400
        raise ValidationError, message
      else
        raise Error.new(message, status_code: response.code.to_i, code: code)
      end
    end

    # @param boundary [String]
    # @param file_data [String]
    # @param filename [String]
    # @param mime_type [String]
    # @param fields [Hash]
    # @return [String]
    def build_multipart_body(boundary, file_data, filename, mime_type, fields)
      parts = []

      fields.each do |key, value|
        parts << "--#{boundary}\r\n" \
                 "Content-Disposition: form-data; name=\"#{key}\"\r\n" \
                 "\r\n" \
                 "#{value}\r\n"
      end

      parts << "--#{boundary}\r\n" \
               "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n" \
               "Content-Type: #{mime_type}\r\n" \
               "\r\n"

      body = parts.join.b
      body << file_data.b
      body << "\r\n--#{boundary}--\r\n".b
      body
    end
  end
end
