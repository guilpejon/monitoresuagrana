class ForecastController < ApplicationController
  def index
    @is_past_month = @current_date < Date.current.beginning_of_month

    if @is_past_month
      actual_expenses_scope = current_user.expenses
        .for_month(@current_date)
        .includes(:category, :credit_card)

      @actual_total = actual_expenses_scope.sum(:amount)
      @actual_expenses = actual_expenses_scope.order(date: :desc).to_a

      @actual_by_payment_method = @actual_expenses
        .group_by(&:payment_method)
        .transform_values { |exps| exps.sum(&:amount) }
        .reject { |_, v| v.zero? }

      @credit_card_bills = @actual_expenses
        .select { |e| e.payment_method == "credit_card" && e.credit_card }
        .group_by(&:credit_card)
        .transform_values { |exps| exps.sum(&:amount) }
        .sort_by { |_, v| -v }
        .to_h

      @actual_incomes = current_user.incomes.for_month(@current_date)
      @actual_income_total = @actual_incomes.sum(:amount)
      @actual_balance = @actual_income_total - @actual_total

      grouped_by_category = @actual_expenses.group_by(&:category)
      @forecast_chart_data = grouped_by_category
        .map { |cat, exps| [ I18n.t("category_names.#{cat.name}", default: cat.name), exps.sum(&:amount).to_f ] }
        .to_h
      @forecast_chart_colors = grouped_by_category.keys.map(&:color)
    else
      # All recurring expenses (not month-specific — these repeat every month)
      @recurring_expenses = current_user.expenses
        .recurring
        .where(recurring_source_id: nil)
        .includes(:category, :credit_card)
        .order("categories.name")

      # Installment expenses due this month (not already counted as recurring)
      @installment_expenses = current_user.expenses
        .for_month(@current_date)
        .where("total_installments > 1")
        .where(recurring: false)
        .includes(:category, :credit_card)
        .order("categories.name")

      # One-off expenses already recorded this month
      @oneoff_expenses = current_user.expenses
        .for_month(@current_date)
        .where(recurring: false)
        .where("total_installments IS NULL OR total_installments <= 1")
        .includes(:category, :credit_card)
        .order("categories.name")

      # Projected spending by category (recurring + installments + one-offs combined)
      recurring_by_category = @recurring_expenses
        .joins(:category)
        .group("categories.name", "categories.color")
        .sum(:amount)

      installment_by_category = @installment_expenses
        .joins(:category)
        .group("categories.name", "categories.color")
        .sum(:amount)

      oneoff_by_category = @oneoff_expenses
        .joins(:category)
        .group("categories.name", "categories.color")
        .sum(:amount)

      @projected_by_category = recurring_by_category
        .merge(installment_by_category) { |_key, a, b| a + b }
        .merge(oneoff_by_category) { |_key, a, b| a + b }

      # Load into memory for in-memory aggregation (avoids extra SQL queries)
      all_projected = @recurring_expenses.to_a + @installment_expenses.to_a + @oneoff_expenses.to_a
      @projected_total = all_projected.sum(&:amount)

      # Breakdown by payment method (boleto, credit_card, pix, cash)
      @projected_by_payment_method = all_projected
        .group_by(&:payment_method)
        .transform_values { |exps| exps.sum(&:amount) }
        .reject { |_, v| v.zero? }

      # Credit card projected bills grouped by card
      @credit_card_bills = all_projected
        .select { |e| e.payment_method == "credit_card" && e.credit_card }
        .group_by(&:credit_card)
        .transform_values { |exps| exps.sum(&:amount) }
        .sort_by { |_, v| -v }
        .to_h

      # Projected income from recurring
      @recurring_incomes = current_user.incomes.where(recurring: true)
      @projected_income = @recurring_incomes.sum(:amount)
      @projected_balance = @projected_income - @projected_total

      # Chart data (with translated category names)
      @forecast_chart_data = @projected_by_category.map { |(name, _color), amt| [ I18n.t("category_names.#{name}", default: name), amt.to_f ] }.to_h
      @forecast_chart_colors = @projected_by_category.keys.map { |(_name, color)| color }
    end

    # Previous month actuals for comparison
    prev_month = @current_date - 1.month
    @prev_month_label = I18n.l(prev_month, format: "%B %Y")
    prev_month_expenses = current_user.expenses.for_month(prev_month).sum(:amount)
    prev_month_income = current_user.incomes.for_month(prev_month).sum(:amount)
    @prev_month_balance = prev_month_income - prev_month_expenses
    @prev_month_by_category = current_user.expenses
      .for_month(prev_month)
      .joins(:category)
      .group("categories.name")
      .sum(:amount)
  end
end
