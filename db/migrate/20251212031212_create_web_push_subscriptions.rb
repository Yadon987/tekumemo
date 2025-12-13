class CreateWebPushSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :web_push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false, comment: "通知送信先URL"
      t.string :p256dh, null: false, comment: "暗号化キー (P-256 curve)"
      t.string :auth_key, null: false, comment: "認証シークレット"
      t.string :user_agent, comment: "登録したブラウザ/デバイス情報"

      t.timestamps
    end

    add_index :web_push_subscriptions, :endpoint, unique: true
  end
end
