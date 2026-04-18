# frozen_string_literal: true

module Apertur
  module Resources
    # Poll upload sessions for new images and download them.
    #
    # Provides a blocking polling loop ({#poll_and_process}) that fetches,
    # downloads, and acknowledges new images automatically.
    class Polling
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # List pending (un-acknowledged) images in a session.
      #
      # @param uuid [String] the session UUID
      # @return [Hash] poll result containing an +images+ array
      def list(uuid)
        @http.request(:get, "/api/v1/upload-sessions/#{uuid}/poll")
      end

      # Download an image from a session.
      #
      # @param uuid [String] the session UUID
      # @param image_id [String] the image ID
      # @return [String] raw binary image data
      def download(uuid, image_id)
        @http.request_raw(:get, "/api/v1/upload-sessions/#{uuid}/images/#{image_id}")
      end

      # Acknowledge (mark as processed) an image.
      #
      # @param uuid [String] the session UUID
      # @param image_id [String] the image ID
      # @return [Hash] acknowledgement status
      def ack(uuid, image_id)
        @http.request(:post, "/api/v1/upload-sessions/#{uuid}/images/#{image_id}/ack")
      end

      # Blocking polling loop that fetches, downloads, and acknowledges images.
      #
      # Calls the provided block for each new image. The loop runs until the
      # calling thread is interrupted or the block raises an exception.
      #
      # @param uuid [String] the session UUID
      # @param interval [Numeric] seconds between poll cycles (default: 3)
      # @yield [image, data] called for each new image
      # @yieldparam image [Hash] image metadata from the poll response
      # @yieldparam data [String] raw binary image data
      # @return [void]
      def poll_and_process(uuid, interval: 3, &handler)
        raise ArgumentError, "A block is required" unless block_given?

        loop do
          result = list(uuid)
          images = result["images"] || []

          images.each do |image|
            data = download(uuid, image["id"])
            handler.call(image, data)
            ack(uuid, image["id"])
          end

          sleep(interval)
        end
      end
    end
  end
end
