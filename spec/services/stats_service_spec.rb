require 'rails_helper'

RSpec.describe StatsService do
  let(:user) { create(:user, target_distance: 3000) }
  let(:service) { StatsService.new(user) }

  describe '基本統計' do
    before do
      # テストデータを作成
      create(:walk, user: user, walked_on: Date.current, distance: 5000, duration: 60, steps: 6000, calories_burned: 250)
      create(:walk, user: user, walked_on: 1.day.ago, distance: 3000, duration: 30, steps: 4000, calories_burned: 150)
      create(:walk, user: user, walked_on: 2.days.ago, distance: 4000, duration: 45, steps: 5000, calories_burned: 200)
    end

    it '累計距離を正しく計算できる' do
      expect(service.total_distance).to eq(12000.0)
    end

    it '累計日数を正しく計算できる' do
      expect(service.total_days).to eq(3)
    end

    it '平均距離を正しく計算できる' do
      # 12000 / 3 = 4000
      expect(service.average_distance_per_day).to eq(4000.0)
    end

    it '最長記録距離を正しく取得できる' do
      expect(service.max_distance).to eq(5000.0)
    end
  end

  describe '今月の統計' do
    before do
      # 今月のデータ
      create(:walk, user: user, walked_on: Date.current, distance: 5000, duration: 60, steps: 6000, calories_burned: 250)
      # 先月のデータ
      create(:walk, user: user, walked_on: Date.current.prev_month, distance: 3000, duration: 30, steps: 4000, calories_burned: 150)
      create(:walk, user: user, walked_on: Date.current.prev_month - 1.day, distance: 4000, duration: 45, steps: 5000, calories_burned: 200)
    end

    it '今月の距離を正しく計算できる' do
      # 今月のデータ（5000m）のみが対象
      expect(service.current_month_distance).to eq(5000.0)
    end
  end

  describe '時系列データ' do
    before do
      # 過去30日間にランダムな記録を作成
      10.times do |i|
        create(:walk,
          user: user,
          walked_on: i.days.ago.to_date,
          distance: (i + 1) * 1000,
          duration: 30
        )
      end
    end

    it '日別距離データを正しく取得できる' do
      result = service.daily_distances_last_30_days

      expect(result).to have_key(:dates)
      expect(result).to have_key(:distances)
      expect(result[:dates].length).to eq(31)  # 30日前〜今日まで
      expect(result[:distances].length).to eq(31)
    end

    it '週別距離データを正しく取得できる' do
      result = service.weekly_distances_last_12_weeks

      expect(result).to have_key(:weeks)
      expect(result).to have_key(:distances)
      expect(result[:weeks].length).to eq(12)
      expect(result[:distances].length).to eq(12)
    end

    it '月別距離データを正しく取得できる' do
      result = service.monthly_distances_last_12_months

      expect(result).to have_key(:months)
      expect(result).to have_key(:distances)
      expect(result[:months].length).to eq(12)
      expect(result[:distances].length).to eq(12)
    end
  end

  describe '曜日別分析' do
    before do
      # 各曜日に記録を作成
      # 月曜日に2000m、火曜日に3000m
      monday = Date.current.beginning_of_week  # 月曜日
      create(:walk, user: user, walked_on: monday, distance: 2000)
      create(:walk, user: user, walked_on: monday + 1.day, distance: 3000)  # 火曜日
    end

    it '曜日別平均距離を正しく計算できる' do
      result = service.average_distance_by_weekday

      expect(result).to have_key(:day_names)
      expect(result).to have_key(:average_distances)
      expect(result[:day_names]).to eq(%w[日 月 火 水 木 金 土])
      expect(result[:average_distances].length).to eq(7)
    end
  end

  describe '時間帯別分析' do
    before do
      # 早朝 (4-8時)
      create(:walk, user: user, created_at: Time.current.change(hour: 6), walked_on: 1.day.ago)
      # 日中 (9-15時)
      create(:walk, user: user, created_at: Time.current.change(hour: 12), walked_on: 2.days.ago)
      create(:walk, user: user, created_at: Time.current.change(hour: 14), walked_on: 3.days.ago)
      # 夕方 (16-18時)
      create(:walk, user: user, created_at: Time.current.change(hour: 17), walked_on: 4.days.ago)
      # 夜間 (19-3時) - なし
    end

    it '時間帯別の散歩回数を正しく集計できる' do
      result = service.walks_count_by_time_of_day

      expect(result).to have_key(:labels)
      expect(result).to have_key(:data)
      expect(result[:labels]).to eq([ "早朝 (4-9時)", "日中 (9-16時)", "夕方 (16-19時)", "夜間 (19-4時)" ])

      # 早朝: 1, 日中: 2, 夕方: 1, 夜間: 0
      expect(result[:data]).to eq([ 1, 2, 1, 0 ])
    end
  end

  describe 'パフォーマンス分析' do
    before do
      create(:walk, user: user, walked_on: Date.current, distance: 5000, duration: 50)  # 5km、50分
      create(:walk, user: user, walked_on: 1.day.ago, distance: 3000, duration: 30)     # 3km、30分
    end

    it '平均ペースを正しく計算できる' do
      # 合計: 8km、80分 → 10分/km
      pace = service.average_pace
      expect(pace).to eq(10.0)
    end

    it 'ペース推移データを取得できる' do
      result = service.pace_trend_last_30_days

      expect(result).to have_key(:dates)
      expect(result).to have_key(:paces)
      expect(result[:dates].length).to eq(31)
      expect(result[:paces].length).to eq(31)
    end

    it 'カロリー推移データを取得できる' do
      result = service.calories_trend_last_30_days

      expect(result).to have_key(:dates)
      expect(result).to have_key(:calories)
      expect(result[:dates].length).to eq(31)
      expect(result[:calories].length).to eq(31)
    end
  end

  describe 'RPG要素' do
    describe '#level' do
      it '累計距離に応じてレベルが上昇する' do
        # Lv1: 0-9km
        create(:walk, user: user, distance: 5, walked_on: Date.current)
        expect(service.level).to eq(1)

        # Lv2: 10-29km
        create(:walk, user: user, distance: 5, walked_on: 1.day.ago) # 合計10km
        expect(service.level).to eq(2)

        # Lv3: 30-59km
        create(:walk, user: user, distance: 20, walked_on: 2.days.ago) # 合計30km
        expect(service.level).to eq(3)
      end
    end

    describe '#rank_name' do
      it 'レベルに応じたランク名を返す' do
        # Lv1
        create(:walk, user: user, distance: 5, walked_on: Date.current)
        expect(service.rank_name).to eq("散歩見習い")

        # Lv3
        create(:walk, user: user, distance: 25, walked_on: 1.day.ago) # 合計30km
        expect(service.rank_name).to eq("街の探索者")
      end
    end

    describe '#achievements' do
      it '条件を満たした称号が獲得済み(obtained: true)になる' do
        # 雨天強行軍の条件: 雨の日の記録(Post)があり、同日の散歩記録(Walk)がある
        post = create(:post, user: user, weather: :rainy, created_at: Time.current)
        create(:walk, user: user, walked_on: post.created_at.to_date)

        # 嵐を呼ぶ者の条件: 嵐の日の記録(Post)があり、同日の散歩記録(Walk)がある
        storm_post = create(:post, user: user, weather: :stormy, created_at: 1.day.ago)
        create(:walk, user: user, walked_on: storm_post.created_at.to_date)

        # 暁の冒険者の条件: 早朝(4-8時)の記録(Walk)がある
        # created_atを5時に設定 -> before_saveでtime_of_day: :early_morningになるはず
        create(:walk, user: user, created_at: Time.current.change(hour: 5), walked_on: 2.days.ago)

        # 太陽の申し子の条件: 日中(9-15時)の記録(Walk)がある
        create(:walk, user: user, created_at: Time.current.change(hour: 12), walked_on: 3.days.ago)

        # 不屈の精神の条件: ヘトヘト(exhausted)の投稿がある
        create(:post, user: user, feeling: :exhausted)

        achievements = service.achievements

        expect(achievements.find { |a| a[:id] == :rain_walker }[:obtained]).to be true
        expect(achievements.find { |a| a[:id] == :storm_walker }[:obtained]).to be true
        expect(achievements.find { |a| a[:id] == :early_bird }[:obtained]).to be true
        expect(achievements.find { |a| a[:id] == :sun_child }[:obtained]).to be true
        expect(achievements.find { |a| a[:id] == :indomitable }[:obtained]).to be true
      end

      it '条件を満たしていない称号は未獲得(obtained: false)になる' do
        # まだ記録がない状態
        achievements = service.achievements

        expect(achievements.find { |a| a[:id] == :rain_walker }[:obtained]).to be false
      end
    end
  end

  describe 'エッジケース' do
    it '記録が0件の場合、エラーにならない' do
      empty_user = create(:user)
      empty_service = StatsService.new(empty_user)

      expect(empty_service.total_distance).to eq(0)
      expect(empty_service.total_days).to eq(0)
      expect(empty_service.average_distance_per_day).to eq(0)
      expect(empty_service.max_distance).to eq(0)
      expect(empty_service.average_pace).to eq(0)
    end
  end
end
