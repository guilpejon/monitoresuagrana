class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[edit update destroy update_status]

  def index
    @expenses = current_user.expenses
      .includes(:category, :credit_card, :payee)
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
    resolve_payee!
    total_installments = expense_params[:total_installments].to_i.clamp(1, 60)

    if total_installments > 1
      create_installments(total_installments)
    else
      @expense = current_user.expenses.build(expense_params)
      if @expense.save
        Expenses::GenerateRecurringJob.perform_later(template_id: @expense.id) if @expense.recurring?
        redirect_to expenses_path, notice: t("controllers.expenses.created")
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
    resolve_payee!
    if @expense.update(expense_params)
      propagate_payee_to_installment_group!
      redirect_to expenses_path, notice: t("controllers.expenses.updated")
    else
      @categories = current_user.categories.order(:name)
      @credit_cards = current_user.credit_cards.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def update_status
    @expense.update!(payment_status: @expense.next_payment_status)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "expense_#{@expense.id}",
          partial: "expenses/expense",
          locals: { expense: @expense }
        )
      end
      format.html { redirect_to expenses_path }
    end
  end

  def destroy
    @expense.destroy
    respond_to do |format|
      format.html { redirect_to expenses_path, notice: t("controllers.expenses.destroyed") }
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
      :installment_number, :installment_group_id, :payee_id, :payment_status
    )
  end

  def resolve_payee!
    name = params.dig(:expense, :payee_name).to_s.strip
    payee_id = params.dig(:expense, :payee_id).to_s.strip

    return if name.blank?

    if payee_id.blank?
      payee = current_user.payees.find_or_create_by!(name: name)
      params[:expense][:payee_id] = payee.id
    end
  end

  def propagate_payee_to_installment_group!
    return if @expense.installment_group_id.blank?

    current_user.expenses
      .where(installment_group_id: @expense.installment_group_id)
      .where.not(id: @expense.id)
      .update_all(payee_id: @expense.payee_id)
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
      redirect_to expenses_path, notice: t("controllers.expenses.created_installments", count: total_installments)
    else
      @expense = records.first
      render_new_with_collections
    end
  end
end
