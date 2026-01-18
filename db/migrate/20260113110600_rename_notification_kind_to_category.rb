# Notificationsテーブルのkindカラムをcategoryにリネーム
#
# レビュアーからの指摘に基づき、kindは抽象的すぎるためcategoryに変更
class RenameNotificationKindToCategory < ActiveRecord::Migration[7.2]
  def change
    rename_column :notifications, :kind, :category
  end
end
