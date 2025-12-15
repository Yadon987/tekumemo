#!/usr/bin/env ruby
# 異常検知テスト用ダミーデータ削除スクリプト
# 実行方法: rails runner db/scripts/delete_anomaly_test_data.rb

puts "=== 異常検知テスト用ダミーデータ削除開始 ==="

id_file_path = Rails.root.join('tmp', 'anomaly_test_user_ids.txt')

unless File.exist?(id_file_path)
  puts "エラー: ユーザーIDファイルが見つかりません"
  puts "パス: #{id_file_path}"
  exit 1
end

user_ids = File.read(id_file_path).split("\n").map(&:to_i)

if user_ids.empty?
  puts "削除するユーザーIDがありません"
  exit 0
end

puts "削除対象ユーザー数: #{user_ids.count}"
puts "ユーザーID: #{user_ids.join(', ')}"

deleted_count = 0
user_ids.each do |user_id|
  user = User.find_by(id: user_id)
  if user
    user.destroy
    deleted_count += 1
    puts "  ✓ #{user.name} を削除しました"
  else
    puts "  ⚠ ID #{user_id} のユーザーは既に削除されています"
  end
end

# IDファイルを削除
File.delete(id_file_path)

puts "\n=== 完了 ==="
puts "削除されたユーザー数: #{deleted_count}"
puts "関連する投稿・散歩記録も自動的に削除されました（dependent: :destroy）"
