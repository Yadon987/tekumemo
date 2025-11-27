class AddTargetDistanceToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :target_distance, :integer, default: 3000, null: false
  end
end
