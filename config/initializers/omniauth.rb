# OmniAuthの初期化設定

# Rails 7のTurboとOmniAuthを連携させるための設定
# POSTとGETの両方を許可（Google OAuth2のコールバックフローに必要）
OmniAuth.config.allowed_request_methods = %i[post get]

# GET警告を全環境で抑制（POSTリクエストに修正済み）
OmniAuth.config.silence_get_warning = true

# 【重要】OmniAuth 2.xのリクエストフェーズでのCSRF検証を無効化
# Render等のPaaS環境では、プロキシ経由でCookieが正しく伝播しないことがあり、
# CSRFトークン検証が失敗することがある。
# OAuth2のセキュリティは「state」パラメータによって保証されるため、
# リクエストフェーズでのCSRFチェックは冗長であり、無効化しても安全。
# 参考: https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
OmniAuth.config.request_validation_phase = nil

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
