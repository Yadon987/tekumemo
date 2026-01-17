class RenameNotificationsToReminderLogs < ActiveRecord::Migration[7.2]
  def change
    # テーブル名変更
    rename_table :notifications, :reminder_logs

    # インデックスは自動的にリネームされないため手動で更新
    # ただし、rename_tableでテーブル名が変わると、既存のインデックス名は維持される
    # PostgreSQLではインデックスはテーブル名に依存しないため、必要に応じて変更
    # 以下のコマンドで確認:
    # \d+ reminder_logs でインデックス名を確認できる

    # インデックスのリネームは必須ではないが、一貫性のために実施
    # ただし、エラーが出る場合はスキップする設定
    begin
      rename_index :reminder_logs, 'index_notifications_on_announcement_id',
                   'index_reminder_logs_on_announcement_id' if index_name_exists?(:reminder_logs, 'index_notifications_on_announcement_id')
      rename_index :reminder_logs, 'index_notifications_on_category',
                   'index_reminder_logs_on_category' if index_name_exists?(:reminder_logs, 'index_notifications_on_category')
      rename_index :reminder_logs, 'index_notifications_on_user_id',
                   'index_reminder_logs_on_user_id' if index_name_exists?(:reminder_logs, 'index_notifications_on_user_id')
      rename_index :reminder_logs, 'index_notifications_on_announcement_user_unique',
                   'index_reminder_logs_on_announcement_user_unique' if index_name_exists?(:reminder_logs, 'index_notifications_on_announcement_user_unique')
    rescue StandardError => e
      Rails.logger.warn "インデックスのリネームをスキップ: #{e.message}"
    end
  end
end
