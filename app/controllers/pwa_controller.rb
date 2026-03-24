class PwaController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_same_origin_request, only: :service_worker

  def service_worker
    render template: "pwa/service-worker", layout: false, content_type: "text/javascript", formats: [ :js ]
  end

  def manifest
    render template: "pwa/manifest", layout: false, content_type: "application/json"
  end
end
