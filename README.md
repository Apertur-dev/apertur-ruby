# Apertur Ruby SDK

Official Ruby client for the [Apertur](https://apertur.ca) image upload and delivery API.

## Installation

Add to your Gemfile:

```ruby
gem "apertur-sdk"
```

Or install directly:

```sh
gem install apertur-sdk
```

## Quick Start

```ruby
require "apertur"

client = Apertur::Client.new(api_key: "aptr_test_your_key_here")

# Create an upload session
session = client.sessions.create(max_images: 10)
puts session["uuid"]

# Upload an image
result = client.upload.image(session["uuid"], "/path/to/photo.jpg")

# Upload with encryption
server_key = client.encryption.get_server_key
client.upload.image_encrypted(
  session["uuid"],
  "/path/to/photo.jpg",
  server_key["publicKey"]
)
```

## Authentication

The SDK accepts an API key (prefixed `aptr_` or `aptr_test_`) or an OAuth token. The environment is auto-detected from the key prefix:

- `aptr_test_*` keys target the sandbox at `https://sandbox.api.aptr.ca`
- `aptr_*` keys target production at `https://api.aptr.ca`

You can override the base URL:

```ruby
client = Apertur::Client.new(api_key: "aptr_...", base_url: "http://localhost:3000")
```

## Resources

### Sessions

```ruby
client.sessions.create(max_images: 5, expires_in_hours: 24)
client.sessions.get("uuid")
client.sessions.update("uuid", max_images: 10)
client.sessions.list(page: 1, page_size: 20)
client.sessions.recent(limit: 5)
client.sessions.qr("uuid", format: "png", size: 300)
client.sessions.verify_password("uuid", "secret")

# Delivery status returns:
#   { "status" => "pending|active|completed|expired",
#     "files" => [...], "lastChanged" => "<ISO 8601>" }
client.sessions.delivery_status("uuid")

# Long-poll: server holds up to 5 min until something changes. Passing
# `poll_from:` widens the per-request read timeout to 360 s automatically.
client.sessions.delivery_status("uuid", poll_from: "2026-04-18T12:34:56Z")
```

### Upload

```ruby
# Multipart upload from file path
client.upload.image("uuid", "/path/to/image.jpg")

# Upload from IO
File.open("photo.png", "rb") do |f|
  client.upload.image("uuid", f, filename: "photo.png", mime_type: "image/png")
end

# Encrypted upload
client.upload.image_encrypted("uuid", "/path/to/image.jpg", public_key_pem)
```

### Uploads

```ruby
client.uploads.list(page: 1, page_size: 20)
client.uploads.recent(limit: 10)
```

### Polling

```ruby
# One-shot poll
result = client.polling.list("uuid")
data = client.polling.download("uuid", image_id)
client.polling.ack("uuid", image_id)

# Blocking loop
client.polling.poll_and_process("uuid", interval: 3) do |image, data|
  File.binwrite("downloads/#{image['id']}.jpg", data)
end
```

### Destinations

```ruby
client.destinations.list("project_id")
client.destinations.create("project_id", type: "s3", bucket: "my-bucket")
client.destinations.update("project_id", "dest_id", bucket: "other-bucket")
client.destinations.delete("project_id", "dest_id")
client.destinations.test("project_id", "dest_id")
```

### Keys

```ruby
client.keys.list("project_id")
client.keys.create("project_id", name: "My Key")
client.keys.update("project_id", "key_id", name: "Renamed Key")
client.keys.delete("project_id", "key_id")
client.keys.set_destinations("key_id", ["dest_1", "dest_2"], long_polling_enabled: true)
```

### Webhooks

```ruby
client.webhooks.list("project_id")
client.webhooks.create("project_id", url: "https://example.com/hook", events: ["upload.completed"])
client.webhooks.update("project_id", "webhook_id", url: "https://example.com/hook2")
client.webhooks.delete("project_id", "webhook_id")
client.webhooks.test("project_id", "webhook_id")
client.webhooks.deliveries("project_id", "webhook_id", page: 1, limit: 20)
client.webhooks.retry_delivery("project_id", "webhook_id", "delivery_id")
```

### Encryption

```ruby
server_key = client.encryption.get_server_key
```

### Stats

```ruby
stats = client.stats.get
```

## Webhook Signature Verification

```ruby
# Simple webhook
Apertur::Signature.verify_webhook(request_body, signature_header, secret)

# Event webhook with timestamp
Apertur::Signature.verify_event(request_body, timestamp_header, signature_header, secret)

# Svix-style webhook
Apertur::Signature.verify_svix(request_body, svix_id, svix_timestamp, svix_signature, secret)
```

## Client-Side Encryption

```ruby
encrypted = Apertur::Crypto.encrypt_image(raw_bytes, public_key_pem)
# => { "encrypted_key" => "...", "iv" => "...", "encrypted_data" => "...", "algorithm" => "RSA-OAEP+AES-256-GCM" }
```

## Error Handling

```ruby
begin
  client.sessions.get("nonexistent")
rescue Apertur::NotFoundError => e
  puts "Not found: #{e.message}"
rescue Apertur::AuthenticationError => e
  puts "Auth failed: #{e.message}"
rescue Apertur::RateLimitError => e
  puts "Rate limited, retry after #{e.retry_after}s"
rescue Apertur::ValidationError => e
  puts "Invalid request: #{e.message}"
rescue Apertur::Error => e
  puts "API error #{e.status_code}: #{e.message}"
end
```

## Requirements

- Ruby >= 3.0
- No external dependencies (uses `net/http`, `json`, and `openssl` from stdlib)

## License

MIT
