class RemovePriorityFromAnnouncements < ActiveRecord::Migration[7.2]
  def change
    remove_column :announcements, :priority, :integer
  end
end
