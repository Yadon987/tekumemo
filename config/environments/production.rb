require "active_support/core_ext/integer/time"

Rails.application.configure do
  # 本番環境の基本設定
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # マスターキーの要求（オプション）
  # config.require_master_key = true

  # 静的ファイルの配信設定
  config.public_file_server.enabled = true

  # アセット設定
  config.assets.compile = false
  config.assets.digest = true

  # Tailwind gemのタスクを無効化（Tailwind CLIを使用）
  # config.assets.css_compressor を設定しない

  # ストレージ設定
  config.active_storage.service = :local

  # SSL設定
  config.force_ssl = true
  config.assume_ssl = true # Renderなどのロードバランサ配下でHTTPSとして認識させる

  # ログ設定
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # キャッシュ設定
  # config.cache_store = :mem_cache_store

  # Active Job設定
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "myapp_production"

  # メーラー設定
  config.action_mailer.perform_caching = false
  # config.action_mailer.raise_delivery_errors = false

  # 国際化設定
  config.i18n.fallbacks = true

  # 非推奨警告を無効化
  config.active_support.report_deprecations = false

  # データベーススキーマのダンプを無効化
  config.active_record.dump_schema_after_migration = false

  # インスペクション設定
  config.active_record.attributes_for_inspect = [ :id ]

  # ホスト認証設定
  # config.hosts = [
  #   "example.com",
  #   /.*\.example\.com/
  # ]
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
