namespace :announcement do
  desc "初期のお知らせデータをインポートする"
  task import: :environment do
    puts "お知らせデータのインポートを開始します..."

    announcements = [
      {
        title: "データ分析機能リリースのお知らせ",
        content: "日々の散歩データをグラフで確認できる「データ分析機能」をリリースしました！\n\n■ 機能概要\n・週間/月間の歩行距離グラフ\n・消費カロリーの推移\n・時間帯別の活動傾向\n\nマイページの「データ分析」タブからご確認いただけます。毎日の健康管理にぜひお役立てください。",
        announcement_type: "info",
        is_published: true,
        published_at: Time.zone.parse("2024-12-10 10:00:00")
      },
      {
        title: "通知機能リリースのお知らせ 🔔",
        content: "運営からのお知らせが届くと、ベルアイコンに通知バッジが表示されるようになりました。\n重要なお知らせを見逃さずにチェックできます。",
        announcement_type: "info",
        is_published: true,
        published_at: Time.current
      },
      {
        title: "アプリとして使えるようになりました (PWA) 📱",
        content: "スマートフォンやPCのブラウザから「ホーム画面に追加」することで、アプリのように起動できるようになりました！\n\n・ホーム画面からワンタップで起動\n・ページの読み込みが高速化\n・全画面表示で広々使える\n\nぜひホーム画面に追加して、毎日の散歩記録をよりスムーズにお楽しみください！",
        announcement_type: "info",
        is_published: true,
        published_at: Time.current
      }
    ]

    count = 0
    announcements.each do |data|
      announcement = Announcement.find_or_initialize_by(title: data[:title])
      if announcement.new_record?
        announcement.update!(data)
        puts "作成: #{announcement.title}"
        count += 1
      else
        puts "スキップ（既存）: #{announcement.title}"
      end
    end

    puts "#{count}件のお知らせを作成しました。"

    # 全ユーザーへの通知作成
    puts "全ユーザーへの通知を作成中..."
    notification_count = 0
    Announcement.published.find_each do |announcement|
      User.find_each do |user|
        unless Notification.exists?(user: user, announcement: announcement)
          Notification.create!(user: user, announcement: announcement)
          notification_count += 1
        end
      end
    end
    puts "#{notification_count}件の通知を作成しました。"
    puts "完了しました！"
  end
end
