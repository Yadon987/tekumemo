class CreateWalks < ActiveRecord::Migration[7.2]
  def change
    create_table :walks do |t|
      t.references :user, null: false, foreign_key: true
      t.date :walked_on
      t.integer :duration
      t.decimal :distance
      t.string :location
      t.text :notes

      t.timestamps
    end
  end
end
