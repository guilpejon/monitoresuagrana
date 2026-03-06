require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  test "is valid with valid attributes" do
    expense = build(:expense)
    assert expense.valid?
  end

  test "allows blank description" do
    expense = build(:expense, description: nil)
    assert expense.valid?
    expense2 = build(:expense, description: "")
    assert expense2.valid?
  end

  test "requires amount" do
    expense = build(:expense, amount: nil)
    assert_not expense.valid?
    assert expense.errors[:amount].any?
  end

  test "requires amount greater than zero" do
    expense = build(:expense, amount: 0)
    assert_not expense.valid?
    expense2 = build(:expense, amount: -5)
    assert_not expense2.valid?
  end

  test "requires date" do
    expense = build(:expense, date: nil)
    assert_not expense.valid?
    assert expense.errors[:date].any?
  end

  test "requires valid expense_type" do
    expense = build(:expense, expense_type: "invalid")
    assert_not expense.valid?
  end

  test "accepts fixed expense_type" do
    expense = build(:expense, expense_type: "fixed")
    assert expense.valid?
  end

  test "accepts variable expense_type" do
    expense = build(:expense, expense_type: "variable")
    assert expense.valid?
  end

  test "validates recurrence_day is between 1 and 28" do
    expense = build(:expense, recurrence_day: 0)
    assert_not expense.valid?

    expense2 = build(:expense, recurrence_day: 29)
    assert_not expense2.valid?
  end

  test "accepts nil recurrence_day" do
    expense = build(:expense, recurrence_day: nil)
    assert expense.valid?
  end

  test "for_month scope filters by month" do
    user = create(:user)
    category = user.categories.first
    this_month = create(:expense, user: user, category: category, date: Date.current)
    last_month = create(:expense, user: user, category: category, date: 1.month.ago)

    results = Expense.for_month(Date.current)
    assert_includes results, this_month
    assert_not_includes results, last_month
  end

  test "ordered scope orders by date ascending" do
    user = create(:user)
    category = user.categories.first
    old = create(:expense, user: user, category: category, date: 3.days.ago)
    recent = create(:expense, user: user, category: category, date: Date.current)

    ordered = Expense.ordered.to_a
    assert_equal old, ordered.first
    assert_equal recent, ordered.last
  end

  test "fixed scope returns only fixed expenses" do
    user = create(:user)
    category = user.categories.first
    fixed = create(:expense, user: user, category: category, expense_type: "fixed")
    variable = create(:expense, user: user, category: category, expense_type: "variable")

    assert_includes Expense.fixed, fixed
    assert_not_includes Expense.fixed, variable
  end

  test "variable scope returns only variable expenses" do
    user = create(:user)
    category = user.categories.first
    fixed = create(:expense, user: user, category: category, expense_type: "fixed")
    variable = create(:expense, user: user, category: category, expense_type: "variable")

    assert_includes Expense.variable, variable
    assert_not_includes Expense.variable, fixed
  end

  test "recurring scope returns only recurring expenses" do
    user = create(:user)
    category = user.categories.first
    recurring = create(:expense, user: user, category: category, recurring: true, recurrence_day: 5)
    one_time = create(:expense, user: user, category: category, recurring: false)

    assert_includes Expense.recurring, recurring
    assert_not_includes Expense.recurring, one_time
  end

  # payment_method
  test "validates payment_method inclusion" do
    expense = build(:expense, payment_method: "wire_transfer")
    assert_not expense.valid?
  end

  test "accepts all valid payment methods" do
    %w[cash pix boleto credit_card].each do |method|
      expense = build(:expense, payment_method: method)
      assert expense.valid?, "Expected #{method} to be valid"
    end
  end

  # total_installments
  test "validates total_installments is in 1..60" do
    assert_not build(:expense, total_installments: 0).valid?
    assert_not build(:expense, total_installments: 61).valid?
    assert build(:expense, total_installments: 1).valid?
    assert build(:expense, total_installments: 60).valid?
  end

  # installment_number
  test "validates installment_number is in 1..60" do
    assert_not build(:expense, installment_number: 0).valid?
    assert_not build(:expense, installment_number: 61).valid?
    assert build(:expense, installment_number: 1).valid?
    assert build(:expense, installment_number: 60).valid?
  end

  # installment?
  test "installment? returns false when total_installments is 1" do
    assert_not build(:expense, total_installments: 1).installment?
  end

  test "installment? returns true when total_installments > 1" do
    assert build(:expense, total_installments: 3, installment_number: 2).installment?
  end

  # installment_label
  test "installment_label returns installment_number/total_installments" do
    expense = build(:expense, installment_number: 2, total_installments: 6)
    assert_equal "2/6", expense.installment_label
  end
end
