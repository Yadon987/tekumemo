class AddStepsAndCaloriesToWalks < ActiveRecord::Migration[7.2]
  def change
    add_column :walks, :steps, :integer
    add_column :walks, :calories_burned, :integer
  end
end
