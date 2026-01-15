# frozen_string_literal: true

class ChangeBadgeKeyToText < ActiveRecord::Migration[7.2]
  def up
    change_column :achievements, :badge_key, :text, null: false
  end

  def down
    change_column :achievements, :badge_key, :string, null: false
  end
end
