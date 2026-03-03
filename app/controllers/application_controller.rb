class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_locale
  before_action :authenticate_user!
  before_action :set_current_date
  before_action :configure_permitted_parameters, if: :devise_controller?

  include Pagy::Backend

  private

  def set_current_date
    return unless current_user

    today = Date.current.beginning_of_month
    min_date = today - 24.months

    latest_entry = [
      current_user.expenses.maximum(:date),
      current_user.incomes.maximum(:date)
    ].compact.max
    latest_month = latest_entry&.beginning_of_month
    @max_date = [ today + 12.months, latest_month ].compact.max

    if params[:month].present?
      date = Date.parse("#{params[:month]}-01")
      date = date.clamp(min_date, @max_date)
      session[:current_month] = date.strftime("%Y-%m")
      @current_date = date
    elsif session[:current_month].present?
      @current_date = Date.parse("#{session[:current_month]}-01").clamp(min_date, @max_date)
    else
      @current_date = today
    end
  rescue ArgumentError
    @current_date = Date.current.beginning_of_month
  end

  def set_locale
    if current_user
      I18n.locale = current_user.locale || I18n.default_locale
    elsif cookies[:locale].present?
      I18n.locale = cookies[:locale]
    elsif session[:locale].present?
      I18n.locale = session[:locale]
    else
      detected = detect_locale_from_browser
      session[:locale] = detected
      I18n.locale = detected
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :currency, :locale ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :currency, :locale ])
  end

  def detect_locale_from_browser
    accept_language = request.env["HTTP_ACCEPT_LANGUAGE"]
    return I18n.default_locale.to_s if accept_language.blank?

    lang = accept_language.split(",").first&.split(";")&.first&.strip&.downcase || ""
    lang.start_with?("pt") ? "pt-BR" : "en"
  end
end
