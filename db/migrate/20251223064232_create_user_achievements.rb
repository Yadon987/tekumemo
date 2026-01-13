class CreateUserAchievements < ActiveRecord::Migration[7.2]
  def change
    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true

      t.index %i[user_id achievement_id], unique: true
      t.timestamps
    end
  end
end
