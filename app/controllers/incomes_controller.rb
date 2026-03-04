class IncomesController < ApplicationController
  before_action :set_income, only: %i[edit update destroy]

  def index
    @incomes = current_user.incomes
      .for_month(@current_date)
      .ordered

    @pagy, @incomes = pagy(@incomes, limit: 20)
    @total = current_user.incomes.for_month(@current_date).sum(:amount)
  end

  def new
    @income = current_user.incomes.build(date: @current_date, income_type: "salary")
  end

  def create
    @income = current_user.incomes.build(income_params)

    if @income.save
      Incomes::GenerateRecurringJob.perform_later(template_id: @income.id) if @income.recurring?
      redirect_to incomes_path, notice: t("controllers.incomes.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    was_recurring = @income.recurring?
    source_id = @income.recurring_source_id
    if @income.update(income_params)
      if was_recurring && !@income.recurring?
        if source_id.present?
          current_user.incomes
            .where(recurring_source_id: source_id)
            .where("date > ?", @income.date)
            .destroy_all
          current_user.incomes.find_by(id: source_id)&.update(recurring: false)
        else
          current_user.incomes
            .where(recurring_source_id: @income.id)
            .where("date >= ?", Date.today)
            .destroy_all
        end
      end
      redirect_to incomes_path, notice: t("controllers.incomes.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:delete_following].present? && @income.recurring_source_id.present?
      current_user.incomes
        .where(recurring_source_id: @income.recurring_source_id)
        .where("date >= ?", @income.date)
        .destroy_all
      redirect_to incomes_path, notice: t("controllers.incomes.destroyed")
    else
      @income.destroy
      respond_to do |format|
        format.html { redirect_to incomes_path, notice: t("controllers.incomes.destroyed") }
        format.turbo_stream { render turbo_stream: turbo_stream.remove("income_#{@income.id}") }
      end
    end
  end

  private

  def set_income
    @income = current_user.incomes.find(params[:id])
  end

  def income_params
    params.require(:income).permit(:description, :amount, :date, :income_type, :recurring, :recurrence_day)
  end
end
