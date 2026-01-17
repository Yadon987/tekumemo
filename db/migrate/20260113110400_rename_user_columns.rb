# Usersテーブルのカラム名リネーム
#
# レビュアーからの指摘に基づき、以下の変更を実施:
# - target_distance → goal_meters: 単位を明確化
# - walk_reminder_enabled → is_walk_reminder: Boolean命名規則(is_xxx)に準拠
# - inactive_days_reminder_enabled → is_inactive_reminder: `_`を2つ以下に削減
# - reaction_summary_enabled → is_reaction_summary: Boolean命名規則に準拠
# - inactive_days_threshold → inactive_days: thresholdを避けて簡潔に
class RenameUserColumns < ActiveRecord::Migration[7.2]
  def change
    # 目標距離: 単位を明確化
    rename_column :users, :target_distance, :goal_meters

    # Boolean命名規則に準拠 (is_xxx形式)
    rename_column :users, :walk_reminder_enabled, :is_walk_reminder
    rename_column :users, :inactive_days_reminder_enabled, :is_inactive_reminder
    rename_column :users, :reaction_summary_enabled, :is_reaction_summary

    # threshold を避けて簡潔に
    rename_column :users, :inactive_days_threshold, :inactive_days
  end
end
