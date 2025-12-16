source "https://rubygems.org"

# Rails本体
gem "rails", "~> 7.2.3"

# フロントエンド関連
gem "sprockets-rails"      # アセットパイプライン
gem "jsbundling-rails"     # JavaScriptバンドリング（esbuild等）
gem "turbo-rails"          # Hotwire Turbo（高速な画面遷移）
gem "stimulus-rails"       # Hotwire Stimulus（軽量なJSフレームワーク）
gem "jbuilder"             # JSON APIレスポンス構築用

# サーバー・パフォーマンス
gem "puma", ">= 5.0"       # アプリケーションサーバー
gem "bootsnap", require: false  # 起動速度の高速化

# データベース
gem "pg", "~> 1.1"         # PostgreSQL（本番環境）

# 認証・認可
gem "devise"                    # ユーザー認証の基盤
gem "omniauth-google-oauth2"    # Google OAuth2認証
# gem "omniauth-rails_csrf_protection", "~> 2.0.0"  # Rails 7 + Turbo環境では不要（CSRFトークンの二重チェックが問題を引き起こす）

# 外部API連携
gem "google-apis-fitness_v1"    # Google Fit APIとの連携

# UI/UX・機能拡張
gem "simple_calendar", "~> 3.0" # カレンダー表示
gem "kaminari"                  # ページネーション
gem "geocoder"                  # 位置情報・ジオコーディング

# キャッシュ
gem "solid_cache", "~> 1.0"     # Railsの高速キャッシュストア

# 通知機能
gem "web-push", "~> 3.0"        # Web Push通知

# システム・その他
gem "tzinfo-data", platforms: %i[ windows jruby ]  # WindowsやJRuby向けのタイムゾーンデータ
gem "dotenv-rails"              # 環境変数管理（.envファイル）
gem "foreman"                   # 複数プロセス管理（Procfile実行用）

# 開発環境・テスト環境共通
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"  # デバッグツール
  gem "brakeman", require: false          # セキュリティ脆弱性検査
  gem "rubocop-rails-omakase", require: false  # コーディング規約チェック
  gem "rspec-rails", "~> 8.0"             # RSpec（テストフレームワーク）
  gem "factory_bot_rails", "~> 6.5"       # テストデータ生成（ファクトリー）
  gem "faker", "~> 3.5"                   # ダミーデータ生成
  gem "parallel_tests", "~> 5.5"          # 並列テスト実行
end

# 開発環境のみ
group :development do
  gem "web-console"  # ブラウザ上でのデバッグコンソール
end

# テスト環境のみ
group :test do
  gem "sqlite3", ">= 1.4"        # テスト専用のインメモリDB
  gem "capybara"                 # システムテスト（E2Eテスト）
  gem "cuprite"                  # Capybara用のヘッドレスChromeドライバー
  gem "swimming_fish", "~> 0.2.2"  # テスト用のダミーデータ生成ツール
  gem "webmock"                    # HTTPリクエストのスタブ化
end
