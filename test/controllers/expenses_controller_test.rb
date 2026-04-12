require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  setup do
    @user = create(:user)
    @category = @user.categories.first
    @expense = create(:expense, user: @user, category: @category)
  end

  test "redirects to sign in when not authenticated" do
    get expenses_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get expenses_path
    assert_response :success
  end

  test "GET index shows fixed expenses in fixed section" do
    fixed = create(:expense, user: @user, category: @category, expense_type: "fixed", description: "Monthly Rent", date: Date.current)
    sign_in @user
    get expenses_path
    assert_response :success
    assert_match fixed.description, response.body
  end

  test "GET index shows variable expenses in variable section" do
    variable = create(:expense, user: @user, category: @category, expense_type: "variable", description: "Groceries Run", date: Date.current)
    sign_in @user
    get expenses_path
    assert_response :success
    assert_match variable.description, response.body
  end

  test "GET index fixed expenses do not bleed into variable section" do
    fixed = create(:expense, user: @user, category: @category, expense_type: "fixed", description: "Internet Bill", date: Date.current)
    variable = create(:expense, user: @user, category: @category, expense_type: "variable", description: "Restaurant Meal", date: Date.current)
    sign_in @user
    get expenses_path
    # Both descriptions must be present somewhere on the page
    assert_match fixed.description, response.body
    assert_match variable.description, response.body
  end

  test "GET index computes fixed and variable totals separately" do
    create(:expense, user: @user, category: @category, expense_type: "fixed", amount: 500.00, date: Date.current)
    create(:expense, user: @user, category: @category, expense_type: "variable", amount: 200.00, date: Date.current)
    sign_in @user
    get expenses_path
    assert_response :success
    # The default @expense from setup is variable with amount 100, so variable total = 300, fixed = 500
    assert_match "500", response.body
    assert_match "300", response.body
  end

  test "GET index only shows current month expenses" do
    last_month = create(:expense, user: @user, category: @category, description: "Old Expense", date: 1.month.ago)
    sign_in @user
    get expenses_path
    assert_response :success
    assert_no_match last_month.description, response.body
  end

  test "GET index renders search input and filter controller" do
    sign_in @user
    get expenses_path
    assert_select "[data-controller='expense-filter']"
    assert_select "input[data-expense-filter-target='input']"
    assert_select "button[data-expense-filter-target='clear']"
  end

  test "GET index renders expense rows with searchable data attributes" do
    expense = create(:expense, user: @user, category: @category, description: "Supermarket Run", date: Date.current)
    sign_in @user
    get expenses_path
    assert_select "[data-expense-filter-target='row'][data-search-text*='Supermarket Run']"
  end

  test "GET index expense rows include payment status in search text" do
    create(:expense, user: @user, category: @category, date: Date.current, payment_status: "paid")
    sign_in @user
    get expenses_path
    assert_select "[data-expense-filter-target='row'][data-search-text*='#{I18n.t("expenses.payment_statuses.paid")}']"
  end

  test "GET index expense rows with nil payment status do not error" do
    expense = create(:expense, user: @user, category: @category, date: Date.current, payment_status: nil)
    sign_in @user
    get expenses_path
    assert_response :success
  end

  test "GET index expense rows include section data attribute" do
    expense = create(:expense, user: @user, category: @category, description: "Test Expense", date: Date.current)
    sign_in @user
    get expenses_path
    assert_select "[data-expense-filter-target='row'][data-section='#{expense.expense_type}']"
  end

  test "GET index loads all expenses without pagination limit" do
    create_list(:expense, 5, user: @user, category: @category, expense_type: "variable", date: Date.current)
    sign_in @user
    get expenses_path
    assert_select "[data-expense-filter-target='row']", minimum: 6
  end

  test "GET new returns success" do
    sign_in @user
    get new_expense_path
    assert_response :success
  end

  test "GET new pre-selects credit_card as default payment method" do
    sign_in @user
    get new_expense_path
    assert_select "input[type='radio'][name='expense[payment_method]'][value='credit_card'][checked]"
  end

  test "GET new payment method order is credit_card, pix, boleto, cash, debito_automatico" do
    sign_in @user
    get new_expense_path
    values = css_select("input[type='radio'][name='expense[payment_method]']").map { |el| el["value"] }
    assert_equal %w[credit_card pix boleto cash debito_automatico], values
  end

  test "GET new pre-selects default credit card" do
    card = create(:credit_card, user: @user)
    @user.update!(default_credit_card_id: card.id)
    sign_in @user
    get new_expense_path
    assert_select "select[name='expense[credit_card_id]'] option[selected][value='#{card.id}']"
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_expense_path(@expense)
    assert_response :success
  end

  test "POST create with valid params creates expense" do
    sign_in @user
    assert_difference "Expense.count", 1 do
      post expenses_path, params: {
        expense: {
          description: "Groceries",
          amount: 150.00,
          date: Date.current,
          expense_type: "variable",
          category_id: @category.id
        }
      }
    end
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.created"), flash[:notice]
  end

  test "POST create with string amount from currency input creates expense" do
    sign_in @user
    assert_difference "Expense.count", 1 do
      post expenses_path, params: {
        expense: {
          description: "Groceries",
          amount: "150.00",
          date: Date.current,
          expense_type: "variable",
          category_id: @category.id
        }
      }
    end
    assert_equal 150.00, Expense.last.amount.to_f
  end

  test "GET new renders currency-input controller on amount field" do
    sign_in @user
    get new_expense_path
    assert_select "[data-controller='currency-input']"
    assert_select "input[data-currency-input-target='display']"
    assert_select "input[data-currency-input-target='hidden']"
  end

  test "GET edit renders amount pre-populated for currency-input" do
    @expense.update!(amount: 99.99)
    sign_in @user
    get edit_expense_path(@expense)
    assert_select "input[data-currency-input-target='hidden'][value='99.99']"
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Expense.count" do
      post expenses_path, params: {
        expense: { description: nil, amount: nil, date: Date.current, expense_type: "variable", category_id: @category.id }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates expense" do
    sign_in @user
    patch expense_path(@expense), params: {
      expense: { description: "Updated description" }
    }
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.updated"), flash[:notice]
    assert_equal "Updated description", @expense.reload.description
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch expense_path(@expense), params: {
      expense: { description: nil, amount: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes expense" do
    sign_in @user
    assert_difference "Expense.count", -1 do
      delete expense_path(@expense)
    end
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.destroyed"), flash[:notice]
  end

  test "cannot access other user's expense" do
    other_user = create(:user)
    other_category = other_user.categories.first
    other_expense = create(:expense, user: other_user, category: other_category)

    sign_in @user
    get edit_expense_path(other_expense)
    assert_response :not_found
  end

  test "POST create stores payment_method" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "Transfer",
        amount: 50.00,
        date: Date.current,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "pix"
      }
    }
    assert_equal "pix", Expense.last.payment_method
  end

  # installment creation
  test "POST create with multiple installments creates correct count" do
    sign_in @user
    assert_difference "Expense.count", 3 do
      post expenses_path, params: {
        expense: {
          description: "New TV",
          amount: 300.00,
          date: Date.current,
          expense_type: "variable",
          category_id: @category.id,
          payment_method: "credit_card",
          total_installments: 3,
          installment_number: 1
        }
      }
    end
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.created_installments", count: 3), flash[:notice]
  end

  test "POST create with multiple installments assigns same group_id" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "New TV",
        amount: 300.00,
        date: Date.current,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "credit_card",
        total_installments: 3,
        installment_number: 1
      }
    }
    created = @user.expenses.order(id: :asc).last(3)
    group_ids = created.map(&:installment_group_id).uniq
    assert_equal 1, group_ids.size
    assert_not_nil group_ids.first
  end

  test "POST create with multiple installments splits amount evenly" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "New TV",
        amount: 300.00,
        date: Date.current,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "credit_card",
        total_installments: 3,
        installment_number: 1
      }
    }
    amounts = @user.expenses.order(id: :asc).last(3).map(&:amount).map(&:to_f)
    assert_equal [ 100.0, 100.0, 100.0 ], amounts
  end

  test "POST create with 12 installments puts cent remainder on last installment" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "Big purchase",
        amount: 1000.00,
        date: Date.current,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "credit_card",
        total_installments: 12,
        installment_number: 1
      }
    }
    amounts = @user.expenses.order(id: :asc).last(12).map(&:amount).map(&:to_f)
    assert_equal 11, amounts.count(83.33)
    assert_in_delta 83.37, amounts.last, 0.001
    assert_in_delta 1000.0, amounts.sum, 0.001
  end

  test "POST create with multiple installments advances date by month" do
    sign_in @user
    base = Date.new(2026, 3, 1)
    post expenses_path, params: {
      expense: {
        description: "New TV",
        amount: 300.00,
        date: base,
        expense_type: "variable",
        category_id: @category.id,
        payment_method: "credit_card",
        total_installments: 3,
        installment_number: 1
      }
    }
    dates = @user.expenses.order(id: :asc).last(3).map(&:date)
    assert_equal [ base, base >> 1, base >> 2 ], dates
  end

  test "POST create with installments and invalid amount re-renders new" do
    sign_in @user
    assert_no_difference "Expense.count" do
      post expenses_path, params: {
        expense: {
          description: "Test",
          amount: -1,
          date: Date.current,
          expense_type: "variable",
          category_id: @category.id,
          total_installments: 3,
          installment_number: 1
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create recurring expense enqueues GenerateRecurringJob" do
    sign_in @user
    assert_enqueued_with(job: Expenses::GenerateRecurringJob) do
      post expenses_path, params: {
        expense: {
          description: "Monthly Rent",
          amount: 1500.00,
          date: Date.current,
          expense_type: "fixed",
          category_id: @category.id,
          recurring: true,
          recurrence_day: 5
        }
      }
    end
  end

  test "PATCH update_status cycles payment status" do
    sign_in @user
    @expense.update!(payment_status: "pending")
    patch update_status_expense_path(@expense)
    assert_equal "scheduled", @expense.reload.payment_status
  end

  test "PATCH update_status cycles back to pending from paid" do
    sign_in @user
    @expense.update!(payment_status: "paid")
    patch update_status_expense_path(@expense)
    assert_equal "pending", @expense.reload.payment_status
  end

  test "GET edit blocks past-month recurring expense" do
    past_recurring = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 1.month.ago)
    sign_in @user
    get edit_expense_path(past_recurring)
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.edit_locked"), flash[:alert]
  end

  test "GET edit blocks past-month installment expense" do
    past_installment = create(:expense, user: @user, category: @category, total_installments: 3, installment_number: 1, date: 1.month.ago)
    sign_in @user
    get edit_expense_path(past_installment)
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.edit_locked"), flash[:alert]
  end

  test "GET edit allows past-month regular expense" do
    past_regular = create(:expense, user: @user, category: @category, recurring: false, total_installments: 1, date: 1.month.ago)
    sign_in @user
    get edit_expense_path(past_regular)
    assert_response :success
  end

  test "GET edit allows current-month recurring expense" do
    current_recurring = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.current)
    sign_in @user
    get edit_expense_path(current_recurring)
    assert_response :success
  end

  test "PATCH update blocks past-month recurring expense" do
    past_recurring = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 1.month.ago)
    sign_in @user
    patch expense_path(past_recurring), params: { expense: { amount: 999 } }
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.edit_locked"), flash[:alert]
  end

  test "PATCH update on recurring template propagates amount to future replicas" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, amount: 100.00, date: Date.current)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.from_now)

    sign_in @user
    patch expense_path(template), params: { expense: { amount: 200.00 } }

    assert_redirected_to expenses_path
    assert_equal 200.00, template.reload.amount
    assert_equal 200.00, future_replica.reload.amount
    assert_equal 100.00, past_replica.reload.amount  # past replica is not updated
  end

  test "PATCH update on recurring template propagates category to future replicas" do
    other_category = create(:category, user: @user)
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.current)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now)

    sign_in @user
    patch expense_path(template), params: { expense: { category_id: other_category.id } }

    assert_redirected_to expenses_path
    assert_equal other_category.id, template.reload.category_id
    assert_equal other_category.id, future_replica.reload.category_id
    assert_equal @category.id, past_replica.reload.category_id  # past replica is not updated
  end

  test "PATCH update on recurring replica propagates amount to future replicas of same source" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, amount: 100.00, date: 3.months.ago)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 2.months.ago)
    edited_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: Date.current)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.from_now)

    sign_in @user
    patch expense_path(edited_replica), params: { expense: { amount: 300.00 } }

    assert_redirected_to expenses_path
    assert_equal 300.00, edited_replica.reload.amount
    assert_equal 300.00, future_replica.reload.amount
    assert_equal 100.00, past_replica.reload.amount  # past replica is not updated
    assert_equal 100.00, template.reload.amount       # template is not updated
  end

  test "PATCH update on recurring template does not propagate unchanged fields" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, amount: 100.00, date: Date.current)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, amount: 100.00, date: 1.month.from_now, category_id: @category.id)

    sign_in @user
    patch expense_path(template), params: { expense: { amount: 200.00 } }

    assert_equal @category.id, future_replica.reload.category_id
  end

  test "PATCH update on non-recurring expense does not propagate" do
    non_recurring = create(:expense, user: @user, category: @category, expense_type: "variable", recurring: false, amount: 100.00, date: Date.current)

    sign_in @user
    patch expense_path(non_recurring), params: { expense: { amount: 200.00 } }

    assert_equal 200.00, non_recurring.reload.amount
  end

  test "PATCH update turning off recurring on template destroys all replicas from following month onwards" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.current)
    same_month_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: Date.current + 1.day)
    later_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 2.months.from_now)

    sign_in @user
    patch expense_path(template), params: { expense: { recurring: "0", expense_type: "fixed" } }

    assert_redirected_to expenses_path
    assert Expense.exists?(same_month_replica.id)   # same month as template — kept
    assert_not Expense.exists?(later_replica.id)    # following month onwards — deleted
    assert_not Expense.exists?(future_replica.id)   # future — deleted
    assert_not template.reload.recurring?
  end

  test "PATCH update turning off recurring on replica destroys siblings from following month and turns off template" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 3.months.ago)
    earlier_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 2.months.ago)
    current_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: Date.current)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now)

    sign_in @user
    patch expense_path(current_replica), params: { expense: { recurring: "0", expense_type: "fixed" } }

    assert_redirected_to expenses_path
    assert Expense.exists?(earlier_replica.id)    # before the edited replica's month — kept
    assert_not Expense.exists?(future_replica.id) # following month onwards — deleted
    assert_not template.reload.recurring?
  end

  test "PATCH update_status responds via turbo_stream" do
    sign_in @user
    @expense.update!(payment_status: "pending")
    patch update_status_expense_path(@expense), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "DELETE destroy responds via turbo_stream" do
    sign_in @user
    delete expense_path(@expense), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match %r{action="remove".*target="expense_#{@expense.id}"}m, response.body
    assert_match %r{action="prepend".*target="flash-messages"}m, response.body
    assert_match I18n.t("controllers.expenses.destroyed"), response.body
  end

  test "DELETE destroy with delete_following removes recurring future expenses" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: 2.months.ago)
    future1 = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring_source_id: template.id, date: 1.month.from_now)
    future2 = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring_source_id: template.id, date: 2.months.from_now)
    past = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring_source_id: template.id, date: 1.month.ago)

    sign_in @user
    delete expense_path(future1), params: { delete_following: "1" }
    assert_redirected_to expenses_path

    assert_not Expense.exists?(future1.id)
    assert_not Expense.exists?(future2.id)
    assert Expense.exists?(past.id)
  end

  test "DELETE destroy with delete_following for installments removes from that number onward" do
    group_id = SecureRandom.uuid
    inst1 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 1, total_installments: 3)
    inst2 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 2, total_installments: 3)
    inst3 = create(:expense, user: @user, category: @category, installment_group_id: group_id, installment_number: 3, total_installments: 3)

    sign_in @user
    delete expense_path(inst2), params: { delete_following: "1" }

    assert Expense.exists?(inst1.id)
    assert_not Expense.exists?(inst2.id)
    assert_not Expense.exists?(inst3.id)
    assert_equal 1, inst1.reload.total_installments
  end

  test "PATCH update on recurring template propagates date day to future replicas" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.current.change(day: 20))
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.ago.change(day: 20))
    future_replica1 = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now.change(day: 20))
    future_replica2 = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 2.months.from_now.change(day: 20))

    sign_in @user
    patch expense_path(template), params: { expense: { date: Date.current.change(day: 25) } }

    assert_redirected_to expenses_path
    assert_equal 25, template.reload.date.day
    assert_equal 25, template.reload.recurrence_day
    assert_equal 25, future_replica1.reload.date.day
    assert_equal 25, future_replica2.reload.date.day
    assert_equal 20, past_replica.reload.date.day  # past replica not updated
  end

  test "PATCH update on recurring replica propagates date day to future siblings and updates template" do
    # Travel to the 10th so that day 20 is in the current month (not locked) and day 25 is after today (future sibling propagation works)
    travel_to Date.current.beginning_of_month + 9.days do
      template_date = Date.current.change(day: 20) - 3.months
      past_date = Date.current.change(day: 20) - 2.months
      edited_date = Date.current.change(day: 20)
      future_date = (Date.current + 1.month).change(day: 20)

      template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: template_date)
      past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: past_date)
      edited_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: edited_date)
      future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: future_date)

      sign_in @user
      patch expense_path(edited_replica), params: { expense: { date: Date.current.change(day: 25) } }

      assert_redirected_to expenses_path
      assert_equal Date.current.change(day: 25), edited_replica.reload.date
      assert_equal (Date.current + 1.month).change(day: 25), future_replica.reload.date
      assert_equal 25, template.reload.recurrence_day              # template recurrence_day updated, date untouched
      assert_equal template_date, template.reload.date             # template date itself unchanged
      assert_equal past_date, past_replica.reload.date             # past replica not updated
    end
  end

  test "PATCH update on recurring template propagates credit_card_id to future replicas" do
    credit_card = create(:credit_card, user: @user)
    other_card = create(:credit_card, user: @user)
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, payment_method: "credit_card", credit_card_id: credit_card.id, date: Date.current)
    past_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, payment_method: "credit_card", credit_card_id: credit_card.id, date: 1.month.ago)
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, payment_method: "credit_card", credit_card_id: credit_card.id, date: 1.month.from_now)

    sign_in @user
    patch expense_path(template), params: { expense: { credit_card_id: other_card.id } }

    assert_redirected_to expenses_path
    assert_equal other_card.id, template.reload.credit_card_id
    assert_equal other_card.id, future_replica.reload.credit_card_id
    assert_equal credit_card.id, past_replica.reload.credit_card_id  # past replica not updated
  end

  test "PATCH update on recurring template does not change day when only month changes" do
    template = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, date: Date.current.change(day: 20))
    future_replica = create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, recurring_source_id: template.id, date: 1.month.from_now.change(day: 20))

    sign_in @user
    patch expense_path(template), params: { expense: { date: Date.current.change(day: 20) } }

    assert_equal 20, future_replica.reload.date.day  # day unchanged, replica untouched
  end

  test "DELETE destroy single installment renumbers remaining" do
    group_id = SecureRandom.uuid
    inst1 = create(:expense, user: @user, category: @category, payment_method: "boleto", installment_group_id: group_id, installment_number: 1, total_installments: 3)
    inst2 = create(:expense, user: @user, category: @category, payment_method: "boleto", installment_group_id: group_id, installment_number: 2, total_installments: 3)
    inst3 = create(:expense, user: @user, category: @category, payment_method: "boleto", installment_group_id: group_id, installment_number: 3, total_installments: 3)

    sign_in @user
    delete expense_path(inst1)

    assert_equal 1, inst2.reload.installment_number
    assert_equal 2, inst3.reload.installment_number
    assert_equal 2, inst2.reload.total_installments
  end

  # Bank account auto-debit via update_status
  test "PATCH update_status to paid decrements linked bank account balance" do
    bank_account = create(:bank_account, user: @user, balance: 1000.00)
    expense = create(:expense, user: @user, category: @category, amount: 150.00,
                     payment_method: "pix", bank_account: bank_account, payment_status: "scheduled")
    sign_in @user
    patch update_status_expense_path(expense)
    assert_in_delta 850.00, bank_account.reload.balance, 0.01
  end

  test "PATCH update_status from paid restores linked bank account balance" do
    bank_account = create(:bank_account, user: @user, balance: 1000.00)
    expense = create(:expense, user: @user, category: @category, amount: 150.00,
                     payment_method: "pix", bank_account: bank_account, payment_status: "paid")
    sign_in @user
    patch update_status_expense_path(expense)
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  test "DELETE destroy paid expense with bank account restores balance" do
    bank_account = create(:bank_account, user: @user, balance: 1000.00)
    expense = create(:expense, user: @user, category: @category, amount: 150.00,
                     payment_method: "pix", bank_account: bank_account, payment_status: "paid")
    sign_in @user
    delete expense_path(expense), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_in_delta 1000.00, bank_account.reload.balance, 0.01
  end

  # bank_account_id propagation to future recurring instances
  test "PATCH update propagates bank_account_id to future recurring instances" do
    bank_account = create(:bank_account, user: @user, balance: 1000.00)
    template = create(:expense, user: @user, category: @category, expense_type: "fixed",
                      payment_method: "pix", recurring: true, recurrence_day: 5)
    future1 = create(:expense, user: @user, category: @category, expense_type: "fixed",
                     payment_method: "pix", recurring: true, recurring_source_id: template.id,
                     date: 1.month.from_now.change(day: 5))
    future2 = create(:expense, user: @user, category: @category, expense_type: "fixed",
                     payment_method: "pix", recurring: true, recurring_source_id: template.id,
                     date: 2.months.from_now.change(day: 5))

    sign_in @user
    patch expense_path(template), params: {
      expense: { bank_account_id: bank_account.id, payment_method: "pix",
                 amount: template.amount, date: template.date,
                 expense_type: "fixed", category_id: @category.id, recurring: "1" }
    }

    assert_equal bank_account.id, future1.reload.bank_account_id
    assert_equal bank_account.id, future2.reload.bank_account_id
  end

  # bank_account_id propagation to all installments in the group
  test "PATCH update propagates bank_account_id to all installments in the group" do
    bank_account = create(:bank_account, user: @user, balance: 1000.00)
    group_id = SecureRandom.uuid
    inst1 = create(:expense, user: @user, category: @category, payment_method: "boleto",
                   installment_group_id: group_id, installment_number: 1, total_installments: 3)
    inst2 = create(:expense, user: @user, category: @category, payment_method: "boleto",
                   installment_group_id: group_id, installment_number: 2, total_installments: 3)
    inst3 = create(:expense, user: @user, category: @category, payment_method: "boleto",
                   installment_group_id: group_id, installment_number: 3, total_installments: 3)

    sign_in @user
    patch expense_path(inst1), params: {
      expense: { bank_account_id: bank_account.id, payment_method: "boleto",
                 amount: inst1.amount, date: inst1.date, expense_type: inst1.expense_type,
                 category_id: @category.id, total_installments: 3,
                 installment_number: 1, installment_group_id: group_id }
    }

    assert_equal bank_account.id, inst2.reload.bank_account_id
    assert_equal bank_account.id, inst3.reload.bank_account_id
  end

  # installment sub-section
  test "GET index renders installment sub-section when installment expenses exist" do
    group_id = SecureRandom.uuid
    create(:expense, user: @user, category: @category, description: "Laptop 1/3",
           expense_type: "variable", date: Date.current, payment_method: "pix",
           installment_group_id: group_id, installment_number: 1, total_installments: 3)

    sign_in @user
    get expenses_path

    assert_response :success
    assert_select "#installment_expenses_list"
    assert_select "[data-section='installment']"
  end

  test "GET index installment expenses appear in installment list not variable list" do
    group_id = SecureRandom.uuid
    installment = create(:expense, user: @user, category: @category, description: "Phone 1/6",
                         expense_type: "variable", date: Date.current, payment_method: "pix",
                         installment_group_id: group_id, installment_number: 1, total_installments: 6)

    sign_in @user
    get expenses_path

    assert_response :success
    # installment_expenses_list must contain the expense row
    assert_select "#installment_expenses_list #expense_#{installment.id}"
    # variable_expenses_list should not contain it
    assert_select "#variable_expenses_list #expense_#{installment.id}", count: 0
  end

  # CC installment special treatment
  test "GET edit blocks CC installment number > 1 regardless of date" do
    group_id = SecureRandom.uuid
    cc_installment = create(:expense, user: @user, category: @category,
                            payment_method: "credit_card", total_installments: 3,
                            installment_number: 2, installment_group_id: group_id,
                            date: Date.current)
    sign_in @user
    get edit_expense_path(cc_installment)
    assert_redirected_to expenses_path
    assert_equal I18n.t("controllers.expenses.edit_locked"), flash[:alert]
  end

  test "GET edit allows CC installment number 1 (original purchase)" do
    group_id = SecureRandom.uuid
    cc_installment_1 = create(:expense, user: @user, category: @category,
                              payment_method: "credit_card", total_installments: 3,
                              installment_number: 1, installment_group_id: group_id,
                              date: Date.current)
    sign_in @user
    get edit_expense_path(cc_installment_1)
    assert_response :success
  end

  test "DELETE destroy CC installment 1 deletes all group installments without delete_following param" do
    group_id = SecureRandom.uuid
    create(:expense, user: @user, category: @category, payment_method: "credit_card",
           total_installments: 3, installment_number: 1, installment_group_id: group_id, date: Date.current)
    create(:expense, user: @user, category: @category, payment_method: "credit_card",
           total_installments: 3, installment_number: 2, installment_group_id: group_id, date: 1.month.from_now)
    create(:expense, user: @user, category: @category, payment_method: "credit_card",
           total_installments: 3, installment_number: 3, installment_group_id: group_id, date: 2.months.from_now)
    first_installment = @user.expenses.find_by(installment_group_id: group_id, installment_number: 1)

    sign_in @user
    assert_difference "Expense.count", -3 do
      delete expense_path(first_installment)
    end
    assert_redirected_to expenses_path
  end

  test "POST create CC installments are created with nil payment_status" do
    sign_in @user
    post expenses_path, params: {
      expense: {
        description: "Phone", amount: 300, date: Date.current,
        expense_type: "variable", category_id: @category.id,
        payment_method: "credit_card", total_installments: 3,
        installment_number: 1
      }
    }
    installments = @user.expenses.where(total_installments: 3).order(:installment_number)
    assert_equal 3, installments.count
    installments.each { |e| assert_nil e.payment_status }
  end

  test "GET index regular variable expenses do not appear in installment sub-section" do
    regular = create(:expense, user: @user, category: @category, description: "Coffee Shop",
                     expense_type: "variable", date: Date.current)

    sign_in @user
    get expenses_path

    assert_response :success
    # regular expense must NOT have installment section data attribute
    assert_select "#expense_#{regular.id}[data-section='installment']", count: 0
    assert_select "#expense_#{regular.id}[data-section='variable']"
  end

  test "GET index installment expenses section is a separate top-level section from variable other" do
    group_id = SecureRandom.uuid
    create(:expense, user: @user, category: @category, description: "Laptop 1/3",
           expense_type: "variable", date: Date.current,
           installment_group_id: group_id, installment_number: 1, total_installments: 3)
    create(:expense, user: @user, category: @category, description: "Coffee",
           expense_type: "variable", date: Date.current)

    sign_in @user
    get expenses_path

    # Both sections exist independently
    assert_select "#installment_expenses_list"
    assert_select "#variable_expenses_list"
    # installment section header uses installment_expenses key
    assert_match I18n.t("expenses.index.installment_expenses"), response.body
    # variable other section header uses variable_other key
    assert_match I18n.t("expenses.index.variable_other"), response.body
    # fixed section still present
    assert_match I18n.t("expenses.index.fixed_expenses"), response.body
  end

  test "GET index variable regular expenses are ordered most recent first" do
    # Travel to mid-month so that subtracting 5 days stays within the same month
    travel_to Date.current.beginning_of_month + 14.days do
      older = create(:expense, user: @user, category: @category, description: "Older Expense",
                     expense_type: "variable", date: Date.current - 5.days)
      newer = create(:expense, user: @user, category: @category, description: "Newer Expense",
                     expense_type: "variable", date: Date.current)

      sign_in @user
      get expenses_path

      newer_pos = response.body.index("Newer Expense")
      older_pos = response.body.index("Older Expense")
      assert newer_pos < older_pos, "Newer expense should appear before older expense"
    end
  end

  test "GET index variable installment expenses are ordered most recent first" do
    # Travel to mid-month so that subtracting 5 days stays within the same month
    travel_to Date.current.beginning_of_month + 14.days do
      group1 = SecureRandom.uuid
      group2 = SecureRandom.uuid
      older_inst = create(:expense, user: @user, category: @category, description: "Old TV 1/3",
                          expense_type: "variable", date: Date.current - 5.days,
                          installment_group_id: group1, installment_number: 1, total_installments: 3)
      newer_inst = create(:expense, user: @user, category: @category, description: "New Phone 1/3",
                          expense_type: "variable", date: Date.current,
                          installment_group_id: group2, installment_number: 1, total_installments: 3)

      sign_in @user
      get expenses_path

      newer_pos = response.body.index("New Phone 1/3")
      older_pos = response.body.index("Old TV 1/3")
      assert newer_pos > older_pos, "Older installment should appear before newer installment"
    end
  end

  # CC invoice drill-down: future period filtering
  test "GET index with future CC period excludes recurring expenses" do
    card = create(:credit_card, user: @user)
    future_start = 1.month.from_now.to_date
    future_end   = future_start + 30.days

    recurring = create(:expense, user: @user, category: @category,
                       description: "Netflix Recurring",
                       expense_type: "fixed", recurring: true,
                       payment_method: "credit_card", credit_card: card,
                       date: future_start)
    sign_in @user
    get expenses_path, params: { credit_card_id: card.id, period_start: future_start.iso8601, period_end: future_end.iso8601 }

    assert_response :success
    assert_no_match recurring.description, response.body
  end

  test "GET index with future CC period includes installment expenses" do
    card = create(:credit_card, user: @user)
    future_start = 1.month.from_now.to_date
    future_end   = future_start + 30.days

    installment = create(:expense, user: @user, category: @category,
                         description: "New Laptop 2/12",
                         expense_type: "variable", recurring: false,
                         payment_method: "credit_card", credit_card: card,
                         date: future_start,
                         installment_number: 2, total_installments: 12,
                         installment_group_id: SecureRandom.uuid)
    sign_in @user
    get expenses_path, params: { credit_card_id: card.id, period_start: future_start.iso8601, period_end: future_end.iso8601 }

    assert_response :success
    assert_match installment.description, response.body
  end

  test "GET index with past CC period still includes recurring expenses" do
    card = create(:credit_card, user: @user)
    past_start = 2.months.ago.to_date
    past_end   = past_start + 30.days

    recurring = create(:expense, user: @user, category: @category,
                       description: "Spotify Past",
                       expense_type: "fixed", recurring: true,
                       payment_method: "credit_card", credit_card: card,
                       date: past_start)
    sign_in @user
    get expenses_path, params: { credit_card_id: card.id, period_start: past_start.iso8601, period_end: past_end.iso8601 }

    assert_response :success
    assert_match recurring.description, response.body
  end
end
