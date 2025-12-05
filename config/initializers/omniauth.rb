# OmniAuthの初期化設定
# omniauth-rails_csrf_protection gemを使用してCSRF保護を有効化

# Rails 7のTurboとOmniAuthを連携させるための設定
# POSTとGETの両方を許可（Google OAuth2のコールバックフローに必要）
OmniAuth.config.allowed_request_methods = [ :post, :get ]

# テスト・開発環境でのSSL警告を無効化（本番環境では有効のまま）
OmniAuth.config.silence_get_warning = true unless Rails.env.production?

# 認証失敗時の詳細ログを出力（本番環境でのデバッグ用）
OmniAuth.config.on_failure = proc { |env|
  error_type = env["omniauth.error.type"]
  error = env["omniauth.error"]
  strategy = env["omniauth.strategy"]&.name

  Rails.logger.error "=== OmniAuth Authentication Failure ==="
  Rails.logger.error "Error Type: #{error_type}"
  Rails.logger.error "Error Message: #{error&.message}"
  Rails.logger.error "Strategy: #{strategy}"
  Rails.logger.error "Request Path: #{env['REQUEST_PATH']}"
  Rails.logger.error "Request Method: #{env['REQUEST_METHOD']}"
  Rails.logger.error "=========================================="

  # デフォルトのエラーハンドラーに処理を委譲
  # Users::OmniauthCallbacksController#failure にリダイレクト
  env["omniauth.error.type"] = error_type
  OmniAuth::FailureEndpoint.new(env).call
}
