class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # CSRF保護をスキップ（OmniAuthのコールバックのため）
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2 ]

  # Google OAuth2のコールバック処理
  # Googleから認証が完了した後に呼ばれる
  def google_oauth2
    # OmniAuthから返された認証情報を使ってユーザーを検索または作成
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      # ユーザーの保存に成功した場合
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      # ユーザーの保存に失敗した場合
      session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  # OAuth認証失敗時の処理
  def failure
    redirect_to root_path, alert: "Google認証に失敗しました。もう一度お試しください。"
  end
end
