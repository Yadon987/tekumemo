class AddReminderFieldsToNotifications < ActiveRecord::Migration[7.2]
  def change
    # announcement_idをoptionalにする（リマインダー通知では不要なため）
    change_column_null :notifications, :announcement_id, true

    # リマインダー用のカラムを追加
    add_column :notifications, :notification_type, :integer, default: 0, null: false,
                                                             comment: '通知種類: 0=お知らせ, 1=非アクティブリマインド, 2=リアクションまとめ'
    add_column :notifications, :message, :text, comment: 'リマインダー通知のメッセージ'
    add_column :notifications, :url, :string, comment: 'リマインダー通知のリンク先'

    # 検索効率化のためのインデックス
    add_index :notifications, :notification_type
  end
end
