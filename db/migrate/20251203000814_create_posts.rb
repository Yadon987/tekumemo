class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :walk, null: true, foreign_key: true
      t.text :body  # null: falseを削除（天気・気分のみの投稿も可能に）
      t.integer :weather
      t.integer :feeling

      t.timestamps
    end

    # 全ユーザーのタイムライン表示を高速化
    add_index :posts, :created_at

    # 特定ユーザーの投稿履歴表示を高速化
    add_index :posts, [:user_id, :created_at]
  end
end
