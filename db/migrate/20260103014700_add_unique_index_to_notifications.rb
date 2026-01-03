class AddUniqueIndexToNotifications < ActiveRecord::Migration[7.2]
  def change
    # announcement_idがnullでないレコードに対してのみユニーク制約
    add_index :notifications,
              [ :announcement_id, :user_id ],
              unique: true,
              where: "announcement_id IS NOT NULL",
              name: "index_notifications_on_announcement_user_unique"
  end
end
