# frozen_string_literal: true

# achievementsテーブルのカラム名を改善
# - name → title (実績の名称)
# - description → flavor_text (実績の説明文)
# - condition_type → metric (達成条件の種類)
# - condition_value → requirement (達成条件の閾値、integer→bigint)
# - icon_name → badge_key (アイコン識別名)
class RenameAchievementsColumns < ActiveRecord::Migration[7.2]
  def change
    # データを保持したままカラム名を変更（reversible）
    rename_column :achievements, :name, :title
    rename_column :achievements, :description, :flavor_text
    rename_column :achievements, :condition_type, :metric
    rename_column :achievements, :condition_value, :requirement
    rename_column :achievements, :icon_name, :badge_key

    # 型変更: integer → bigint（データロスなし、拡張方向）
    change_column :achievements, :requirement, :bigint, null: false, default: 0
  end
end
