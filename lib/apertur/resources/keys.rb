# frozen_string_literal: true

module Apertur
  module Resources
    # Manage API keys within a project.
    class Keys
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # List all API keys for a project.
      #
      # @param project_id [String] the project ID
      # @return [Array<Hash>] list of API keys
      def list(project_id)
        @http.request(:get, "/api/v1/projects/#{project_id}/keys")
      end

      # Create a new API key.
      #
      # @param project_id [String] the project ID
      # @param options [Hash] key configuration (e.g. +name+, +scopes+)
      # @return [Hash] the created key, including the plaintext secret (shown only once)
      def create(project_id, **options)
        @http.request(:post, "/api/v1/projects/#{project_id}/keys", body: options)
      end

      # Update an existing API key.
      #
      # @param project_id [String] the project ID
      # @param key_id [String] the key ID
      # @param options [Hash] fields to update
      # @return [Hash] the updated key
      def update(project_id, key_id, **options)
        @http.request(:patch, "/api/v1/projects/#{project_id}/keys/#{key_id}", body: options)
      end

      # Delete an API key.
      #
      # @param project_id [String] the project ID
      # @param key_id [String] the key ID
      # @return [nil]
      def delete(project_id, key_id)
        @http.request(:delete, "/api/v1/projects/#{project_id}/keys/#{key_id}")
      end

      # Set the destinations and long-polling configuration for a key.
      #
      # @param key_id [String] the key ID
      # @param destination_ids [Array<String>] destination IDs to associate
      # @param long_polling_enabled [Boolean] whether to enable long-polling (default: false)
      # @return [Hash] the updated key-destinations mapping
      def set_destinations(key_id, destination_ids, long_polling_enabled: false)
        body = { destination_ids: destination_ids }
        body[:long_polling_enabled] = long_polling_enabled unless long_polling_enabled.nil?
        @http.request(:put, "/api/v1/keys/#{key_id}/destinations", body: body)
      end
    end
  end
end
