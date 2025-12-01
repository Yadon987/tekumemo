class AddUseGoogleAvatarToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :use_google_avatar, :boolean, default: true
  end
end
