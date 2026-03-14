require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @category = @user.categories.first
  end

  test "redirects to sign in when not authenticated" do
    get categories_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns success" do
    sign_in @user
    get categories_path
    assert_response :success
  end

  test "GET new returns success" do
    sign_in @user
    get new_category_path
    assert_response :success
  end

  test "GET show returns success" do
    sign_in @user
    get category_path(@category)
    assert_response :success
  end

  test "GET show uses slug in URL" do
    sign_in @user
    get "/categories/#{@category.slug}"
    assert_response :success
  end

  test "GET show defaults to 6m timeframe" do
    sign_in @user
    get category_path(@category)
    assert_response :success
  end

  test "GET show filters by 6m timeframe" do
    sign_in @user
    get category_path(@category, timeframe: "6m")
    assert_response :success
  end

  test "GET show filters by 1y timeframe" do
    sign_in @user
    get category_path(@category, timeframe: "1y")
    assert_response :success
  end

  test "GET show with all timeframe" do
    sign_in @user
    get category_path(@category, timeframe: "all")
    assert_response :success
  end

  test "GET show ignores unknown timeframe and defaults to 6m" do
    sign_in @user
    get category_path(@category, timeframe: "invalid")
    assert_response :success
  end

  test "GET show with custom timeframe and date range" do
    sign_in @user
    get category_path(@category, timeframe: "custom", start_date: "2026-01-01", end_date: "2026-03-31")
    assert_response :success
  end

  test "GET show with custom timeframe and no dates returns results" do
    sign_in @user
    get category_path(@category, timeframe: "custom")
    assert_response :success
  end

  test "GET show with current_month excludes expenses from future months" do
    sign_in @user
    current_expense = create(:expense, user: @user, category: @category, date: Date.current)
    future_expense  = create(:expense, user: @user, category: @category, date: 1.month.from_now.to_date, expense_type: "fixed")

    get category_path(@category, timeframe: "current_month")
    assert_response :success

    assert_includes response.body, current_expense.description
    assert_not_includes response.body, future_expense.description
  end

  test "GET show with 3m excludes expenses from future months" do
    sign_in @user
    recent_expense = create(:expense, user: @user, category: @category, date: 1.month.ago.to_date)
    future_expense = create(:expense, user: @user, category: @category, date: 1.month.from_now.to_date, expense_type: "fixed")

    get category_path(@category, timeframe: "3m")
    assert_response :success

    assert_includes response.body, recent_expense.description
    assert_not_includes response.body, future_expense.description
  end

  test "GET show with 6m excludes expenses from future months" do
    sign_in @user
    recent_expense = create(:expense, user: @user, category: @category, date: 3.months.ago.to_date)
    future_expense = create(:expense, user: @user, category: @category, date: 1.month.from_now.to_date, expense_type: "fixed")

    get category_path(@category, timeframe: "6m")
    assert_response :success

    assert_includes response.body, recent_expense.description
    assert_not_includes response.body, future_expense.description
  end

  test "GET show with 1y excludes expenses from future months" do
    sign_in @user
    recent_expense = create(:expense, user: @user, category: @category, date: 6.months.ago.to_date)
    future_expense = create(:expense, user: @user, category: @category, date: 1.month.from_now.to_date, expense_type: "fixed")

    get category_path(@category, timeframe: "1y")
    assert_response :success

    assert_includes response.body, recent_expense.description
    assert_not_includes response.body, future_expense.description
  end

  test "cannot access another user's category show page" do
    other_user = create(:user)
    other_category = other_user.categories.create!(name: "UniqueCatGHI", color: "#FF5733", icon: "tag")

    sign_in @user
    get category_path(other_category)
    assert_response :not_found
  end

  test "show redirects unauthenticated users" do
    get category_path(@category)
    assert_redirected_to new_user_session_path
  end

  test "GET edit returns success" do
    sign_in @user
    get edit_category_path(@category)
    assert_response :success
  end

  test "POST create with valid params creates category" do
    sign_in @user
    assert_difference "Category.count", 1 do
      post categories_path, params: {
        category: { name: "Pets", color: "#FF5733", icon: "paw-print" }
      }
    end
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.created"), flash[:notice]
  end

  test "POST create with invalid params re-renders new" do
    sign_in @user
    assert_no_difference "Category.count" do
      post categories_path, params: {
        category: { name: nil, color: nil, icon: nil }
      }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update with valid params updates category" do
    sign_in @user
    patch category_path(@category), params: {
      category: { name: "Updated Name" }
    }
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.updated"), flash[:notice]
    assert_equal "Updated Name", @category.reload.name
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in @user
    patch category_path(@category), params: {
      category: { name: nil }
    }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes category" do
    sign_in @user
    assert_difference "Category.count", -1 do
      delete category_path(@category)
    end
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.destroyed"), flash[:notice]
  end

  test "cannot access other user's category" do
    other_user = create(:user)
    other_category = other_user.categories.create!(name: "UniqueCatXYZ", color: "#FF5733", icon: "tag")

    sign_in @user
    get edit_category_path(other_category)
    assert_response :not_found
  end

  test "cannot update other user's category" do
    other_user = create(:user)
    other_category = other_user.categories.create!(name: "UniqueCatABC", color: "#FF5733", icon: "tag")

    sign_in @user
    patch category_path(other_category), params: { category: { name: "Hacked" } }
    assert_response :not_found
  end

  test "cannot delete other user's category" do
    other_user = create(:user)
    other_category = other_user.categories.create!(name: "UniqueCatDEF", color: "#FF5733", icon: "tag")

    sign_in @user
    delete category_path(other_category)
    assert_response :not_found
  end

  test "PATCH set_default sets category as user default" do
    sign_in @user
    patch set_default_category_path(@category)
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.default_set"), flash[:notice]
    assert_equal @category.id, @user.reload.default_category_id
  end

  test "PATCH set_default clears default when category is already the default" do
    @user.update!(default_category_id: @category.id)
    sign_in @user
    patch set_default_category_path(@category)
    assert_redirected_to categories_path
    assert_equal I18n.t("controllers.categories.default_cleared"), flash[:notice]
    assert_nil @user.reload.default_category_id
  end

  test "cannot set default on other user's category" do
    other_user = create(:user)
    other_category = other_user.categories.create!(name: "UniqueCatJKL", color: "#FF5733", icon: "tag")

    sign_in @user
    patch set_default_category_path(other_category)
    assert_response :not_found
  end

  test "destroying default category clears user default" do
    @user.update!(default_category_id: @category.id)
    sign_in @user
    assert_difference "Category.count", -1 do
      delete category_path(@category)
    end
    assert_nil @user.reload.default_category_id
  end
end
