class AddNotificationSettingsToUsers < ActiveRecord::Migration[7.2]
  def change
    # 散歩時間リマインド機能
    add_column :users, :walk_reminder_enabled, :boolean, default: false, null: false, comment: "散歩時間リマインド通知の有効/無効"
    add_column :users, :walk_reminder_time, :time, default: "19:00", comment: "散歩リマインド通知の時刻"

    # 非アクティブリマインド機能
    add_column :users, :inactive_days_reminder_enabled, :boolean, default: true, null: false, comment: "非アクティブリマインド通知の有効/無効"
    add_column :users, :inactive_days_threshold, :integer, default: 3, null: false, comment: "非アクティブと判定する日数"

    # リアクションまとめ通知機能
    add_column :users, :reaction_summary_enabled, :boolean, default: true, null: false, comment: "リアクションまとめ通知の有効/無効"
  end
end
