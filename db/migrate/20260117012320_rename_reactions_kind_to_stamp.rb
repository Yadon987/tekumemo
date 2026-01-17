class RenameReactionsKindToStamp < ActiveRecord::Migration[7.2]
  def change
    # カラムリネーム: kind → stamp
    rename_column :reactions, :kind, :stamp

    # インデックスリネーム（既存を削除して新規作成）
    remove_index :reactions, name: 'index_reactions_on_post_id_and_kind', if_exists: true
    remove_index :reactions, name: 'index_reactions_on_user_post_kind', if_exists: true

    add_index :reactions, %i[post_id stamp], name: 'index_reactions_on_post_id_and_stamp', if_not_exists: true
    add_index :reactions, %i[user_id post_id stamp], unique: true, name: 'index_reactions_on_user_post_stamp', if_not_exists: true
  end
end
