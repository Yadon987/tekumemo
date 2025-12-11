# frozen_string_literal: true

# 統計データを集計するサービスクラス
# ユーザーの散歩記録から様々な統計情報を算出します
class StatsService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # ===== 基本統計カード用データ =====

  # 累計距離 (全期間)
  def total_distance
    user.walks.sum(:distance).to_f.round(2)
  end

  # 累計散歩日数
  def total_days
    user.walks.count
  end

  # 現在の連続記録日数 (Userモデルのメソッドを利用)
  def current_streak
    user.consecutive_walk_days
  end

  # 平均距離/日
  def average_distance_per_day
    return 0 if total_days.zero?
    (total_distance / total_days).round(2)
  end

  # 最長記録距離
  def max_distance
    user.walks.maximum(:distance)&.to_f&.round(2) || 0
  end

  # 今月の目標達成率 (%)
  def monthly_goal_achievement_rate
    monthly_distance_m = current_month_distance  # メートル単位
    target = user.target_distance * days_in_current_month  # メートル単位
    return 0 if target.zero?
    ((monthly_distance_m / target) * 100).round(1)
  end

  # 今月の歩いた距離（メートル単位）
  def current_month_distance
    user.walks
        .where(walked_on: Date.current.beginning_of_month..Date.current)
        .sum(:distance)
        .to_f
        .round(2)
  end

  # ===== 時系列グラフ用データ =====

  # 過去30日間の日別距離データ（今日を含めて31日分）
  # 返り値: { dates: [...], distances: [...] }
  def daily_distances_last_30_days
    start_date = 30.days.ago.to_date
    end_date = Date.current

    # 日付の配列を生成 (30日前〜今日 = 31日分)
    dates = (start_date..end_date).to_a

    # 散歩記録を一括取得してハッシュ化 (N+1対策)
    walks_by_date = user.walks
                        .where(walked_on: start_date..end_date)
                        .group(:walked_on)
                        .sum(:distance)

    # 各日付に対して距離を設定 (記録がない日は0)
    distances = dates.map { |date| walks_by_date[date]&.to_f&.round(2) || 0 }

    {
      dates: dates.map { |d| d.strftime("%m/%d") },  # "12/01" 形式
      distances: distances
    }
  end

  # 過去12週間の週別合計距離
  # 返り値: { weeks: [...], distances: [...] }
  def weekly_distances_last_12_weeks
    # 今週を含めて過去12週間分取得したい
    end_date = Date.current
    start_date = 11.weeks.ago.to_date.beginning_of_week # 11週間前 + 今週 = 12週間分

    # 週ごとにグループ化して合計
    # PostgreSQLのDATE_TRUNCはTime型を返すため、Date型に変換してハッシュ化
    raw_data = user.walks
               .where(walked_on: start_date..end_date)
               .group("DATE_TRUNC('week', walked_on)")
               .sum(:distance)

    data = raw_data.transform_keys { |k| k.to_date }

    # 週の配列を生成
    weeks = []
    current_week = start_date
    # 今週の月曜日までループ
    while current_week <= Date.current.beginning_of_week
      weeks << current_week
      current_week += 1.week
    end

    # 各週の距離を設定
    week_labels = weeks.map { |w| w.strftime("%m/%d") }
    distances = weeks.map do |week_start|
      data[week_start] || 0
    end

    {
      weeks: week_labels,
      distances: distances.map { |d| d.to_f.round(2) }
    }
  end

  # 過去12ヶ月の月別合計距離
  # 返り値: { months: [...], distances: [...] }
  def monthly_distances_last_12_months
    # 今月を含めて過去12ヶ月分
    end_date = Date.current.end_of_month
    start_date = 11.months.ago.to_date.beginning_of_month # to_dateを追加してDate型にする

    # 月ごとにグループ化して合計
    raw_data = user.walks
               .where(walked_on: start_date..end_date)
               .group("DATE_TRUNC('month', walked_on)")
               .sum(:distance)

    data = raw_data.transform_keys { |k| k.to_date }

    # 月の配列を生成
    months = []
    current_month = start_date
    # 今月の初日までループ
    while current_month <= Date.current.beginning_of_month
      months << current_month
      current_month += 1.month
    end

    # 各月の距離を設定
    month_labels = months.map { |m| m.strftime("%Y/%m") }
    distances = months.map do |month_start|
      data[month_start] || 0
    end

    {
      months: month_labels,
      distances: distances.map { |d| d.to_f.round(2) }
    }
  end

  # ===== 曜日別分析用データ =====

  # 曜日ごとの平均距離
  # 返り値: { day_names: [...], average_distances: [...] }
  def average_distance_by_weekday
    # PostgreSQLのEXTRACT(DOW FROM date)を使用 (0=日曜, 6=土曜)
    # 戻り値はFloatなのでIntegerに変換
    raw_data = user.walks
               .group("EXTRACT(DOW FROM walked_on)")
               .average(:distance)

    data = raw_data.transform_keys { |k| k.to_i }

    # 曜日ラベル (日曜始まり)
    day_names = %w[日 月 火 水 木 金 土]

    # 各曜日の平均距離を設定 (記録がない曜日は0)
    average_distances = (0..6).map do |dow|
      data[dow] || 0
    end

    {
      day_names: day_names,
      average_distances: average_distances.map { |d| d.to_f.round(2) }
    }
  end

  # ===== パフォーマンス分析用データ =====

  # 平均ペース (分/km)
  def average_pace
    # duration(分) / distance(km) = 分/km
    total_time = user.walks.sum(:duration).to_f  # 分
    total_dist_m = user.walks.sum(:distance).to_f  # メートル

    return 0 if total_dist_m.zero?

    # メートルをキロメートルに変換してから計算
    total_dist_km = total_dist_m / 1000.0
    (total_time / total_dist_km).round(2)
  end

  # 過去30日間の平均ペースの推移
  # 返り値: { dates: [...], paces: [...] }
  def pace_trend_last_30_days
    start_date = 30.days.ago.to_date
    end_date = Date.current

    dates = (start_date..end_date).to_a

    # 各日のペースを計算
    walks_by_date = user.walks
                        .where(walked_on: start_date..end_date)
                        .select(:walked_on, :distance, :duration)
                        .group_by(&:walked_on)

    paces = dates.map do |date|
      if walks_by_date[date]
        walk = walks_by_date[date].first  # 1日1記録の想定
        distance_m = walk.distance  # メートル
        distance_km = distance_m / 1000.0  # キロメートルに変換
        distance_km.zero? ? 0 : (walk.duration / distance_km).round(2)
      else
        0
      end
    end

    {
      dates: dates.map { |d| d.strftime("%m/%d") },
      paces: paces
    }
  end

  # 過去30日間のカロリー消費推移
  # 返り値: { dates: [...], calories: [...] }
  def calories_trend_last_30_days
    start_date = 30.days.ago.to_date
    end_date = Date.current

    dates = (start_date..end_date).to_a

    walks_by_date = user.walks
                        .where(walked_on: start_date..end_date)
                        .group(:walked_on)
                        .sum(:calories_burned)

    calories = dates.map { |date| walks_by_date[date] || 0 }

    {
      dates: dates.map { |d| d.strftime("%m/%d") },
      calories: calories
    }
  end

  private

  # 今月の日数
  def days_in_current_month
    Date.current.end_of_month.day
  end
end
