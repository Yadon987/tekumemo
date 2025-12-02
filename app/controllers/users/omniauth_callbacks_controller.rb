class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # CSRF保護をスキップ（OmniAuthのコールバックのため）
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2 ]

  # Google OAuth2のコールバック処理
  # Googleから認証が完了した後に呼ばれる
  def google_oauth2
    # OmniAuthから返された認証情報
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      # ログイン中の場合：既存アカウントにGoogle情報を紐付け
      if current_user.update(
        google_uid: auth.uid,
        google_token: auth.credentials.token,
        google_refresh_token: auth.credentials.refresh_token,
        google_expires_at: Time.at(auth.credentials.expires_at),
        avatar_url: auth.info.image,
        email: auth.info.email
      )
        set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
        # 独自の設定画面へリダイレクト
        redirect_to edit_user_registration_path, notice: "Googleアカウントと連携しました（メールアドレスを更新しました）"
      else
        # エラー内容を詳細に表示
        error_msg = "Googleアカウントの連携に失敗しました: #{current_user.errors.full_messages.join(', ')}"
        redirect_to edit_user_registration_path, alert: error_msg
      end
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
