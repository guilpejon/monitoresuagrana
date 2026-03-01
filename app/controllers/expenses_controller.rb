class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[edit update destroy]

  def index
    @expenses = current_user.expenses
      .includes(:category, :credit_card)
      .for_month(@current_date)
      .ordered

    @pagy, @expenses = pagy(@expenses, limit: 20)
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    @total = current_user.expenses.for_month(@current_date).sum(:amount)
  end

  def new
    @expense = current_user.expenses.build(date: Date.current, expense_type: "variable")
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    @quick = params[:quick].present?
  end

  def create
    total_installments = expense_params[:total_installments].to_i.clamp(1, 60)

    if total_installments > 1
      create_installments(total_installments)
    else
      @expense = current_user.expenses.build(expense_params)
      if @expense.save
        redirect_to expenses_path, notice: "Expense added."
      else
        render_new_with_collections
      end
    end
  end

  def edit
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
  end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: "Expense updated."
    else
      @categories = current_user.categories.order(:name)
      @credit_cards = current_user.credit_cards.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    respond_to do |format|
      format.html { redirect_to expenses_path, notice: "Expense deleted." }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("expense_#{@expense.id}") }
    end
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(
      :description, :amount, :date, :expense_type, :category_id, :credit_card_id,
      :recurring, :recurrence_day, :payment_method, :total_installments,
      :installment_number, :installment_group_id
    )
  end

  def render_new_with_collections
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    render :new, status: :unprocessable_entity
  end

  def create_installments(total_installments)
    @expense = current_user.expenses.build(expense_params)
    group_id  = SecureRandom.uuid
    total     = @expense.amount
    per       = (total / total_installments).round(2)
    base_date = @expense.date

    records = (1..total_installments).map do |n|
      amount = n == total_installments ? total - per * (total_installments - 1) : per
      current_user.expenses.build(
        expense_params.merge(
          date: base_date >> (n - 1),
          amount: amount,
          installment_number: n,
          total_installments: total_installments,
          installment_group_id: group_id
        )
      )
    end

    if records.all?(&:valid?)
      ActiveRecord::Base.transaction { records.each(&:save!) }
      redirect_to expenses_path, notice: "Expense added in #{total_installments} installments."
    else
      @expense = records.first
      render_new_with_collections
    end
  end
end
