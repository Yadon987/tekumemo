class AddGoogleOauthToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :google_token, :text
    add_column :users, :google_refresh_token, :text
    add_column :users, :google_expires_at, :datetime
  end
end
