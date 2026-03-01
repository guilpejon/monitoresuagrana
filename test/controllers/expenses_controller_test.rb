require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
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

  test "GET new returns success" do
    sign_in @user
    get new_expense_path
    assert_response :success
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
    assert_equal "Expense added.", flash[:notice]
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
    assert_equal "Expense updated.", flash[:notice]
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
    assert_equal "Expense deleted.", flash[:notice]
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
    assert_equal "Expense added in 3 installments.", flash[:notice]
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
    assert_equal [100.0, 100.0, 100.0], amounts
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
    assert_equal [base, base >> 1, base >> 2], dates
  end

  test "POST create with installments and invalid description re-renders new" do
    sign_in @user
    assert_no_difference "Expense.count" do
      post expenses_path, params: {
        expense: {
          description: nil,
          amount: 300.00,
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
end
