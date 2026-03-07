class DashboardController < ApplicationController
  def index
    today = Date.current

    incomes = current_user.incomes.for_month(today)
    expenses = current_user.expenses.for_month(today)
    @net_balance = incomes.sum(:amount) - expenses.sum(:amount)

    # Credit card bills this month
    @credit_cards = current_user.credit_cards.includes(:expenses)
    @total_card_bills = @credit_cards.sum { |card| card.current_bill(today) }

    # Monthly cash flow for last 6 months (bar chart)
    @monthly_income = current_user.incomes
      .where(date: 6.months.ago.beginning_of_month..Date.current.end_of_month)
      .group_by_month(:date, format: "%b %Y")
      .sum(:amount)

    @monthly_expenses = current_user.expenses
      .where(date: 6.months.ago.beginning_of_month..Date.current.end_of_month)
      .group_by_month(:date, format: "%b %Y")
      .sum(:amount)

    # Bank accounts total balance
    @total_bank_balance = current_user.bank_accounts.sum(:balance)

    # Possessions total current value
    @total_possessions_value = current_user.possessions.sum(:current_value)

    # Investments
    investments = current_user.investments.to_a
    @total_invested = investments.sum(&:total_invested)
    @total_portfolio_value = investments.sum(&:current_value)
    @portfolio_profit_loss = @total_portfolio_value - @total_invested
    @portfolio_profit_loss_percent = @total_invested.nonzero? ? (@portfolio_profit_loss / @total_invested * 100).round(1) : 0
    @portfolio_by_type = investments
      .group_by(&:investment_type)
      .transform_values { |invs| invs.sum(&:current_value).to_f }
      .reject { |_, v| v.zero? }

    # Wealth distribution
    @wealth_distribution = {
      "bank"        => @total_bank_balance.to_f,
      "investments" => @total_portfolio_value.to_f,
      "possessions" => @total_possessions_value.to_f
    }.reject { |_, v| v <= 0 }

    # Recent transactions
    @recent_transactions = current_user.expenses
      .includes(:category)
      .where("date <= ?", Date.current)
      .where(recurring_source_id: nil)
      .order(date: :desc, created_at: :desc)
      .limit(5)
  end
end
