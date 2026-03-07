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
end
