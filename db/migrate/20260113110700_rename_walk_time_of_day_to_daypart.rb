# Walksテーブルのtime_of_dayカラムをdaypartにリネーム
#
# レビュアーからの指摘に基づき、アンダースコアを減らしてdaypartに変更
class RenameWalkTimeOfDayToDaypart < ActiveRecord::Migration[7.2]
  def change
    rename_column :walks, :time_of_day, :daypart
  end
end
