# frozen_string_literal: true

module Apertur
  module Resources
    # Retrieve server-side encryption keys.
    class Encryption
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # Get the server's public encryption key.
      #
      # The returned key is used for client-side image encryption before upload.
      #
      # @return [Hash] server key details including the PEM-encoded public key
      def get_server_key
        @http.request(:get, "/api/v1/encryption/server-key")
      end
    end
  end
end
