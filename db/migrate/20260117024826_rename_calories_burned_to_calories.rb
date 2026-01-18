class RenameCaloriesBurnedToCalories < ActiveRecord::Migration[7.2]
  def change
    rename_column :walks, :calories_burned, :calories
  end
end
