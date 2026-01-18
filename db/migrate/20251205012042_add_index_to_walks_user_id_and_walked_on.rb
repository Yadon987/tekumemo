class AddIndexToWalksUserIdAndWalkedOn < ActiveRecord::Migration[7.2]
  def change
    add_index :walks, %i[user_id walked_on]
    add_index :walks, :walked_on
  end
end
