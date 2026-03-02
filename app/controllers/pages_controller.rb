class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_date

  def showcase
  end
end
