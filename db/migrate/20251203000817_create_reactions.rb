class CreateReactions < ActiveRecord::Migration[7.2]
  def change
    create_table :reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.integer :kind, null: false # リアクションの種類

      t.timestamps
    end

    # 1ユーザーが1投稿に対して1種類のリアクションのみ（重複防止）
    add_index :reactions, %i[user_id post_id kind], unique: true, name: 'index_reactions_on_user_post_kind'
    # 投稿ごとのリアクション集計の高速化
    add_index :reactions, %i[post_id kind]
  end
end
