# frozen_string_literal: true

# announcementsテーブルのpriority列をstring → integerに変更
# Rails enumを使用して型安全性とパフォーマンスを向上
# 同時にexpires_atにインデックスを追加
class ChangePriorityToIntegerAndAddExpiresAtIndex < ActiveRecord::Migration[7.2]
  def up
    # 1. 一時的なinteger列を追加
    add_column :announcements, :priority_int, :integer, default: 0, null: false

    # 2. 既存データを変換
    execute <<-SQL.squish
      UPDATE announcements
      SET priority_int = CASE priority
        WHEN 'info' THEN 0
        WHEN 'warning' THEN 1
        WHEN 'urgent' THEN 2
        ELSE 0
      END
    SQL

    # 3. 旧列を削除
    remove_column :announcements, :priority

    # 4. 新列をリネーム
    rename_column :announcements, :priority_int, :priority

    # 5. expires_atにインデックス追加
    add_index :announcements, :expires_at
  end

  def down
    # インデックス削除
    remove_index :announcements, :expires_at

    # 一時的なstring列を追加
    add_column :announcements, :priority_str, :string, default: 'info'

    # データを変換
    execute <<-SQL.squish
      UPDATE announcements
      SET priority_str = CASE priority
        WHEN 0 THEN 'info'
        WHEN 1 THEN 'warning'
        WHEN 2 THEN 'urgent'
        ELSE 'info'
      END
    SQL

    # 旧列を削除
    remove_column :announcements, :priority

    # 新列をリネーム
    rename_column :announcements, :priority_str, :priority
  end
end
