class RevertAchievementRequirementToInteger < ActiveRecord::Migration[7.2]
  def up
    change_column :achievements, :requirement, :integer, limit: 4
  end

  def down
    change_column :achievements, :requirement, :bigint
  end
end
