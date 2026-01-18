class RenamePostsBodyToContent < ActiveRecord::Migration[7.2]
  def change
    rename_column :posts, :body, :content
  end
end
