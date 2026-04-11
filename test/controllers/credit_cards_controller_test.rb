require "test_helper"

class CreditCardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @credit_card = create(:credit_card, user: @user)
  end

  test "redirects to sign in when not authenticated" do
    get credit_cards_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get credit_cards_path
    assert_response :success
  end

  test "GET new returns success" do
    sign_in @user
    get new_credit_card_path
    assert_response :success
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_credit_card_path(@credit_card)
    assert_response :success
  end

  test "POST create with valid params creates credit card" do
    sign_in @user
    assert_difference "CreditCard.count", 1 do
      post credit_cards_path, params: {
        credit_card: {
          name: "My Visa",
          limit: 10000.00,
          last4: "1234",
          brand: "visa",
          color: "#6C63FF",
          billing_day: 5,
          due_day: 15
        }
      }
    end
    assert_redirected_to credit_cards_path
    assert_equal I18n.t("controllers.credit_cards.created"), flash[:notice]
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "CreditCard.count" do
      post credit_cards_path, params: {
        credit_card: { name: nil, billing_day: 0, due_day: 0 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates credit card" do
    sign_in @user
    patch credit_card_path(@credit_card), params: {
      credit_card: { name: "Updated Card" }
    }
    assert_redirected_to credit_cards_path
    assert_equal I18n.t("controllers.credit_cards.updated"), flash[:notice]
    assert_equal "Updated Card", @credit_card.reload.name
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch credit_card_path(@credit_card), params: {
      credit_card: { name: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes credit card" do
    sign_in @user
    assert_difference "CreditCard.count", -1 do
      delete credit_card_path(@credit_card)
    end
    assert_redirected_to credit_cards_path
    assert_equal I18n.t("controllers.credit_cards.destroyed"), flash[:notice]
  end

  test "cannot access other user's credit card" do
    other_user = create(:user)
    other_card = create(:credit_card, user: other_user)

    sign_in @user
    get edit_credit_card_path(other_card)
    assert_response :not_found
  end

  test "cannot update other user's credit card" do
    other_user = create(:user)
    other_card = create(:credit_card, user: other_user)

    sign_in @user
    patch credit_card_path(other_card), params: { credit_card: { name: "Hacked" } }
    assert_response :not_found
  end

  test "cannot delete other user's credit card" do
    other_user = create(:user)
    other_card = create(:credit_card, user: other_user)

    sign_in @user
    assert_no_difference "CreditCard.count" do
      delete credit_card_path(other_card)
    end
    assert_response :not_found
  end

  test "PATCH set_default sets card as user default" do
    sign_in @user
    patch set_default_credit_card_path(@credit_card)
    assert_redirected_to credit_cards_path
    assert_equal I18n.t("controllers.credit_cards.default_set"), flash[:notice]
    assert_equal @credit_card.id, @user.reload.default_credit_card_id
  end

  test "PATCH set_default clears default when card is already the default" do
    @user.update!(default_credit_card_id: @credit_card.id)
    sign_in @user
    patch set_default_credit_card_path(@credit_card)
    assert_redirected_to credit_cards_path
    assert_equal I18n.t("controllers.credit_cards.default_cleared"), flash[:notice]
    assert_nil @user.reload.default_credit_card_id
  end

  test "cannot set default on other user's credit card" do
    other_user = create(:user)
    other_card = create(:credit_card, user: other_user)

    sign_in @user
    patch set_default_credit_card_path(other_card)
    assert_response :not_found
  end

  test "destroying default card clears user default" do
    @user.update!(default_credit_card_id: @credit_card.id)
    sign_in @user
    delete credit_card_path(@credit_card)
    assert_nil @user.reload.default_credit_card_id
  end

  test "GET invoices returns success" do
    sign_in @user
    get invoices_credit_card_path(@credit_card)
    assert_response :success
  end

  test "GET invoices renders 19 period rows (6 upcoming + 1 current + 12 past)" do
    sign_in @user
    get invoices_credit_card_path(@credit_card)
    # Each row has a link to expenses_path with period_start param
    assert_equal 19, response.body.scan(/period_start=/).count
  end

  test "GET invoices renders exactly one open badge" do
    sign_in @user
    get invoices_credit_card_path(@credit_card)
    assert_equal 1, response.body.scan(I18n.t("credit_cards.invoices.open")).count
  end

  test "GET invoices shows past expense amount" do
    category = @user.categories.first
    past_start, = @credit_card.billing_periods_history(1).first
    create(:expense, user: @user, category: category, credit_card: @credit_card,
           date: past_start + 1.day, amount: 88.00)

    sign_in @user
    get invoices_credit_card_path(@credit_card)
    assert_match "88", response.body
  end

  test "GET invoices shows future installment amount" do
    category = @user.categories.first
    upcoming_start, = @credit_card.billing_periods_upcoming(1).first
    create(:expense, user: @user, category: category, credit_card: @credit_card,
           date: upcoming_start + 1.day, amount: 55.00,
           payment_method: "credit_card", total_installments: 3, installment_number: 1)

    sign_in @user
    get invoices_credit_card_path(@credit_card)
    assert_match "55", response.body
  end

  test "GET invoices on another user's card returns 404" do
    other_user = create(:user)
    other_card  = create(:credit_card, user: other_user)

    sign_in @user
    get invoices_credit_card_path(other_card)
    assert_response :not_found
  end

  test "GET invoices redirects to sign in when not authenticated" do
    get invoices_credit_card_path(@credit_card)
    assert_redirected_to new_user_session_path
  end
end
