class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show edit update destroy set_default]

  def index
    @categories = current_user.categories.order(:name)
  end

  def show
    timeframe = params[:timeframe].presence_in(%w[current_month last_month 3m 6m 1y all custom]) || "current_month"
    @timeframe = timeframe

    if timeframe == "custom"
      @custom_start = params[:start_date].presence
      @custom_end   = params[:end_date].presence
      start_date = (Date.parse(@custom_start) rescue nil) if @custom_start
      end_date   = (Date.parse(@custom_end)   rescue nil) if @custom_end
    else
      start_date = case timeframe
      when "current_month" then Date.current.beginning_of_month
      when "last_month"    then 1.month.ago.beginning_of_month.to_date
      when "3m"            then 3.months.ago.beginning_of_month.to_date
      when "6m"            then 6.months.ago.beginning_of_month.to_date
      when "1y"            then 12.months.ago.beginning_of_month.to_date
      else nil
      end
      end_date = case timeframe
      when "current_month" then Date.current.end_of_month
      when "last_month"    then 1.month.ago.end_of_month.to_date
      when "3m", "6m", "1y" then Date.current
      else nil
      end
    end

    @period_label = period_label_for(timeframe, start_date, end_date)

    scope = @category.expenses.includes(:credit_card).order(date: :desc)
    scope = scope.where("date >= ?", start_date) if start_date
    scope = scope.where("date <= ?", end_date)   if end_date
    @expenses = scope.to_a

    @total_spent   = @expenses.sum(&:amount)
    @expense_count = @expenses.size

    effective_start = start_date || @expenses.last&.date
    effective_end   = end_date   || Date.current
    span_days       = effective_start ? [ (effective_end - effective_start).to_i + 1, 1 ].max : 1

    @avg_per_month            = @total_spent / [ span_days / 30.44, 1 ].max
    @avg_per_week             = @total_spent / [ span_days / 7.0,   1 ].max
    @avg_per_month_projection = span_days < 28
    @avg_per_week_projection  = span_days < 7
  end

  def new
    @category = current_user.categories.build(color: "#6C63FF")
  end

  def create
    @category = current_user.categories.build(category_params)

    if @category.save
      update_default_category
      redirect_to categories_path, notice: t("controllers.categories.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      update_default_category
      redirect_to categories_path, notice: t("controllers.categories.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to categories_path, notice: t("controllers.categories.destroyed")
    else
      redirect_to categories_path, alert: @category.errors.full_messages.to_sentence
    end
  end

  def set_default
    if current_user.default_category_id == @category.id
      current_user.update!(default_category_id: nil)
      redirect_to categories_path, notice: t("controllers.categories.default_cleared")
    else
      current_user.update!(default_category_id: @category.id)
      redirect_to categories_path, notice: t("controllers.categories.default_set")
    end
  end

  private

  def set_category
    @category = current_user.categories.find_by!(slug: params[:id])
  end

  def period_label_for(timeframe, start_date, end_date)
    case timeframe
    when "current_month" then t("categories.show.timeframe_current_month")
    when "last_month"    then t("categories.show.timeframe_last_month")
    when "3m"    then t("categories.show.timeframe_3m")
    when "6m"    then t("categories.show.timeframe_6m")
    when "1y"    then t("categories.show.timeframe_1y")
    when "all"   then t("categories.show.timeframe_all")
    when "custom"
      parts = [
        start_date&.strftime("%-d %b %Y"),
        end_date&.strftime("%-d %b %Y")
      ].compact
      parts.any? ? parts.join(" – ") : t("categories.show.timeframe_custom")
    end
  end

  def category_params
    params.require(:category).permit(:name, :color, :icon)
  end

  def update_default_category
    if params[:set_as_default] == "1"
      current_user.update_column(:default_category_id, @category.id)
    elsif current_user.default_category_id == @category.id
      current_user.update_column(:default_category_id, nil)
    end
  end
end
