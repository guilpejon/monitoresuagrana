class ForecastController < ApplicationController
  def index
    # All recurring expenses (not month-specific — these repeat every month)
    @recurring_expenses = current_user.expenses
      .recurring
      .includes(:category)
      .order("categories.name")

    # Projected spending by category from recurring
    @projected_by_category = @recurring_expenses
      .joins(:category)
      .group("categories.name", "categories.color")
      .sum(:amount)

    # Previous month actuals for comparison
    prev_month = @current_date - 1.month
    @prev_month_label = prev_month.strftime("%B %Y")
    @prev_month_total = current_user.expenses.for_month(prev_month).sum(:amount)
    @prev_month_by_category = current_user.expenses
      .for_month(prev_month)
      .joins(:category)
      .group("categories.name")
      .sum(:amount)

    @projected_total = @recurring_expenses.sum(:amount)

    # Projected income from recurring
    @recurring_incomes = current_user.incomes.where(recurring: true)
    @projected_income = @recurring_incomes.sum(:amount)
    @projected_balance = @projected_income - @projected_total

    # Chart data
    @forecast_chart_data = @projected_by_category.map { |cat, amt| [cat, amt.to_f] }.to_h
  end
end
