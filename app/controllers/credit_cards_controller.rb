class CreditCardsController < ApplicationController
  before_action :set_credit_card, only: %i[edit update destroy]

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
      redirect_to credit_cards_path, notice: "Credit card added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @credit_card.update(credit_card_params)
      redirect_to credit_cards_path, notice: "Credit card updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @credit_card.destroy
    redirect_to credit_cards_path, notice: "Credit card removed."
  end

  private

  def set_credit_card
    @credit_card = current_user.credit_cards.find(params[:id])
  end

  def credit_card_params
    params.require(:credit_card).permit(:name, :limit, :last4, :brand, :color, :billing_day, :due_day)
  end
end
