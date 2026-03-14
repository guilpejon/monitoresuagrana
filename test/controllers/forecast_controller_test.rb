require "test_helper"

class ForecastControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @category = @user.categories.first
  end

  test "redirects to sign in when not authenticated" do
    get forecast_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success for current/future month" do
    sign_in @user
    get forecast_path
    assert_response :success
  end

  test "GET index returns success for future month" do
    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_response :success
  end

  test "GET index returns success for past month" do
    sign_in @user
    get forecast_path, params: { month: 1.month.ago.strftime("%Y-%m") }
    assert_response :success
  end

  test "future month shows recurring and installment expenses" do
    create(:expense, user: @user, category: @category, expense_type: "fixed", recurring: true, amount: 500)
    create(:expense, user: @user, category: @category,
           date: 1.month.from_now.beginning_of_month,
           total_installments: 3, installment_number: 1, amount: 100)

    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_response :success
  end

  test "past month shows actual expenses and incomes" do
    past = 1.month.ago.beginning_of_month
    create(:expense, user: @user, category: @category, date: past, amount: 250)
    create(:income, user: @user, date: past, amount: 3000)

    sign_in @user
    get forecast_path, params: { month: past.strftime("%Y-%m") }
    assert_response :success
  end

  test "current month renders monthly spending progress chart" do
    create(:expense, user: @user, category: @category, date: Date.current, amount: 150)
    create(:expense, user: @user, category: @category, recurring: true, amount: 500)

    sign_in @user
    get forecast_path
    assert_response :success
    assert_match I18n.t("forecast.index.monthly_spending_trend"), response.body
  end

  test "current month chart includes actual and projected series labels" do
    create(:expense, user: @user, category: @category, date: Date.current, amount: 200)
    create(:income, user: @user, date: Date.current, amount: 3000, recurring: true)

    sign_in @user
    get forecast_path
    assert_match I18n.t("forecast.index.actual_spending"), response.body
    assert_match I18n.t("forecast.index.income_line"), response.body
  end

  test "past month renders monthly spending progress chart with actual data" do
    past = 1.month.ago.beginning_of_month
    create(:expense, user: @user, category: @category, date: past, amount: 300)
    create(:income, user: @user, date: past, amount: 2000)

    sign_in @user
    get forecast_path, params: { month: past.strftime("%Y-%m") }
    assert_match I18n.t("forecast.index.monthly_spending_trend"), response.body
    assert_match I18n.t("forecast.index.actual_spending"), response.body
    assert_match I18n.t("forecast.index.income_line"), response.body
  end

  test "future month renders monthly spending progress chart with projected data" do
    create(:expense, user: @user, category: @category, recurring: true, amount: 500)
    create(:income, user: @user, date: 1.month.from_now.beginning_of_month, amount: 3000, recurring: true)

    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_match I18n.t("forecast.index.monthly_spending_trend"), response.body
    assert_match I18n.t("forecast.index.projected_spending"), response.body
    assert_match I18n.t("forecast.index.income_line"), response.body
  end

  test "future month with no scheduled expenses or income omits both chart lines" do
    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_match I18n.t("forecast.index.monthly_spending_trend"), response.body
    assert_no_match /"name":"#{I18n.t("forecast.index.projected_spending")}"/, response.body
    assert_no_match /"name":"#{I18n.t("forecast.index.income_line")}"/, response.body
  end

  test "future month with generated recurring income copy shows income line" do
    create(:income, user: @user, date: 1.month.from_now.beginning_of_month, amount: 3000, recurring: true)

    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_match I18n.t("forecast.index.income_line"), response.body
  end

  test "income not in the viewed month does not show income line" do
    create(:income, user: @user, date: 2.months.from_now.beginning_of_month, amount: 3000, recurring: true)

    sign_in @user
    get forecast_path, params: { month: 1.month.from_now.strftime("%Y-%m") }
    assert_no_match /"name":"#{I18n.t("forecast.index.income_line")}"/, response.body
  end
end
