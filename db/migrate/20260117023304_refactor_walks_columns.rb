class RefactorWalksColumns < ActiveRecord::Migration[7.2]
  def change
    rename_column :walks, :distance, :kilometers
    rename_column :walks, :duration, :minutes

    # Set precision for kilometers (e.g. 1.35)
    change_column :walks, :kilometers, :decimal, precision: 10, scale: 2
  end
end
