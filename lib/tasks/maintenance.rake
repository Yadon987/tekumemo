namespace :maintenance do
  desc "Walkモデルのtime_of_dayカラムをcreated_atに基づいて再計算・更新する"
  task update_walk_time_of_day: :environment do
    puts "Starting update_walk_time_of_day..."

    updated_count = 0
    Walk.find_each do |walk|
      # created_at または walked_on から時間を推定
      # walked_on は日付のみなので、created_at がない場合はデフォルト(早朝)にするか、スキップするか
      target_time = walk.created_at || Time.zone.parse("#{walk.walked_on} 00:00:00")

      hour = target_time.hour
      new_time_of_day = case hour
      when 4..8 then :early_morning
      when 9..15 then :day
      when 16..18 then :evening
      else :night
      end

      # 値が異なる場合のみ更新
      if walk.time_of_day != new_time_of_day.to_s
        walk.update_column(:time_of_day, Walk.time_of_days[new_time_of_day])
        updated_count += 1
      end
    end

    puts "Finished! Updated #{updated_count} walks."
  end
end
