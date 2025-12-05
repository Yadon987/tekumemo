class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # CSRF保護をスキップ（OmniAuthのコールバックのため）
  # google_oauth2, failure, passthr uの3つすべてに適用
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2, :failure, :passthru ]

  # Google OAuth2のコールバック処理
  # Googleから認証が完了した後に呼ばれる
  def google_oauth2
    # OmniAuthから返された認証情報
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      # ログイン中の場合：既存アカウントにGoogle情報を紐付け
      auth_email = auth.info.email

      # メールアドレスが一致しない場合 -> 確認画面へ
      if current_user.email != auth_email
        # 認証情報を一時的にセッションに保存（確認画面で使用）
        session[:google_auth_data] = {
          uid: auth.uid,
          token: auth.credentials.token,
          refresh_token: auth.credentials.refresh_token,
          expires_at: auth.credentials.expires_at,
          image: auth.info.image,
          email: auth_email
        }
        redirect_to confirm_email_change_users_path
        return
      end

      # メールアドレスが一致する場合 -> そのまま連携
      connect_google_account(auth)
    else
      # 未ログインの場合：Google連携済みのユーザーを探す
      @user = User.from_omniauth(auth)

      if @user
        # 連携済みユーザーが見つかった場合 -> ログイン
        @user.remember_me = true
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
      else
        # 未連携の場合 -> ログイン画面に戻してエラー表示
        # セッションにデータは保存しない（新規登録には使わないため）
        redirect_to new_user_session_path, alert: "このGoogleアカウントは連携されていません。先にメールアドレスでログインし、設定画面から連携してください。"
      end
    end
  end

  # メールアドレス変更確認後の連携処理
  def update_email_and_connect
    auth_data = session[:google_auth_data]

    unless auth_data
      redirect_to edit_user_registration_path, alert: "セッションが切れました。もう一度連携操作を行ってください。"
      return
    end

    # メールアドレスを更新して連携
    if current_user.update(
      email: auth_data["email"],
      google_uid: auth_data["uid"],
      google_token: auth_data["token"],
      google_refresh_token: auth_data["refresh_token"],
      google_expires_at: Time.at(auth_data["expires_at"]),
      avatar_url: auth_data["image"]
    )
      session.delete(:google_auth_data) # セッション削除
      redirect_to edit_user_registration_path, notice: "メールアドレスを更新し、Googleアカウントと連携しました。"
    else
      redirect_to edit_user_registration_path, alert: "連携に失敗しました: #{current_user.errors.full_messages.join(', ')}"
    end
  end

  private

  # Googleアカウントとの連携処理（共通化）
  def connect_google_account(auth)
    if current_user.update(
      google_uid: auth.uid,
      google_token: auth.credentials.token,
      google_refresh_token: auth.credentials.refresh_token,
      google_expires_at: Time.at(auth.credentials.expires_at),
      avatar_url: auth.info.image
    )
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
      redirect_to edit_user_registration_path, notice: "Googleアカウントと連携しました"
    else
      error_msg = "Googleアカウントの連携に失敗しました: #{current_user.errors.full_messages.join(', ')}"
      redirect_to edit_user_registration_path, alert: error_msg
    end
  end

  # OAuth認証失敗時の処理
  def failure
    Rails.logger.error "=== Google Auth Failure Debug Info ==="
    Rails.logger.error "Session ID: #{session.id.inspect}"
    Rails.logger.error "CSRF Token in params: #{request.params['authenticity_token']}"
    Rails.logger.error "Cookie Header: #{request.headers['Cookie']}"
    Rails.logger.error "X-Forwarded-Proto: #{request.headers['X-Forwarded-Proto']}"
    Rails.logger.error "Origin: #{request.headers['Origin']}"
    Rails.logger.error "======================================"

    redirect_to root_path, alert: t("devise.omniauth_callbacks.failure", kind: "Google", reason: "アクセスが拒否されたか、エラーが発生しました")
  end
end
