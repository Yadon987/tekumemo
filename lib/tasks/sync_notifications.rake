namespace :notification do
  desc "公開済みのお知らせに対して、まだ通知が作成されていないユーザーへの通知を一括作成"
  task sync: :environment do
    puts "🔔 通知の同期を開始します..."
    puts ""

    # 現在の状況を表示
    puts "=== 現在の状態 ==="
    puts "  お知らせ数（アクティブ）: #{Announcement.active.count}"
    puts "  ユーザー数: #{User.count}"
    puts "  既存の通知数: #{Notification.count}"
    puts ""

    # 理論上の最大通知数
    expected_max = Announcement.active.count * User.count
    puts "  理論上の最大通知数: #{expected_max}"
    puts ""

    # 通知を作成
    created_count = 0
    skipped_count = 0

    Announcement.active.find_each do |announcement|
      puts "📢 「#{announcement.title.truncate(30)}」の通知を確認中..."

      User.find_each do |user|
        # すでに通知が存在するかチェック
        if Notification.exists?(user: user, announcement: announcement)
          skipped_count += 1
        else
          # 通知を作成
          Notification.create!(
            user: user,
            announcement: announcement,
            kind: :announcement,
            read_at: nil
          )
          created_count += 1
        end
      end
    end

    puts ""
    puts "=== 完了 ==="
    puts "  ✅ 作成した通知数: #{created_count}"
    puts "  ⏭️  スキップ（既存）: #{skipped_count}"
    puts "  📊 現在の通知総数: #{Notification.count}"
    puts ""
    puts "🎉 通知の同期が完了しました！"
  end
end
