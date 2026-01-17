# 削除してしまったsign_in関連カラムを復元
#
# Deviseの:trackableモジュールが有効なため、これらのカラムは必須でした。
class RestoreSignInColumns < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :last_sign_in_at, :datetime
  end
end
