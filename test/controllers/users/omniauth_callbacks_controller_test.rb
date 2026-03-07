require "test_helper"

class Users::OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  def auth_hash(email:, name:, uid: "123456", provider: "google_oauth2")
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: name),
      credentials: { token: "token", expires_at: 1.hour.from_now.to_i }
    )
  end

  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "signs in existing user matched by provider and uid" do
    user = create(:user, provider: "google_oauth2", uid: "123456")
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash(email: user.email, name: user.name)

    get user_google_oauth2_omniauth_callback_path
    follow_redirect!

    assert_response :success
    assert_equal user, controller.current_user
  end

  test "connects google to existing email account" do
    user = create(:user, provider: nil, uid: nil)
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash(email: user.email, name: user.name)

    assert_no_difference "User.count" do
      get user_google_oauth2_omniauth_callback_path
    end

    assert_equal "google_oauth2", user.reload.provider
    assert_equal "123456", user.reload.uid
  end

  test "creates new user when no match found" do
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash(email: "new@example.com", name: "New User")

    assert_difference "User.count", 1 do
      get user_google_oauth2_omniauth_callback_path
    end

    new_user = User.find_by(email: "new@example.com")
    assert_not_nil new_user
    assert_equal "google_oauth2", new_user.provider
    assert_equal "123456", new_user.uid
  end

  test "sets remember me on successful sign in" do
    user = create(:user, provider: "google_oauth2", uid: "123456")
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash(email: user.email, name: user.name)

    get user_google_oauth2_omniauth_callback_path

    assert_not_nil user.reload.remember_created_at
  end

  test "redirects to root on failure" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    get user_google_oauth2_omniauth_callback_path

    assert_redirected_to root_path
  end

  test "retries oauth on csrf_detected (PWA intercept scenario)" do
    OmniAuth.config.mock_auth[:google_oauth2] = :csrf_detected

    get user_google_oauth2_omniauth_callback_path

    assert_redirected_to user_google_oauth2_omniauth_authorize_path
  end
end
