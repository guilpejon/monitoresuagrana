require "test_helper"

class Expenses::GenerateRecurringJobTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = @user.categories.first
    @template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.current)
  end

  test "generates 11 future months from template" do
    assert_difference "Expense.count", 11 do
      Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    end
  end

  test "generated expenses are linked to template via recurring_source_id" do
    Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    generated = Expense.where(recurring_source_id: @template.id)
    assert_equal 11, generated.count
    assert generated.all?(&:recurring?)
  end

  test "does not duplicate already generated months" do
    next_month = Date.current >> 1
    create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: @template.id, date: next_month)

    assert_difference "Expense.count", 10 do
      Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    end
  end

  test "copies expense attributes from template on first run (no existing instances)" do
    Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)
    generated = Expense.where(recurring_source_id: @template.id).first
    assert_equal @template.description, generated.description
    assert_equal @template.amount, generated.amount
    assert_equal @template.expense_type, generated.expense_type
    assert_equal @template.category_id, generated.category_id
    assert_equal @template.payment_method, generated.payment_method
    assert_equal 1, generated.total_installments
    assert_equal 1, generated.installment_number
  end

  test "copies expense attributes from latest instance, not template, when instances already exist" do
    other_category = create(:category, user: @user)
    older_instance = create(:expense, user: @user, category: @category, expense_type: "fixed",
      recurring: true, recurring_source_id: @template.id,
      amount: 100.00, date: 1.month.from_now)
    latest_instance = create(:expense, user: @user, category: other_category, expense_type: "fixed",
      recurring: true, recurring_source_id: @template.id,
      amount: 250.00, date: 2.months.from_now)

    Expenses::GenerateRecurringJob.new.perform(template_id: @template.id)

    new_instance = Expense.where(recurring_source_id: @template.id).order(date: :desc).first
    assert_equal 250.00, new_instance.amount
    assert_equal other_category.id, new_instance.category_id
  end

  test "generates future instances for old templates beyond initial 12-month window" do
    old_template = create(:expense, user: @user, category: @category, expense_type: "fixed",
      recurring: true, date: 13.months.ago)
    # Simulate all old instances already existing
    (1..12).each do |i|
      create(:expense, user: @user, category: @category, expense_type: "fixed",
        recurring: true, recurring_source_id: old_template.id, amount: 100.00,
        date: (13 - i).months.ago)
    end

    assert_difference "Expense.count", 12 do
      Expenses::GenerateRecurringJob.new.perform(template_id: old_template.id)
    end

    generated_dates = Expense.where(recurring_source_id: old_template.id).where("date >= ?", Date.today).pluck(:date)
    assert_not_empty generated_dates
    assert generated_dates.all? { |d| d >= Date.today }
  end

  test "handles month-end day edge case (day 31 in short month)" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.new(Date.current.year, 1, 31))
    Expenses::GenerateRecurringJob.new.perform(template_id: template.id)
    feb = Expense.where(recurring_source_id: template.id).find { |e| e.date.month == 2 }
    assert_not_nil feb
    assert feb.date.day <= feb.date.end_of_month.day
  end

  test "rescues errors without re-raising" do
    assert_nothing_raised do
      Expenses::GenerateRecurringJob.new.perform(template_id: 0)
    end
  end

  test "when no template_id given processes all recurring templates" do
    other_template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.current)

    assert_difference "Expense.count", 22 do
      Expenses::GenerateRecurringJob.new.perform
    end
  end

  test "generated credit card recurring expenses have scheduled status" do
    cc_template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, payment_method: "credit_card", date: Date.current)
    Expenses::GenerateRecurringJob.new.perform(template_id: cc_template.id)
    generated = Expense.where(recurring_source_id: cc_template.id)
    assert generated.all? { |e| e.payment_status == "scheduled" }
  end

  test "ignores templates that are generated expenses themselves" do
    generated = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: @template.id)
    count_before = Expense.count
    Expenses::GenerateRecurringJob.new.perform(template_id: generated.id)
    assert_equal count_before, Expense.count
  end
end
