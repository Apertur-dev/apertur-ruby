# frozen_string_literal: true

module Apertur
  module Resources
    # Manage delivery destinations within a project.
    #
    # Destinations define where uploaded images are delivered (e.g. cloud
    # storage buckets, webhooks, etc.).
    class Destinations
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # List all destinations for a project.
      #
      # @param project_id [String] the project ID
      # @return [Array<Hash>] list of destinations
      def list(project_id)
        @http.request(:get, "/api/v1/projects/#{project_id}/destinations")
      end

      # Create a new destination.
      #
      # @param project_id [String] the project ID
      # @param config [Hash] destination configuration
      # @return [Hash] the created destination
      def create(project_id, **config)
        @http.request(:post, "/api/v1/projects/#{project_id}/destinations", body: config)
      end

      # Update an existing destination.
      #
      # @param project_id [String] the project ID
      # @param dest_id [String] the destination ID
      # @param config [Hash] fields to update
      # @return [Hash] the updated destination
      def update(project_id, dest_id, **config)
        @http.request(:patch, "/api/v1/projects/#{project_id}/destinations/#{dest_id}", body: config)
      end

      # Delete a destination.
      #
      # @param project_id [String] the project ID
      # @param dest_id [String] the destination ID
      # @return [nil]
      def delete(project_id, dest_id)
        @http.request(:delete, "/api/v1/projects/#{project_id}/destinations/#{dest_id}")
      end

      # Send a test payload to a destination.
      #
      # @param project_id [String] the project ID
      # @param dest_id [String] the destination ID
      # @return [Hash] test result
      def test(project_id, dest_id)
        @http.request(:post, "/api/v1/projects/#{project_id}/destinations/#{dest_id}/test")
      end
    end
  end
end
