class CreateAchievements < ActiveRecord::Migration[7.2]
  def change
    create_table :achievements do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.integer :condition_type, null: false, default: 0
      t.integer :condition_value, null: false, default: 0
      t.string :icon_name, null: false

      t.timestamps
    end
  end
end
