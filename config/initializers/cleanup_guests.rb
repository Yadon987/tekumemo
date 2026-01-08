# frozen_string_literal: true

# 古いゲストユーザーのクリーンアップ
# アプリ起動時（デプロイ時）に実行される
Rails.application.config.after_initialize do
  if Rails.env.production?
    # 起動時にクリーンアップを実行（非同期ではなく同期的に）
    User.cleanup_old_guests
    Rails.logger.info "[Cleanup] Old guest users cleaned up on app boot"
  end
end
