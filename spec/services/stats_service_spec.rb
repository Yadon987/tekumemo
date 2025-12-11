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
