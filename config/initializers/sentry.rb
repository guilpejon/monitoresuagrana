Sentry.init do |config|
  config.dsn = "https://7d13fb542833c58274a337d59ed7c4b7@o531033.ingest.us.sentry.io/4511175698481152"

  # Only report errors in production — avoid noise from local dev/test
  config.enabled_environments = %w[production]
  config.environment = Rails.env

  # Tag releases so you can track which deploy introduced an error
  config.release = ENV["KAMAL_VERSION"]

  # Breadcrumbs: trace ActiveSupport notifications and outbound HTTP (HTTParty)
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Include request headers and IP — useful for diagnosing user-reported issues
  config.send_default_pii = true

  # Performance monitoring: capture 10% of transactions (low overhead on Raspberry Pi)
  config.traces_sample_rate = 0.1

  # Ignore high-volume, non-actionable errors
  config.excluded_exceptions += [
    "ActionController::RoutingError",       # 404s from bots/crawlers
    "ActionController::InvalidAuthenticityToken", # CSRF (usually bots)
    "ActionDispatch::Http::MimeNegotiation::InvalidType",
    "Rack::Attack::Throttle"                # Rate-limited requests
  ]

  # Skip health check pings (/up) — Kamal hits this constantly
  config.before_send = lambda do |event, _hint|
    path = event.request&.url
    return nil if path&.include?("/up")
    event
  end
end
