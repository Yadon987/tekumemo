class CreateAnnouncements < ActiveRecord::Migration[7.2]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :announcement_type, default: 'info'
      t.datetime :published_at
      t.datetime :expires_at
      t.boolean :is_published, default: false, null: false
      t.integer :priority, default: 0

      t.timestamps
    end

    add_index :announcements, :is_published
    add_index :announcements, :published_at
  end
end
