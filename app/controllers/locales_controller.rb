class LocalesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_date

  def set
    locale = params[:locale].in?(%w[en pt-BR]) ? params[:locale] : I18n.default_locale.to_s
    cookies.permanent[:locale] = locale
    session[:locale] = locale
    redirect_back fallback_location: root_path
  end
end
