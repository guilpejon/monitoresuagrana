class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_current_date
  before_action :configure_permitted_parameters, if: :devise_controller?

  include Pagy::Backend

  private

  def set_current_date
    if params[:month].present?
      @current_date = Date.parse("#{params[:month]}-01")
    else
      @current_date = Date.current.beginning_of_month
    end
  rescue ArgumentError
    @current_date = Date.current.beginning_of_month
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :currency])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :currency])
  end
end
