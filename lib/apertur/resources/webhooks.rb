# frozen_string_literal: true

module Apertur
  module Resources
    # Manage event webhooks within a project.
    class Webhooks
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # List all webhooks for a project.
      #
      # @param project_id [String] the project ID
      # @return [Array<Hash>] list of webhooks
      def list(project_id)
        @http.request(:get, "/api/v1/projects/#{project_id}/webhooks")
      end

      # Create a new webhook.
      #
      # @param project_id [String] the project ID
      # @param config [Hash] webhook configuration (e.g. +url+, +events+, +secret+)
      # @return [Hash] the created webhook
      def create(project_id, **config)
        @http.request(:post, "/api/v1/projects/#{project_id}/webhooks", body: config)
      end

      # Update an existing webhook.
      #
      # @param project_id [String] the project ID
      # @param webhook_id [String] the webhook ID
      # @param config [Hash] fields to update
      # @return [Hash] the updated webhook
      def update(project_id, webhook_id, **config)
        @http.request(:patch, "/api/v1/projects/#{project_id}/webhooks/#{webhook_id}", body: config)
      end

      # Delete a webhook.
      #
      # @param project_id [String] the project ID
      # @param webhook_id [String] the webhook ID
      # @return [nil]
      def delete(project_id, webhook_id)
        @http.request(:delete, "/api/v1/projects/#{project_id}/webhooks/#{webhook_id}")
      end

      # Send a test event to a webhook.
      #
      # @param project_id [String] the project ID
      # @param webhook_id [String] the webhook ID
      # @return [Hash] test result
      def test(project_id, webhook_id)
        @http.request(:post, "/api/v1/projects/#{project_id}/webhooks/#{webhook_id}/test")
      end

      # List delivery attempts for a webhook.
      #
      # @param project_id [String] the project ID
      # @param webhook_id [String] the webhook ID
      # @param page [Integer, nil] page number
      # @param limit [Integer, nil] number of results per page
      # @return [Hash] paginated delivery list
      def deliveries(project_id, webhook_id, **options)
        query = {}
        query["page"] = options[:page].to_s if options[:page]
        query["limit"] = options[:limit].to_s if options[:limit]
        @http.request(:get, "/api/v1/projects/#{project_id}/webhooks/#{webhook_id}/deliveries", query: query)
      end

      # Retry a failed delivery attempt.
      #
      # @param project_id [String] the project ID
      # @param webhook_id [String] the webhook ID
      # @param delivery_id [String] the delivery ID
      # @return [Hash] retry result
      def retry_delivery(project_id, webhook_id, delivery_id)
        @http.request(
          :post,
          "/api/v1/projects/#{project_id}/webhooks/#{webhook_id}/deliveries/#{delivery_id}/retry"
        )
      end
    end
  end
end
