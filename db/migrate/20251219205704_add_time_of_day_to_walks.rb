class AddTimeOfDayToWalks < ActiveRecord::Migration[7.2]
  def up
    add_column :walks, :time_of_day, :integer

    # 既存のデータに対して、created_atを元にtime_of_dayを設定する
    # 0: early_morning (04:00 - 08:59)
    # 1: day (09:00 - 15:59)
    # 2: evening (16:00 - 18:59)
    # 3: night (19:00 - 03:59)

    Walk.reset_column_information
    Walk.find_each do |walk|
      hour = walk.created_at.hour
      time_of_day = case hour
      when 4..8 then 0
      when 9..15 then 1
      when 16..18 then 2
      else 3
      end
      walk.update_columns(time_of_day: time_of_day)
    end
  end

  def down
    remove_column :walks, :time_of_day
  end
end
