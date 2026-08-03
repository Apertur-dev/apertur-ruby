# frozen_string_literal: true

module Apertur
  module Resources
    # Browse completed uploads.
    class Uploads
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # List uploads with pagination.
      #
      # @param page [Integer, nil] page number
      # @param page_size [Integer, nil] number of results per page
      # @return [Hash] paginated list with +data+ and pagination metadata
      def list(**params)
        query = {}
        query["page"] = params[:page].to_s if params[:page]
        query["pageSize"] = params[:page_size].to_s if params[:page_size]
        @http.request(:get, "/api/v1/uploads", query: query)
      end

      # List recent uploads.
      #
      # @param limit [Integer, nil] maximum number of uploads to return
      # @return [Array<Hash>] recent uploads
      def recent(**params)
        query = {}
        query["limit"] = params[:limit].to_s if params[:limit]
        @http.request(:get, "/api/v1/uploads/recent", query: query)
      end
    end
  end
end
