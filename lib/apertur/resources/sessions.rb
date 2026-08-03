# frozen_string_literal: true

module Apertur
  module Resources
    # Manage upload sessions.
    #
    # Upload sessions represent a time-limited context in which one or more
    # images can be uploaded. Each session has a unique UUID, optional password
    # protection, and configurable constraints.
    class Sessions
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # Create a new upload session.
      #
      # @param destination_ids [Array<String>, nil] destination IDs to deliver images to
      # @param long_polling [Boolean, nil] whether to enable long-polling on this session
      # @param tags [Array<String>, nil] tags to attach to the session
      # @param expires_in_hours [Integer, nil] hours until the session expires
      # @param expires_at [String, nil] ISO 8601 expiry timestamp
      # @param max_images [Integer, nil] maximum number of images allowed
      # @param allowed_mime_types [Array<String>, nil] allowed MIME types for uploads
      # @param max_image_dimension [Integer, nil] maximum image dimension in pixels
      # @param password [String, nil] optional password to protect the session
      # @return [Hash] the created session details including +uuid+ and +upload_url+
      def create(**options)
        @http.request(:post, "/api/v1/upload-sessions", body: options)
      end

      # Retrieve an existing upload session by UUID.
      #
      # @param uuid [String] the session UUID
      # @return [Hash] session details
      def get(uuid)
        @http.request(:get, "/api/v1/upload/#{uuid}/session")
      end

      # Update an existing upload session.
      #
      # @param uuid [String] the session UUID
      # @param options [Hash] fields to update (same options as {#create})
      # @return [Hash] the updated session
      def update(uuid, **options)
        @http.request(:patch, "/api/v1/upload-sessions/#{uuid}", body: options)
      end

      # List upload sessions with pagination.
      #
      # @param page [Integer, nil] page number
      # @param page_size [Integer, nil] number of results per page
      # @return [Hash] paginated list with +data+ and pagination metadata
      def list(**params)
        query = {}
        query["page"] = params[:page].to_s if params[:page]
        query["pageSize"] = params[:page_size].to_s if params[:page_size]
        @http.request(:get, "/api/v1/sessions", query: query)
      end

      # List recent upload sessions.
      #
      # @param limit [Integer, nil] maximum number of sessions to return
      # @return [Array<Hash>] recent sessions
      def recent(**params)
        query = {}
        query["limit"] = params[:limit].to_s if params[:limit]
        @http.request(:get, "/api/v1/sessions/recent", query: query)
      end

      # Get the QR code image for an upload session.
      #
      # @param uuid [String] the session UUID
      # @param format [String, nil] image format (e.g. "png", "svg")
      # @param size [Integer, nil] QR code size in pixels
      # @param style [String, nil] QR code style
      # @param fg [String, nil] foreground color
      # @param bg [String, nil] background color
      # @param border_size [Integer, nil] border size in pixels
      # @param border_color [String, nil] border color
      # @return [String] raw binary image data
      def qr(uuid, **options)
        query = {}
        query["format"] = options[:format] if options[:format]
        query["size"] = options[:size].to_s if options[:size]
        query["style"] = options[:style] if options[:style]
        query["fg"] = options[:fg] if options[:fg]
        query["bg"] = options[:bg] if options[:bg]
        query["borderSize"] = options[:border_size].to_s if options[:border_size]
        query["borderColor"] = options[:border_color] if options[:border_color]
        @http.request_raw(:get, "/api/v1/upload-sessions/#{uuid}/qr", query: query)
      end

      # Verify a session password.
      #
      # @param uuid [String] the session UUID
      # @param password [String] the password to verify
      # @return [Hash] result with +valid+ boolean
      def verify_password(uuid, password)
        @http.request(:post, "/api/v1/upload/#{uuid}/verify-password", body: { password: password })
      end

      # Get the delivery status for a session.
      #
      # Returns a hash with the following shape:
      #
      #   {
      #     "status"      => "pending" | "active" | "completed" | "expired",
      #     "files"       => [ { "record_id" => ..., "filename" => ..., "size_bytes" => ...,
      #                          "destinations" => [ { "destination_id" => ..., "status" => ..., ... } ] } ],
      #     "lastChanged" => "<ISO 8601>"
      #   }
      #
      # When +poll_from+ (ISO 8601 timestamp) is provided, the server long-polls for
      # up to 5 minutes waiting for something to change before responding. This call
      # automatically widens the read timeout to 360 s (6 min) in that case so the
      # server releases first under the happy path.
      #
      # @param uuid [String] the session UUID
      # @param poll_from [String, nil] ISO 8601 timestamp; when set, enables long-poll mode
      # @return [Hash] delivery status snapshot
      def delivery_status(uuid, poll_from: nil)
        query = {}
        query["pollFrom"] = poll_from if poll_from
        read_timeout = poll_from ? 360 : nil
        @http.request(
          :get,
          "/api/v1/upload-sessions/#{uuid}/delivery-status",
          query: query,
          read_timeout: read_timeout,
        )
      end
    end
  end
end
