class InvestmentsController < ApplicationController
  before_action :set_investment, only: %i[edit update destroy refresh_price]

  def index
    @investments = current_user.investments.order(:investment_type, :name)

    @total_invested = @investments.sum { |i| i.total_invested }
    @current_value = @investments.sum { |i| i.current_value }
    @total_pnl = @current_value - @total_invested
    @total_pnl_percent = @total_invested.positive? ? (@total_pnl / @total_invested * 100).round(2) : 0

    @by_type = @investments.group_by(&:investment_type)
  end

  def new
    @investment = current_user.investments.build(
      investment_type: "stock",
      currency: "BRL",
      quantity: 0,
      average_price: 0,
      current_price: 0
    )
  end

  def create
    @investment = current_user.investments.build(investment_params)

    if @investment.save
      Investments::FetchPriceJob.perform_later(@investment.id) if @investment.ticker.present?
      redirect_to investments_path, notice: "Investment added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @investment.update(investment_params)
      redirect_to investments_path, notice: "Investment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @investment.destroy
    redirect_to investments_path, notice: "Investment removed."
  end

  def refresh_price
    Investments::FetchPriceJob.perform_later(@investment.id)
    redirect_to investments_path, notice: "Price refresh queued for #{@investment.name}."
  end

  def refresh_all_prices
    current_user.investments.where.not(ticker: [nil, ""]).each do |inv|
      Investments::FetchPriceJob.perform_later(inv.id)
    end
    redirect_to investments_path, notice: "Price refresh queued for all investments."
  end

  private

  def set_investment
    @investment = current_user.investments.find(params[:id])
  end

  def investment_params
    params.require(:investment).permit(:name, :ticker, :investment_type, :quantity, :average_price, :current_price, :currency)
  end
end
