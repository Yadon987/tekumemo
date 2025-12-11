class AddIsAdminToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_admin, :boolean, default: false, null: false
    add_index :users, :is_admin
  end
end
