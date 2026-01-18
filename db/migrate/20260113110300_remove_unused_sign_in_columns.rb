# 不要カラム削除マイグレーション
#
# sign_in_count と last_sign_in_at はコード内で使用されていないため削除
# current_sign_in_at は adminダッシュボードで使用中のため保持
class RemoveUnusedSignInColumns < ActiveRecord::Migration[7.2]
  def change
    # rollbackを考慮しreversibleで記述
    reversible do |dir|
      dir.up do
        remove_column :users, :sign_in_count, :integer
        remove_column :users, :last_sign_in_at, :datetime
      end
      dir.down do
        add_column :users, :sign_in_count, :integer, default: 0, null: false
        add_column :users, :last_sign_in_at, :datetime
      end
    end
  end
end
