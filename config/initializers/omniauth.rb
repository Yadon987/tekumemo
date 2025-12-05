# OmniAuthの初期化設定
# omniauth-rails_csrf_protection gemを使用してCSRF保護を有効化

# Rails 7のTurboとOmniAuthを連携させるための設定
# POSTとGETの両方を許可（Google OAuth2のコールバックフローに必要）
OmniAuth.config.allowed_request_methods = [ :post, :get ]

# テスト・開発環境でのSSL警告を無効化（本番環境では有効のまま）
OmniAuth.config.silence_get_warning = true unless Rails.env.production?
