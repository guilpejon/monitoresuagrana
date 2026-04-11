class CreditCardsController < ApplicationController
  before_action :set_credit_card, only: %i[edit update destroy set_default invoices]

  def index
    @credit_cards = current_user.credit_cards.order(:name)
  end

  def new
    @credit_card = current_user.credit_cards.build(
      billing_day: 1,
      due_day: 10,
      color: "#6C63FF"
    )
  end

  def create
    @credit_card = current_user.credit_cards.build(credit_card_params)

    if @credit_card.save
      redirect_to credit_cards_path, notice: t("controllers.credit_cards.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @credit_card.update(credit_card_params)
      redirect_to credit_cards_path, notice: t("controllers.credit_cards.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @credit_card.destroy
    redirect_to credit_cards_path, notice: t("controllers.credit_cards.destroyed")
  end

  def invoices
    current_start, current_end = @credit_card.billing_period(Date.current)
    past_periods     = @credit_card.billing_periods_history(12)
    upcoming_periods = @credit_card.billing_periods_upcoming(6)

    oldest_start = past_periods.last.first
    newest_end   = upcoming_periods.last.last
    expenses_in_range = @credit_card.expenses
                          .where(date: oldest_start..newest_end)
                          .select(:date, :amount, :recurring)

    build_entry = ->(ps, pe, status) do
      period_expenses = expenses_in_range.select { |e| e.date.between?(ps, pe) }
      period_expenses = period_expenses.reject(&:recurring?) if status == :upcoming
      total = period_expenses.sum(&:amount)
      { period_start: ps, period_end: pe, total: total, status: status }
    end

    @invoices = upcoming_periods.reverse.map { |ps, pe| build_entry.(ps, pe, :upcoming) } +
                [ build_entry.(current_start, current_end, :current) ] +
                past_periods.map { |ps, pe| build_entry.(ps, pe, :past) }
  end

  def set_default
    if current_user.default_credit_card_id == @credit_card.id
      current_user.update!(default_credit_card_id: nil)
      redirect_to credit_cards_path, notice: t("controllers.credit_cards.default_cleared")
    else
      current_user.update!(default_credit_card_id: @credit_card.id)
      redirect_to credit_cards_path, notice: t("controllers.credit_cards.default_set")
    end
  end

  private

  def set_credit_card
    @credit_card = current_user.credit_cards.find(params[:id])
  end

  def credit_card_params
    params.require(:credit_card).permit(:name, :limit, :last4, :brand, :color, :billing_day, :due_day)
  end
end
