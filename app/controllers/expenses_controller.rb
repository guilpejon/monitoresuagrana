class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[edit update destroy update_status]
  before_action :prevent_locked_edit, only: %i[edit update]

  def index
    base = current_user.expenses
      .includes(:category, :credit_card)
      .for_month(@current_date)
      .ordered

    @fixed_expenses = base.fixed
    @variable_expenses = base.variable
    @variable_regular_expenses = @variable_expenses.reject(&:installment?)
    @variable_installment_expenses = @variable_expenses.select(&:installment?)
    @variable_installment_total = @variable_installment_expenses.sum(&:amount)
    @variable_regular_total = @variable_regular_expenses.sum(&:amount)

    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    @bank_accounts = current_user.bank_accounts.order(:name)

    totals = current_user.expenses.for_month(@current_date).group(:expense_type).sum(:amount)
    @fixed_total = totals["fixed"] || 0
    @variable_total = totals["variable"] || 0
    @total = @fixed_total + @variable_total
  end

  def new
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    @bank_accounts = current_user.bank_accounts.order(:name)
    default_category = @categories.find { |c| c.id == current_user.default_category_id } || @categories.first
    @expense = current_user.expenses.build(date: @current_date, expense_type: "variable", category: default_category, credit_card_id: current_user.default_credit_card_id)
    @quick = params[:quick].present?
  end

  def create
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
    @bank_accounts = current_user.bank_accounts.order(:name)
  end

  def update
    was_recurring = @expense.recurring?
    source_id = @expense.recurring_source_id
    if @expense.update(expense_params)
      propagate_bank_account_to_installment_group!
      propagate_recurring_changes!
      if was_recurring && !@expense.recurring?
        cutoff = @expense.date.next_month.beginning_of_month
        if source_id.present?
          current_user.expenses
            .where(recurring_source_id: source_id)
            .where("date >= ?", cutoff)
            .destroy_all
          current_user.expenses.find_by(id: source_id)&.update(recurring: false)
        else
          current_user.expenses
            .where(recurring_source_id: @expense.id)
            .where("date >= ?", cutoff)
            .destroy_all
        end
      end
      redirect_to expenses_path, notice: t("controllers.expenses.updated")
    else
      @categories = current_user.categories.order(:name)
      @credit_cards = current_user.credit_cards.order(:name)
      @bank_accounts = current_user.bank_accounts.order(:name)
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
    group_id = @expense.installment? ? @expense.installment_group_id : nil

    if params[:delete_following].present?
      if @expense.recurring_source_id.present?
        current_user.expenses
          .where(recurring_source_id: @expense.recurring_source_id)
          .where("date >= ?", @expense.date)
          .destroy_all
      elsif @expense.installment?
        current_user.expenses
          .where(installment_group_id: group_id)
          .where("installment_number >= ?", @expense.installment_number)
          .destroy_all
        renumber_installments(group_id)
      else
        @expense.destroy
      end
      redirect_to expenses_path, notice: t("controllers.expenses.destroyed")
    else
      @expense.destroy
      if group_id
        renumber_installments(group_id)
        redirect_to expenses_path, notice: t("controllers.expenses.destroyed")
      else
        respond_to do |format|
          format.html { redirect_to expenses_path, notice: t("controllers.expenses.destroyed") }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("expense_#{@expense.id}"),
              turbo_stream.prepend("flash-messages", partial: "layouts/flash", locals: { type: :notice, message: t("controllers.expenses.destroyed") })
            ]
          end
        end
      end
    end
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def prevent_locked_edit
    if (@expense.recurring? || @expense.installment?) && @expense.date < Date.current.beginning_of_month
      redirect_to expenses_path, alert: t("controllers.expenses.edit_locked")
    end
  end

  def expense_params
    params.require(:expense).permit(
      :description, :amount, :date, :expense_type, :category_id, :credit_card_id,
      :bank_account_id, :recurring, :recurrence_day, :payment_method, :total_installments,
      :installment_number, :installment_group_id, :payment_status
    )
  end

  def propagate_recurring_changes!
    return unless @expense.recurring? && !@expense.installment?
    return unless @expense.saved_change_to_amount? || @expense.saved_change_to_category_id? ||
                  @expense.saved_change_to_date? || @expense.saved_change_to_credit_card_id? ||
                  @expense.saved_change_to_bank_account_id?

    source_id = @expense.recurring_source_id || @expense.id

    bulk_updates = {}
    bulk_updates[:amount] = @expense.amount if @expense.saved_change_to_amount?
    bulk_updates[:category_id] = @expense.category_id if @expense.saved_change_to_category_id?
    bulk_updates[:credit_card_id] = @expense.credit_card_id if @expense.saved_change_to_credit_card_id?
    bulk_updates[:bank_account_id] = @expense.bank_account_id if @expense.saved_change_to_bank_account_id?

    if bulk_updates.any?
      current_user.expenses
        .where(recurring_source_id: source_id)
        .where("date > ?", Date.today)
        .update_all(bulk_updates)
    end

    if @expense.saved_change_to_date?
      old_day = @expense.saved_changes[:date][0].day
      new_day = @expense.date.day
      if old_day != new_day
        current_user.expenses
          .where(recurring_source_id: source_id)
          .where("date > ?", Date.today)
          .find_each do |future|
            future.update_column(:date, future.date.change(day: [ new_day, future.date.end_of_month.day ].min))
          end

        template = current_user.expenses.find_by(id: source_id)
        template&.update_column(:recurrence_day, new_day)
      end
    end
  end

  def propagate_bank_account_to_installment_group!
    return if @expense.installment_group_id.blank?
    return unless @expense.saved_change_to_bank_account_id?

    current_user.expenses
      .where(installment_group_id: @expense.installment_group_id)
      .where.not(id: @expense.id)
      .update_all(bank_account_id: @expense.bank_account_id)
  end

  def renumber_installments(group_id)
    remaining = current_user.expenses
      .where(installment_group_id: group_id)
      .order(:installment_number)
    return if remaining.empty?
    total = remaining.count
    remaining.each_with_index do |expense, index|
      expense.update_columns(installment_number: index + 1, total_installments: total)
    end
  end

  def render_new_with_collections
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    @bank_accounts = current_user.bank_accounts.order(:name)
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
      @expense = records.find(&:invalid?) || records.first
      render_new_with_collections
    end
  end
end
