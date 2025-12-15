#!/usr/bin/env ruby
# 異常検知テスト用ダミーデータ作成スクリプト
# 実行方法: rails runner db/scripts/create_anomaly_test_data.rb
# 削除方法: rails runner db/scripts/delete_anomaly_test_data.rb

puts "=== 異常検知テスト用ダミーデータ作成開始 ==="

# テスト用ユーザーを一時的に保存する配列
test_user_ids = []

# 1. スパム疑いユーザー（24時間で20件以上投稿）
puts "\n[1/5] スパム疑いユーザーを作成中..."
spam_user = User.create!(
  name: "【テスト】スパムユーザー",
  email: "test_spam_#{Time.current.to_i}@example.com",
  password: "password123",
  role: :general
)
test_user_ids << spam_user.id


# 24時間以内に25件の投稿を作成
25.times do |i|
  post = Post.create!(
    user: spam_user,
    body: "テスト投稿 #{i + 1} - これはスパム検知のテストです"
  )
  # タイムスタンプをバリデーションをスキップして更新
  post.update_column(:created_at, rand(1..23).hours.ago)
end
puts "  ✓ スパムユーザー作成完了（25件投稿）"

# 2. 新規ユーザースパム（登録1時間以内に5件以上投稿）
puts "\n[2/5] 新規ユーザースパムを作成中..."
new_spam_user = User.create!(
  name: "【テスト】新規スパム",
  email: "test_new_spam_#{Time.current.to_i}@example.com",
  password: "password123",
  role: :general
)
new_spam_user.update_column(:created_at, 30.minutes.ago)
test_user_ids << new_spam_user.id

# 登録から1時間以内に8件の投稿を作成
8.times do |i|
  post = Post.create!(
    user: new_spam_user,
    body: "新規ユーザー投稿 #{i + 1}"
  )
  post.update_column(:created_at, rand(1..29).minutes.ago)
end
puts "  ✓ 新規スパムユーザー作成完了（8件投稿）"

# 3. データ整合性エラー（異常な距離・歩数の散歩記録）
puts "\n[3/5] データ整合性エラーを作成中..."
invalid_data_user = User.create!(
  name: "【テスト】データ異常ユーザー",
  email: "test_invalid_data_#{Time.current.to_i}@example.com",
  password: "password123",
  role: :general
)
test_user_ids << invalid_data_user.id

# 異常な距離の散歩記録（50km以上）
Walk.create!(
  user: invalid_data_user,
  distance: 75000, # 75km
  steps: 100000,
  walked_on: Date.today,
  duration: 7200 # 2時間 = 7200秒
)

# 異常な歩数の散歩記録（10万歩以上）
Walk.create!(
  user: invalid_data_user,
  distance: 10000,
  steps: 150000, # 15万歩
  walked_on: Date.yesterday,
  duration: 3600 # 1時間 = 3600秒
)
puts "  ✓ データ異常ユーザー作成完了（異常な散歩記録2件）"

# 4. セキュリティ懸念（30日以上未ログインだが最近投稿あり）
puts "\n[4/5] セキュリティ懸念ユーザーを作成中..."
security_concern_user = User.create!(
  name: "【テスト】セキュリティ懸念",
  email: "test_security_#{Time.current.to_i}@example.com",
  password: "password123",
  role: :general
)
# タイムスタンプを手動で設定
security_concern_user.update_columns(
  created_at: 60.days.ago,
  current_sign_in_at: 35.days.ago,
  last_sign_in_at: 36.days.ago
)
test_user_ids << security_concern_user.id

# 最近（7日以内）の投稿を作成
3.times do |i|
  post = Post.create!(
    user: security_concern_user,
    body: "最近の投稿 #{i + 1} - アカウント乗っ取り？"
  )
  post.update_column(:created_at, rand(1..6).days.ago)
end
puts "  ✓ セキュリティ懸念ユーザー作成完了（35日間未ログイン、最近3件投稿）"

# 5. 非アクティブアカウント（登録30日以上、投稿・散歩0件）
puts "\n[5/5] 非アクティブアカウントを作成中..."
3.times do |i|
  inactive_user = User.create!(
    name: "【テスト】非アクティブ#{i + 1}",
    email: "test_inactive_#{i}_#{Time.current.to_i}@example.com",
    password: "password123",
    role: :general
  )
  inactive_user.update_column(:created_at, (35 + i * 5).days.ago)
  test_user_ids << inactive_user.id
end
puts "  ✓ 非アクティブアカウント3件作成完了"

# テストユーザーIDをファイルに保存（削除用）
File.write(
  Rails.root.join('tmp', 'anomaly_test_user_ids.txt'),
  test_user_ids.join("\n")
)

puts "\n=== 完了 ==="
puts "作成されたテストユーザー数: #{test_user_ids.count}"
puts "ユーザーID: #{test_user_ids.join(', ')}"
puts "\n管理者ダッシュボード（/admin）で異常検知を確認してください。"
puts "\n削除方法:"
puts "  rails runner db/scripts/delete_anomaly_test_data.rb"
