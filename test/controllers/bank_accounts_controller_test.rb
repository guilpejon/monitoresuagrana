require "test_helper"

class BankAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @bank_account = create(:bank_account, user: @user)
  end

  test "redirects to sign in when not authenticated" do
    get bank_accounts_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get bank_accounts_path
    assert_response :success
  end

  test "GET new returns success" do
    sign_in @user
    get new_bank_account_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_bank_account_path(@bank_account)
    assert_response :success
  end

  test "POST create with fixed rate creates bank account" do
    sign_in @user
    assert_difference "BankAccount.count", 1 do
      post bank_accounts_path, params: {
        bank_account: {
          name: "My Savings",
          bank_name: "Nubank",
          account_type: "savings",
          balance: 5000.0,
          interest_rate: 6.5,
          currency: "BRL",
          color: "#6C63FF",
          rate_type: "fixed",
          cdi_multiplier: 100.0
        }
      }
    end
    assert_redirected_to bank_accounts_path
    assert_equal "Bank account added.", flash[:notice]
  end

  test "POST create with CDI rate creates bank account" do
    sign_in @user
    assert_difference "BankAccount.count", 1 do
      post bank_accounts_path, params: {
        bank_account: {
          name: "CDB 120% CDI",
          bank_name: "XP",
          account_type: "savings",
          balance: 10000.0,
          interest_rate: 0,
          currency: "BRL",
          color: "#00D4AA",
          rate_type: "cdi_percentage",
          cdi_multiplier: 120.0
        }
      }
    end
    assert_redirected_to bank_accounts_path
    account = BankAccount.last
    assert_equal "cdi_percentage", account.rate_type
    assert_equal 120.0, account.cdi_multiplier.to_f
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "BankAccount.count" do
      post bank_accounts_path, params: {
        bank_account: { name: nil, account_type: "invalid" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates bank account" do
    sign_in @user
    patch bank_account_path(@bank_account), params: {
      bank_account: { name: "Updated Name" }
    }
    assert_redirected_to bank_accounts_path
    assert_equal "Bank account updated.", flash[:notice]
    assert_equal "Updated Name", @bank_account.reload.name
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch bank_account_path(@bank_account), params: {
      bank_account: { name: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes bank account" do
    sign_in @user
    assert_difference "BankAccount.count", -1 do
      delete bank_account_path(@bank_account)
    end
    assert_redirected_to bank_accounts_path
    assert_equal "Bank account removed.", flash[:notice]
  end

  test "cannot access other user's bank account" do
    other_user = create(:user)
    other_account = create(:bank_account, user: other_user)

    sign_in @user
    get edit_bank_account_path(other_account)
    assert_response :not_found
  end

  test "POST refresh_cdi_rate redirects with notice" do
    sign_in @user
    post refresh_cdi_rate_bank_accounts_path
    assert_redirected_to bank_accounts_path
    assert_equal "CDI rate refresh queued.", flash[:notice]
  end
end
