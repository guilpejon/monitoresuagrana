class BankAccountsController < ApplicationController
  before_action :set_bank_account, only: %i[edit update destroy set_default]

  def index
    @bank_accounts = current_user.bank_accounts.order(:account_type, :name)

    @total_balance = @bank_accounts.sum(:balance)
    @total_monthly_interest = @bank_accounts.sum { |a| a.monthly_interest }
    @total_yearly_interest = @bank_accounts.sum { |a| a.yearly_interest }

    @by_type = @bank_accounts.group_by(&:account_type)
    @cdi_info = CdiRate.cached_info
    @cdi_rate = @cdi_info&.fetch(:rate)
  end

  def new
    @bank_account = current_user.bank_accounts.build(
      account_type: "checking",
      balance: 0,
      interest_rate: 0,
      currency: "BRL",
      color: "#6C63FF",
      rate_type: "fixed",
      cdi_multiplier: 100
    )
    @cdi_info = CdiRate.cached_info
  end

  def create
    @bank_account = current_user.bank_accounts.build(bank_account_params)

    if @bank_account.save
      redirect_to bank_accounts_path, notice: t("controllers.bank_accounts.created")
    else
      @cdi_info = CdiRate.cached_info
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @cdi_info = CdiRate.cached_info
  end

  def update
    if @bank_account.update(bank_account_params)
      redirect_to bank_accounts_path, notice: t("controllers.bank_accounts.updated")
    else
      @cdi_info = CdiRate.cached_info
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bank_account.destroy
    redirect_to bank_accounts_path, notice: t("controllers.bank_accounts.destroyed")
  end

  def set_default
    if current_user.default_bank_account_id == @bank_account.id
      current_user.update!(default_bank_account_id: nil)
      redirect_to bank_accounts_path, notice: t("controllers.bank_accounts.default_cleared")
    else
      current_user.update!(default_bank_account_id: @bank_account.id)
      redirect_to bank_accounts_path, notice: t("controllers.bank_accounts.default_set")
    end
  end

  private

  def set_bank_account
    @bank_account = current_user.bank_accounts.find(params[:id])
  end

  def bank_account_params
    params.require(:bank_account).permit(:name, :bank_name, :account_type, :balance, :interest_rate, :currency, :color, :rate_type, :cdi_multiplier)
  end
end
