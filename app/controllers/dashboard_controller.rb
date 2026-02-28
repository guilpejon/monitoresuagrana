class DashboardController < ApplicationController
  def index
    @incomes = current_user.incomes.for_month(@current_date)
    @expenses = current_user.expenses.for_month(@current_date).includes(:category, :credit_card)

    @total_income = @incomes.sum(:amount)
    @total_expenses = @expenses.sum(:amount)
    @net_balance = @total_income - @total_expenses

    # Credit card bills this month
    @credit_cards = current_user.credit_cards
    @total_card_bills = @credit_cards.sum { |card| card.current_bill(@current_date) }

    # Spending by category for donut chart
    @spending_by_category = @expenses
      .joins(:category)
      .group("categories.name")
      .sum(:amount)
      .sort_by { |_, v| -v }
      .first(8)
      .to_h

    # Monthly cash flow for last 6 months (bar chart)
    @monthly_income = current_user.incomes
      .where(date: 6.months.ago.beginning_of_month..Date.current.end_of_month)
      .group_by_month(:date, format: "%b %Y")
      .sum(:amount)

    @monthly_expenses = current_user.expenses
      .where(date: 6.months.ago.beginning_of_month..Date.current.end_of_month)
      .group_by_month(:date, format: "%b %Y")
      .sum(:amount)

    # Recent transactions
    @recent_transactions = current_user.expenses
      .includes(:category)
      .order(date: :desc, created_at: :desc)
      .limit(5)
  end
end
