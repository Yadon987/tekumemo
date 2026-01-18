class CreateInitialAnnouncements < ActiveRecord::Migration[7.2]
  def up
    announcements = [
      {
        title: '統計・グラフ機能の実装',
        content: '日々の歩数や消費カロリーをグラフで確認できるようになりました。過去のデータと比較して、モチベーション維持に役立ててください。',
        published_at: Time.zone.parse('2025-12-15 10:00:00'),
        announcement_type: 'info'
      },
      {
        title: 'OGP設定とSNSシェア機能の実装',
        content: '散歩の記録やランキング結果をSNSでシェアできるようになりました。RPG風のカード画像が自動生成されます。',
        published_at: Time.zone.parse('2025-12-17 10:00:00'),
        announcement_type: 'info'
      },
      {
        title: 'ライトモードとダークモードのデザイン刷新',
        content: '画面のデザインを大幅にリニューアルしました。ライトモードは「Crystal Claymorphism」、ダークモードは「Holographic Neon Noir」をテーマに、より美しく使いやすいUIになりました。',
        published_at: Time.zone.parse('2025-12-20 10:00:00'),
        announcement_type: 'info'
      },
      {
        title: 'Google Fit連携に一括取込機能を実装',
        content: 'Google Fitからのデータ連携を強化し、過去のデータを一括で取り込めるようになりました。設定画面から連携を行うことで利用可能です。',
        published_at: Time.zone.parse('2025-12-22 10:00:00'),
        announcement_type: 'info'
      },
      {
        title: 'アイコンのアップロード機能の実装',
        content: 'プロフィールアイコンを自由にアップロードできるようになりました。お気に入りの画像を設定して、ランキングや投稿で個性をアピールしましょう。',
        published_at: Time.zone.parse('2025-12-23 10:00:00'),
        announcement_type: 'info'
      }
    ]

    announcements.each do |data|
      # 重複作成を防ぐため、同じタイトルのデータがない場合のみ作成
      next if Announcement.exists?(title: data[:title])

      Announcement.create!(
        title: data[:title],
        content: data[:content],
        published_at: data[:published_at],
        announcement_type: data[:announcement_type],
        expires_at: nil # 無期限
      )
    end
  end

  def down
    # ロールバック時は今回追加したデータを削除
    titles = [
      '統計・グラフ機能の実装',
      'OGP設定とSNSシェア機能の実装',
      'ライトモードとダークモードのデザイン刷新',
      'Google Fit連携に一括取込機能を実装',
      'アイコンのアップロード機能の実装'
    ]
    Announcement.where(title: titles).destroy_all
  end
end
