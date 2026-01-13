# Announcements・Notificationsテーブルのカラム名リネーム
#
# レビュアーからの指摘に基づき、以下の変更を実施:
# - announcement_type → priority: テーブル名の冗長な繰り返しを排除
# - notification_type → kind: テーブル名の冗長な繰り返しを排除
class RenameAnnouncementColumns < ActiveRecord::Migration[7.2]
  def change
    rename_column :announcements, :announcement_type, :priority
    rename_column :notifications, :notification_type, :kind
  end
end
