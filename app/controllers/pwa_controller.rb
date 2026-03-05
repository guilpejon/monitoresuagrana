class PwaController < ActionController::Base
  skip_forgery_protection

  def service_worker
    render template: "pwa/service-worker", layout: false, content_type: "text/javascript"
  end

  def manifest
    render template: "pwa/manifest", layout: false, content_type: "application/json"
  end
end
