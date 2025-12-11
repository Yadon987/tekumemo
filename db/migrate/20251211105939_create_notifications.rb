class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :announcement, null: false, foreign_key: true
      t.datetime :read_at

      t.timestamps
    end
  end
end
