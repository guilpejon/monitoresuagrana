# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      @user.remember_me!
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    # When the OAuth callback is intercepted by the installed PWA but the session
    # was started in the browser, OmniAuth fails with a CSRF/state mismatch.
    # Automatically retry so the new flow starts and completes in the same context.
    if request.env["omniauth.error.type"] == :csrf_detected
      redirect_to user_google_oauth2_omniauth_authorize_path
    else
      redirect_to root_path, alert: t("devise.omniauth_callbacks.failure", kind: "Google", reason: failure_message)
    end
  end
end
