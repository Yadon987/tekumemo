require "active_support/core_ext/integer/time"

Rails.application.configure do
  # 開発環境での設定
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # アセット設定を最適化
  config.assets.debug = false
  config.assets.digest = true
  config.assets.compile = true
  # Tailwind CSSビルドファイルを明示的に指定
  config.assets.precompile += %w[application.css]

  # キャッシュ設定
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    # キャッシュストアをSolid Cacheに変更
    config.cache_store = :solid_cache_store
    config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # ストレージ設定
  config.active_storage.service = :local

  # メール設定
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # ログ設定
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # データベース設定
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # ジョブログ設定
  config.active_job.verbose_enqueue_logs = true

  # アセットを静的に配信
  config.assets.quiet = true

  # ビューファイル名を注釈
  config.action_view.annotate_rendered_view_with_filenames = true

  # コールバックエラー設定
  # Rails 7.1のデフォルトではtrueだが、OmniAuthのpassthruアクションとの互換性のためfalseに設定
  config.action_controller.raise_on_missing_callback_actions = false
end
