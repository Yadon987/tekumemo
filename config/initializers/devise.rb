# frozen_string_literal: true

# Devise設定ファイル
Devise.setup do |config|
  # 秘密鍵の設定（本番環境では環境変数から読み込み推奨）
  # config.secret_key = ENV['DEVISE_SECRET_KEY']

  # ===== メーラー設定 =====
  config.mailer_sender = "noreply@tekumemo.com"
  # config.mailer = 'Devise::Mailer'
  # config.parent_mailer = 'ActionMailer::Base'

  # ===== ORM設定 =====
  require "devise/orm/active_record"

  # ===== 認証設定 =====
  # 認証キー（デフォルトは:email）
  # config.authentication_keys = [:email]

  # 大文字小文字を区別しないキー
  config.case_insensitive_keys = [ :email ]

  # 空白を削除するキー
  config.strip_whitespace_keys = [ :email ]

  # パラメータ認証の有効化
  # config.params_authenticatable = true

  # HTTP認証の設定
  # config.http_authenticatable = false
  # config.http_authenticatable_on_xhr = true
  # config.http_authentication_realm = 'Application'

  # パラノイアモード（セキュリティ向上）
  # config.paranoid = true

  # セッションストレージのスキップ設定
  config.skip_session_storage = [ :http_auth ]

  # CSRF トークンのクリーンアップ
  # config.clean_up_csrf_token_on_authentication = true

  # ルートの再読み込み設定
  # config.reload_routes = true

  # ===== database_authenticatable設定 =====
  # bcryptのコスト（テスト環境では1、本番では12推奨）
  config.stretches = Rails.env.test? ? 1 : 12

  # pepper設定（追加のセキュリティ）
  # config.pepper = ENV['DEVISE_PEPPER']

  # メール変更通知
  # config.send_email_changed_notification = false

  # パスワード変更通知
  # config.send_password_change_notification = false

  # ===== confirmable設定 =====
  # 未確認でのアクセス期間
  # config.allow_unconfirmed_access_for = 2.days

  # 確認期限
  # config.confirm_within = 3.days

  # メール変更時の再確認
  config.reconfirmable = true

  # 確認キー
  # config.confirmation_keys = [:email]

  # ===== rememberable設定 =====
  # ログイン記憶期間
  # config.remember_for = 2.weeks

  # サインアウト時に記憶トークンを無効化
  config.expire_all_remember_me_on_sign_out = true

  # 記憶期間の延長
  # config.extend_remember_period = false

  # Cookieオプション
  # config.rememberable_options = {}

  # ===== validatable設定 =====
  # パスワード長の範囲
  config.password_length = 6..128

  # メールアドレスの正規表現
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ===== timeoutable設定 =====
  # タイムアウト時間
  # config.timeout_in = 30.minutes

  # ===== lockable設定 =====
  # ロック戦略
  # config.lock_strategy = :failed_attempts

  # アンロックキー
  # config.unlock_keys = [:email]

  # アンロック戦略
  # config.unlock_strategy = :both

  # ロックまでの試行回数
  # config.maximum_attempts = 20

  # アンロックまでの時間
  # config.unlock_in = 1.hour

  # 最後の試行の警告
  # config.last_attempt_warning = true

  # ===== recoverable設定 =====
  # パスワードリセットキー
  # config.reset_password_keys = [:email]

  # パスワードリセット期限
  config.reset_password_within = 6.hours

  # パスワードリセット後の自動サインイン
  # config.sign_in_after_reset_password = true

  # ===== encryptable設定 =====
  # bcrypt以外のハッシュアルゴリズムを使用する場合
  # require 'devise-encryptable' gem
  # config.encryptor = :sha512

  # ===== スコープ設定 =====
  # スコープ付きビューの有効化
  # config.scoped_views = false

  # デフォルトスコープ
  # config.default_scope = :user

  # 全スコープからのサインアウト
  # config.sign_out_all_scopes = true

  # ===== ナビゲーション設定 =====
  # ナビゲーショナルフォーマット
  # config.navigational_formats = ['*/*', :html, :turbo_stream]

  # サインアウトのHTTPメソッド（Turbo対応のためDELETEを推奨）
  config.sign_out_via = :delete

  # ===== OmniAuth設定 =====
  # OAuthプロバイダーの追加
  # config.omniauth :github, ENV['GITHUB_APP_ID'], ENV['GITHUB_APP_SECRET'], scope: 'user,public_repo'

  # Google OAuth2設定（Google Fit API連携用）
  # Google Cloud Consoleで取得したクライアントIDとシークレットを使用
  # スコープ: ユーザー情報とGoogle Fit（アクティビティ、位置情報、身体データ）へのアクセス

  # ↓はAIが出してきたコードで、Credentialsが読み込めない場合でもエラーにならないように空ハッシュをデフォルトにするためらしい
  google_creds = begin
    Rails.application.credentials.google || {}
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
    # デプロイ時など、マスターキーが不一致の場合にビルドが落ちないようにする
    {}
  end

  # Credentialsが空の場合はENVにフォールバック（Clone直後の開発者向け）
  google_client_id = google_creds[:client_id].presence || ENV["GOOGLE_CLIENT_ID"]
  google_client_secret = google_creds[:client_secret].presence || ENV["GOOGLE_CLIENT_SECRET"]

  # Google認証が設定されていない場合は警告を出す（アプリ自体は起動する）
  if google_client_id.blank? || google_client_secret.blank?
    warn "WARNING: Google OAuth2 credentials are not configured. Google login will not work."
  end

  config.omniauth :google_oauth2,
                  google_client_id,
                  google_client_secret,
                  {
                    scope: [
                      # 基本認証情報
                      "userinfo.email",
                      "userinfo.profile",
                      # フィットネス関連（歩数・カロリー取得）
                      "https://www.googleapis.com/auth/fitness.activity.read",
                      # 距離データの取得には位置情報権限が必要な場合があるため追加
                      "https://www.googleapis.com/auth/fitness.location.read"
                    ].join(","),

                    access_type: "offline",
                    prompt: "consent"
                  }

  # ===== Warden設定 =====
  # Wardenの追加設定
  # config.warden do |manager|
  #   manager.intercept_401 = false
  #   manager.default_strategies(scope: :user).unshift :some_external_strategy
  # end

  # ===== Hotwire/Turbo設定 =====
  # エラーレスポンスとリダイレクトのステータスコード
  # Turbo対応のために必要な設定
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # ===== registerable設定 =====
  # パスワード変更後の自動サインイン
  # config.sign_in_after_change_password = true
end
