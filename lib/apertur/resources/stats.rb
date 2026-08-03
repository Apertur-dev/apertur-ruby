# frozen_string_literal: true

module Apertur
  module Resources
    # Retrieve account usage statistics.
    class Stats
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # Get current account statistics.
      #
      # @return [Hash] usage statistics (uploads, sessions, storage, etc.)
      def get
        @http.request(:get, "/api/v1/stats")
      end
    end
  end
end
