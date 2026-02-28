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
    @income = current_user.incomes.build(date: Date.current, income_type: "salary")
  end

  def create
    @income = current_user.incomes.build(income_params)

    if @income.save
      respond_to do |format|
        format.html { redirect_to incomes_path, notice: "Income added." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("incomes_list", partial: "incomes/income", locals: { income: @income }),
            turbo_stream.update("incomes_total", partial: "incomes/total", locals: { total: current_user.incomes.for_month(@current_date).sum(:amount) })
          ]
        end
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @income.update(income_params)
      redirect_to incomes_path, notice: "Income updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @income.destroy
    respond_to do |format|
      format.html { redirect_to incomes_path, notice: "Income deleted." }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("income_#{@income.id}") }
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
