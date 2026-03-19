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

  test "validates recurrence_day is between 1 and 31" do
    assert_not build(:expense, recurrence_day: 0).valid?
    assert_not build(:expense, recurrence_day: 32).valid?
    assert build(:expense, recurrence_day: 29).valid?
    assert build(:expense, recurrence_day: 31).valid?
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
    recurring = create(:expense, user: user, category: category, expense_type: "fixed", recurring: true, recurrence_day: 5)
    one_time = create(:expense, user: user, category: category, recurring: false)

    assert_includes Expense.recurring, recurring
    assert_not_includes Expense.recurring, one_time
  end

  # recurring
  test "new fixed expense is automatically set to recurring" do
    expense = build(:expense, expense_type: "fixed", recurring: false)
    expense.valid?
    assert expense.recurring?
  end

  test "new variable expense is automatically set to non-recurring" do
    expense = build(:expense, expense_type: "variable", recurring: true)
    expense.valid?
    assert_not expense.recurring?
  end

  test "existing fixed expense can have recurring turned off" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed")
    assert expense.recurring?
    expense.update!(recurring: false)
    assert_not expense.reload.recurring?
  end

  test "fixed expense with recurrence_day is valid" do
    expense = build(:expense, expense_type: "fixed", recurrence_day: 5)
    assert expense.valid?
  end

  test "fixed expense cannot have installments" do
    expense = build(:expense, expense_type: "fixed", total_installments: 3, installment_number: 1)
    assert_not expense.valid?
    assert expense.errors[:total_installments].any?
  end

  test "variable expense can have installments" do
    expense = build(:expense, expense_type: "variable", total_installments: 3, installment_number: 1)
    assert expense.valid?
  end

  test "fixed expense with one installment is valid" do
    expense = build(:expense, expense_type: "fixed", total_installments: 1, installment_number: 1)
    assert expense.valid?
  end

  # payment_method default
  test "new expense defaults payment_method to credit_card" do
    user = create(:user)
    category = user.categories.first
    expense = user.expenses.build(amount: 10, date: Date.current, category: category, expense_type: "variable")
    assert_equal "credit_card", expense.payment_method
  end

  # payment_method
  test "validates payment_method inclusion" do
    expense = build(:expense, payment_method: "wire_transfer")
    assert_not expense.valid?
  end

  test "accepts all valid payment methods" do
    %w[cash pix boleto credit_card debito_automatico].each do |method|
      expense = build(:expense, payment_method: method)
      assert expense.valid?, "Expected #{method} to be valid"
    end
  end

  # credit_card_id is cleared for non-credit_card methods
  test "credit_card_id is cleared when payment method is not credit_card" do
    user = create(:user)
    category = user.categories.first
    credit_card = create(:credit_card, user: user)
    expense = create(:expense, user: user, category: category, payment_method: "pix", credit_card: credit_card)
    assert_nil expense.credit_card_id
  end

  test "credit_card_id is preserved when payment method is credit_card" do
    user = create(:user)
    category = user.categories.first
    credit_card = create(:credit_card, user: user)
    expense = create(:expense, user: user, category: category, payment_method: "credit_card", credit_card: credit_card)
    assert_equal credit_card.id, expense.credit_card_id
  end

  # automatic payment methods
  test "debito_automatico is valid for fixed expenses" do
    expense = build(:expense, expense_type: "fixed", payment_method: "debito_automatico")
    assert expense.valid?
  end

  test "debito_automatico is valid for variable expenses" do
    expense = build(:expense, expense_type: "variable", payment_method: "debito_automatico")
    assert expense.valid?
  end

  test "debito_automatico can be recurring" do
    expense = build(:expense, expense_type: "fixed", payment_method: "debito_automatico", recurring: true, recurrence_day: 5)
    assert expense.valid?
  end

  test "debito_automatico can have installments" do
    expense = build(:expense, expense_type: "variable", payment_method: "debito_automatico", total_installments: 6, installment_number: 1)
    assert expense.valid?
  end

  # scheduled_payment? for automatic methods
  test "scheduled_payment? returns true for debito_automatico" do
    expense = build(:expense, expense_type: "fixed", payment_method: "debito_automatico")
    assert expense.scheduled_payment?
  end

  # set_default_payment_status for automatic methods
  test "debito_automatico expense gets scheduled status by default" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed", payment_method: "debito_automatico")
    assert_equal "scheduled", expense.payment_status
  end

  # next_payment_status for automatic methods (two-state cycle)
  test "next_payment_status for debito_automatico: scheduled -> paid" do
    expense = build(:expense, expense_type: "fixed", payment_method: "debito_automatico", payment_status: "scheduled")
    assert_equal "paid", expense.next_payment_status
  end

  test "next_payment_status for debito_automatico: paid -> scheduled" do
    expense = build(:expense, expense_type: "fixed", payment_method: "debito_automatico", payment_status: "paid")
    assert_equal "scheduled", expense.next_payment_status
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

  # credit_card_installment?
  test "credit_card_installment? returns true for credit_card with total_installments > 1" do
    expense = build(:expense, payment_method: "credit_card", total_installments: 3, installment_number: 1)
    assert expense.credit_card_installment?
  end

  test "credit_card_installment? returns false for boleto installment" do
    expense = build(:expense, payment_method: "boleto", total_installments: 3, installment_number: 1)
    assert_not expense.credit_card_installment?
  end

  test "credit_card_installment? returns false for credit_card non-installment" do
    expense = build(:expense, payment_method: "credit_card", total_installments: 1)
    assert_not expense.credit_card_installment?
  end

  test "credit card installment gets nil payment_status by default" do
    user = create(:user)
    category = create(:category, user: user)
    expense = create(:expense, user: user, category: category,
                     payment_method: "credit_card", total_installments: 3, installment_number: 1,
                     expense_type: "variable", date: Date.current)
    assert_nil expense.payment_status
  end

  # installment_label
  test "installment_label returns installment_number/total_installments" do
    expense = build(:expense, installment_number: 2, total_installments: 6)
    assert_equal "2/6", expense.installment_label
  end

  # recurring_credit_card?
  test "recurring_credit_card? returns true for recurring credit card expense" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "credit_card")
    assert expense.recurring_credit_card?
  end

  test "recurring_credit_card? returns false for non-recurring credit card expense" do
    expense = build(:expense, recurring: false, payment_method: "credit_card")
    assert_not expense.recurring_credit_card?
  end

  test "recurring_credit_card? returns false for recurring boleto expense" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "boleto")
    assert_not expense.recurring_credit_card?
  end

  # scheduled_payment?
  test "scheduled_payment? returns true for recurring credit card" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "credit_card")
    assert expense.scheduled_payment?
  end

  test "scheduled_payment? returns true for recurring pix" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "pix")
    assert expense.scheduled_payment?
  end

  test "scheduled_payment? returns false for pix installment" do
    expense = build(:expense, payment_method: "pix", total_installments: 3, installment_number: 1)
    assert_not expense.scheduled_payment?
  end

  test "scheduled_payment? returns false for non-recurring non-installment pix" do
    expense = build(:expense, payment_method: "pix", recurring: false, total_installments: 1)
    assert_not expense.scheduled_payment?
  end

  test "scheduled_payment? returns false for recurring boleto" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "boleto")
    assert_not expense.scheduled_payment?
  end

  test "scheduled_payment? returns false for credit card installment" do
    expense = build(:expense, payment_method: "credit_card", total_installments: 3, installment_number: 1)
    assert_not expense.scheduled_payment?
  end

  # set_default_payment_status
  test "recurring credit card expense gets scheduled status by default" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed", recurring: true, payment_method: "credit_card")
    assert_equal "scheduled", expense.payment_status
  end

  test "recurring pix expense gets scheduled status by default" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed", recurring: true, payment_method: "pix")
    assert_equal "scheduled", expense.payment_status
  end

  test "pix installment expense gets pending status by default" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, payment_method: "pix", total_installments: 3, installment_number: 1)
    assert_equal "pending", expense.payment_status
  end

  test "fixed boleto expense gets pending status by default" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed", payment_method: "boleto")
    assert_equal "pending", expense.payment_status
  end

  test "fixed cash expense gets nil status by default" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed", payment_method: "cash")
    assert_nil expense.payment_status
  end

  test "explicit payment_status is not overridden on create" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed", recurring: true, payment_method: "credit_card", payment_status: "paid")
    assert_equal "paid", expense.payment_status
  end

  # next_payment_status for recurring credit card (two-state cycle)
  test "next_payment_status for recurring credit card: scheduled -> paid" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "credit_card", payment_status: "scheduled")
    assert_equal "paid", expense.next_payment_status
  end

  test "next_payment_status for recurring credit card: paid -> scheduled" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "credit_card", payment_status: "paid")
    assert_equal "scheduled", expense.next_payment_status
  end

  # next_payment_status for recurring pix (two-state cycle)
  test "next_payment_status for recurring pix: scheduled -> paid" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "pix", payment_status: "scheduled")
    assert_equal "paid", expense.next_payment_status
  end

  test "next_payment_status for recurring pix: paid -> scheduled" do
    expense = build(:expense, expense_type: "fixed", recurring: true, payment_method: "pix", payment_status: "paid")
    assert_equal "scheduled", expense.next_payment_status
  end

  # next_payment_status for pix installment (two-state cycle)
  test "next_payment_status for pix installment: scheduled -> paid" do
    expense = build(:expense, payment_method: "pix", total_installments: 3, installment_number: 1, payment_status: "scheduled")
    assert_equal "paid", expense.next_payment_status
  end

  test "next_payment_status for pix installment: paid -> pending" do
    expense = build(:expense, payment_method: "pix", total_installments: 3, installment_number: 1, payment_status: "paid")
    assert_equal "pending", expense.next_payment_status
  end

  # next_payment_status for boleto (three-state cycle)
  test "next_payment_status for boleto: pending -> scheduled" do
    expense = build(:expense, payment_method: "boleto", payment_status: "pending")
    assert_equal "scheduled", expense.next_payment_status
  end

  test "next_payment_status for boleto: scheduled -> paid" do
    expense = build(:expense, payment_method: "boleto", payment_status: "scheduled")
    assert_equal "paid", expense.next_payment_status
  end

  test "next_payment_status for boleto: paid -> pending" do
    expense = build(:expense, payment_method: "boleto", payment_status: "paid")
    assert_equal "pending", expense.next_payment_status
  end

  # scheduled_payment? for bank-debit installments
  test "scheduled_payment? returns false for boleto installment" do
    expense = build(:expense, payment_method: "boleto", total_installments: 3, installment_number: 1)
    assert_not expense.scheduled_payment?
  end

  test "scheduled_payment? returns true for debito_automatico installment" do
    expense = build(:expense, payment_method: "debito_automatico", total_installments: 3, installment_number: 1)
    assert expense.scheduled_payment?
  end

  test "scheduled_payment? returns false for standalone boleto (non-installment, non-recurring)" do
    expense = build(:expense, payment_method: "boleto", total_installments: 1, recurring: false)
    assert_not expense.scheduled_payment?
  end

  test "boleto installment gets pending status by default" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, payment_method: "boleto",
                     total_installments: 3, installment_number: 1)
    assert_equal "pending", expense.payment_status
  end

  test "boleto installment cycles scheduled -> paid" do
    expense = build(:expense, payment_method: "boleto", total_installments: 3, installment_number: 1,
                    payment_status: "scheduled")
    assert_equal "paid", expense.next_payment_status
  end

  test "boleto installment cycles paid -> pending" do
    expense = build(:expense, payment_method: "boleto", total_installments: 3, installment_number: 1,
                    payment_status: "paid")
    assert_equal "pending", expense.next_payment_status
  end

  # Bank account auto-debit tests
  test "bank_account_id is cleared when payment method is not in BANK_DEBIT_METHODS" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 500.00)
    expense = create(:expense, user: user, category: category, payment_method: "pix", bank_account: bank_account)
    expense.update!(payment_method: "credit_card")
    assert_nil expense.reload.bank_account_id
  end

  test "bank_account_id is preserved when payment method is pix" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 500.00)
    expense = create(:expense, user: user, category: category)
    expense.update!(payment_method: "pix", bank_account: bank_account)
    assert_equal bank_account.id, expense.reload.bank_account_id
  end

  test "bank_account_id is preserved when payment method is boleto" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 500.00)
    expense = create(:expense, user: user, category: category)
    expense.update!(payment_method: "boleto", bank_account: bank_account)
    assert_equal bank_account.id, expense.reload.bank_account_id
  end

  test "bank_account_id is preserved when payment method is debito_automatico" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 500.00)
    expense = create(:expense, user: user, category: category)
    expense.update!(payment_method: "debito_automatico", bank_account: bank_account)
    assert_equal bank_account.id, expense.reload.bank_account_id
  end

  test "marking expense as paid decrements bank account balance" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = create(:expense, user: user, category: category, amount: 100.00, payment_method: "pix", bank_account: bank_account, payment_status: "pending")
    expense.update!(payment_status: "paid")
    assert_in_delta 900.00, bank_account.reload.balance, 0.01
  end

  test "toggling expense back from paid increments bank account balance" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = create(:expense, user: user, category: category, amount: 100.00, payment_method: "pix", bank_account: bank_account, payment_status: "pending")
    expense.update!(payment_status: "paid")
    expense.update!(payment_status: "pending")
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  test "destroying a paid expense with bank account restores the balance" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = create(:expense, user: user, category: category, amount: 100.00, payment_method: "pix", bank_account: bank_account, payment_status: "pending")
    expense.update!(payment_status: "paid")
    # balance is now 900 after marking paid
    expense.destroy
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  test "destroying a non-paid expense does not change bank account balance" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = create(:expense, user: user, category: category, amount: 100.00, payment_method: "pix", bank_account: bank_account, payment_status: "pending")
    expense.destroy
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  # Variable expense defaults and bank account sync on create

  test "variable expense with pix defaults to paid on create" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = create(:expense, user: user, category: category, expense_type: "variable", payment_method: "pix", bank_account: bank_account, date: Date.current)
    assert_equal "paid", expense.payment_status
  end

  test "variable expense with cash defaults to paid on create" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "variable", payment_method: "cash", date: Date.current)
    assert_equal "paid", expense.payment_status
  end

  test "variable expense with pix decrements bank account balance on create" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    create(:expense, user: user, category: category, expense_type: "variable", payment_method: "pix", bank_account: bank_account, amount: 150.00, date: Date.current)
    assert_in_delta 850.00, bank_account.reload.balance, 0.01
  end

  test "variable expense with boleto decrements bank account balance on create" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    create(:expense, user: user, category: category, expense_type: "variable", payment_method: "boleto", bank_account: bank_account, amount: 200.00, date: Date.current)
    assert_in_delta 800.00, bank_account.reload.balance, 0.01
  end

  test "variable expense with debito_automatico gets scheduled status (debito_automatico always scheduled)" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = create(:expense, user: user, category: category, expense_type: "variable", payment_method: "debito_automatico", bank_account: bank_account, amount: 75.00, date: Date.current)
    assert_equal "scheduled", expense.payment_status
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  test "variable expense with cash does not change bank account balance on create" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    create(:expense, user: user, category: category, expense_type: "variable", payment_method: "cash", amount: 50.00, date: Date.current)
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  test "variable expense with past date and pix decrements bank account balance on create" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    create(:expense, user: user, category: category, expense_type: "variable", payment_method: "pix", bank_account: bank_account, amount: 100.00, date: Date.current - 5.days)
    assert_in_delta 900.00, bank_account.reload.balance, 0.01
  end

  test "destroying variable pix expense restores bank account balance" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = create(:expense, user: user, category: category, expense_type: "variable", payment_method: "pix", bank_account: bank_account, amount: 100.00, date: Date.current)
    # balance is now 900 after create
    expense.destroy
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  test "variable expense with future date is invalid" do
    user = create(:user)
    category = user.categories.first
    bank_account = create(:bank_account, user: user, balance: 1000.00)
    expense = build(:expense, user: user, category: category, expense_type: "variable", payment_method: "pix", bank_account: bank_account, date: Date.current + 1.day)
    assert_not expense.valid?
    assert expense.errors[:date].any?
  end

  test "variable expense with cash and future date is invalid" do
    user = create(:user)
    category = user.categories.first
    expense = build(:expense, user: user, category: category, expense_type: "variable", payment_method: "cash", date: Date.current + 1.day)
    assert_not expense.valid?
    assert expense.errors[:date].any?
  end

  test "fixed boleto expense still defaults to pending" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "fixed", payment_method: "boleto", date: Date.current)
    assert_equal "pending", expense.payment_status
  end

  test "fixed expense with future date is valid" do
    user = create(:user)
    category = user.categories.first
    expense = build(:expense, user: user, category: category, expense_type: "fixed", payment_method: "cash", date: Date.current + 30.days)
    assert expense.valid?
  end

  test "variable installment expense with future date is valid (installments span multiple months)" do
    user = create(:user)
    category = user.categories.first
    expense = build(:expense, user: user, category: category, expense_type: "variable", payment_method: "boleto",
                    total_installments: 3, installment_number: 2, date: Date.current + 1.month)
    assert expense.valid?
  end

  test "variable non-installment expense with future date is still invalid" do
    user = create(:user)
    category = user.categories.first
    expense = build(:expense, user: user, category: category, expense_type: "variable", payment_method: "boleto",
                    total_installments: 1, installment_number: 1, date: Date.current + 1.day)
    assert_not expense.valid?
    assert expense.errors[:date].any?
  end

  # auto_paid_boleto_or_pix?
  test "auto_paid_boleto_or_pix? returns true for non-recurring non-installment variable boleto" do
    expense = build(:expense, expense_type: "variable", payment_method: "boleto", recurring: false, total_installments: 1)
    assert expense.auto_paid_boleto_or_pix?
  end

  test "auto_paid_boleto_or_pix? returns true for non-recurring non-installment variable pix" do
    expense = build(:expense, expense_type: "variable", payment_method: "pix", recurring: false, total_installments: 1)
    assert expense.auto_paid_boleto_or_pix?
  end

  test "auto_paid_boleto_or_pix? returns false for boleto installment" do
    expense = build(:expense, expense_type: "variable", payment_method: "boleto", total_installments: 3, installment_number: 1)
    assert_not expense.auto_paid_boleto_or_pix?
  end

  test "auto_paid_boleto_or_pix? returns false for pix installment" do
    expense = build(:expense, expense_type: "variable", payment_method: "pix", total_installments: 3, installment_number: 1)
    assert_not expense.auto_paid_boleto_or_pix?
  end

  test "auto_paid_boleto_or_pix? returns false for fixed boleto" do
    expense = build(:expense, expense_type: "fixed", payment_method: "boleto", recurring: true)
    assert_not expense.auto_paid_boleto_or_pix?
  end

  test "auto_paid_boleto_or_pix? returns false for variable cash" do
    expense = build(:expense, expense_type: "variable", payment_method: "cash", recurring: false, total_installments: 1)
    assert_not expense.auto_paid_boleto_or_pix?
  end

  test "non-recurring non-installment variable boleto is auto-set to paid on create" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "variable",
                     payment_method: "boleto", total_installments: 1, date: Date.current)
    assert_equal "paid", expense.payment_status
  end

  test "non-recurring non-installment variable pix is auto-set to paid on create" do
    user = create(:user)
    category = user.categories.first
    expense = create(:expense, user: user, category: category, expense_type: "variable",
                     payment_method: "pix", total_installments: 1, date: Date.current)
    assert_equal "paid", expense.payment_status
  end
end
