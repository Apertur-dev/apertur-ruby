# frozen_string_literal: true

module Apertur
  module Resources
    # Upload images to a session.
    #
    # Supports both plaintext multipart uploads and client-side encrypted
    # uploads using AES-256-GCM with RSA-OAEP key wrapping.
    class Upload
      # @param http [Apertur::HttpClient]
      def initialize(http)
        @http = http
      end

      # Upload an image to a session via multipart/form-data.
      #
      # @param uuid [String] the session UUID
      # @param file [String, IO] a file path (String), an IO-like object responding
      #   to +read+, or raw image bytes (binary String)
      # @param filename [String] the filename to send (default: "image.jpg")
      # @param mime_type [String] the MIME type of the image (default: "image/jpeg")
      # @param source [String, nil] an optional source identifier
      # @param password [String, nil] session password if the session is protected
      # @return [Hash] upload result
      def image(uuid, file, filename: "image.jpg", mime_type: "image/jpeg", source: nil, password: nil)
        file_data = read_file(file)

        fields = {}
        fields["source"] = source if source

        headers = {}
        headers["x-session-password"] = password if password

        @http.request_multipart(
          "/api/v1/upload/#{uuid}/images",
          file_data,
          filename: filename,
          mime_type: mime_type,
          fields: fields,
          headers: headers
        )
      end

      # Upload an encrypted image to a session.
      #
      # The image is encrypted client-side using AES-256-GCM, with the AES key
      # wrapped by the server's RSA public key. The encrypted payload is sent as
      # JSON with the +X-Aptr-Encrypted: default+ header.
      #
      # @param uuid [String] the session UUID
      # @param file [String, IO] a file path, IO, or raw bytes
      # @param public_key [String] the RSA public key in PEM format
      # @param filename [String] the filename (default: "image.jpg")
      # @param mime_type [String] the MIME type (default: "image/jpeg")
      # @param source [String, nil] optional source identifier
      # @param password [String, nil] session password if the session is protected
      # @return [Hash] upload result
      def image_encrypted(uuid, file, public_key, filename: "image.jpg", mime_type: "image/jpeg", source: nil, password: nil)
        file_data = read_file(file)
        encrypted = Apertur::Crypto.encrypt_image(file_data, public_key)

        # The server's "default" encryption mode expects a multipart file
        # upload whose body is the JSON-serialized EncryptedPayload (camelCase
        # keys), which it then decrypts with its private key. Sending a JSON
        # request body instead yields a 500 ("No file uploaded").
        payload_json = JSON.generate(
          "encryptedKey" => encrypted["encrypted_key"],
          "iv" => encrypted["iv"],
          "encryptedData" => encrypted["encrypted_data"],
          "algorithm" => encrypted["algorithm"]
        )

        fields = {}
        fields["source"] = source if source

        headers = { "X-Aptr-Encrypted" => "default" }
        headers["x-session-password"] = password if password

        @http.request_multipart(
          "/api/v1/upload/#{uuid}/images",
          payload_json,
          filename: "#{filename}.enc",
          mime_type: "application/octet-stream",
          fields: fields,
          headers: headers
        )
      end

      private

      # Normalize file input to raw bytes.
      #
      # @param file [String, IO] file path, IO object, or raw bytes
      # @return [String] raw binary data
      def read_file(file)
        if file.respond_to?(:read)
          file.read.b
        elsif file.is_a?(String) && looks_like_path?(file) && File.exist?(file)
          # Treat short strings that point to existing files as paths.
          # Raw image bytes will almost never be < 1024 bytes AND match an
          # existing filename, so this heuristic is safe in practice.
          File.binread(file)
        elsif file.is_a?(String)
          file.b
        else
          raise ArgumentError, "Unsupported file input. Use a file path String, IO object, or raw String bytes."
        end
      end

      # Heuristic: does this String plausibly name a file path (as opposed to
      # raw image bytes)? Must be short and contain no NUL byte. Calling
      # File.exist? on binary image data that contains a NUL byte raises
      # "ArgumentError: path name contains null byte", so we must guard it.
      #
      # @param str [String]
      # @return [Boolean]
      def looks_like_path?(str)
        str.length < 1024 && !str.include?("\x00")
      end
    end
  end
end
