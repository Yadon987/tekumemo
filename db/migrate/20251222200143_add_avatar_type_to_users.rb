class AddAvatarTypeToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :avatar_type, :integer, default: 0, null: false

    # 既存データの移行
    # use_google_avatar: true -> avatar_type: 1 (google)
    # use_google_avatar: false -> avatar_type: 0 (default)
    User.reset_column_information
    User.find_each do |user|
      # use_google_avatarカラムが存在し、かつtrueの場合のみ更新
      # （falseの場合はデフォルトの0でOKなのでスキップ可能だが、念のため明示的に）
      new_type = user.use_google_avatar ? 1 : 0
      user.update_columns(avatar_type: new_type)
    end

    remove_column :users, :use_google_avatar
  end

  def down
    add_column :users, :use_google_avatar, :boolean, default: true

    User.reset_column_information
    User.find_each do |user|
      # avatar_type: 1 (google) -> use_google_avatar: true
      # その他 -> use_google_avatar: false
      is_google = (user.avatar_type == 1)
      user.update_columns(use_google_avatar: is_google)
    end

    remove_column :users, :avatar_type
  end
end
