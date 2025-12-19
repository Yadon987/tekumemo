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
  # 今月の目標達成率 (%)
  def monthly_goal_achievement_rate
    monthly_distance_km = current_month_distance  # km単位
    target_m = user.target_distance * days_in_current_month  # m単位
    target_km = target_m / 1000.0 # km単位に変換

    return 0 if target_km.zero?
    ((monthly_distance_km / target_km) * 100).round(1)
  end

  # 今月の歩いた距離（km単位）
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
    total_dist_km = user.walks.sum(:distance).to_f / 1000.0 # kmに変換

    return 0 if total_dist_km.zero?

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
        distance_km = walk.distance.to_f  # km
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

  # ===== RPG / ゲーミフィケーション要素 =====

  # レベル計算
  # 累計距離に基づいてレベルを算出 (例: 10kmごとにレベルアップなど、累進的に設定)
  def level
    total_dist = total_distance
    # レベル閾値の定義 (累計km)
    # Lv1: 0, Lv2: 10, Lv3: 30, Lv4: 60, Lv5: 100, Lv6: 150...
    # 簡易計算式: レベル = 1 + √(累計距離) のようなカーブも良いが、
    # ここでは明確なマイルストーンを設定
    case total_dist
    when 0...10 then 1
    when 10...30 then 2
    when 30...60 then 3
    when 60...100 then 4
    when 100...150 then 5
    when 150...220 then 6
    when 220...300 then 7
    when 300...400 then 8
    when 400...550 then 9
    else 10 + ((total_dist - 550) / 200).to_i # Lv10以降は200kmごとにレベルアップ
    end
  end

  # ランク名 (称号)
  def rank_name
    case level
    when 1 then "散歩見習い"
    when 2 then "駆け出しウォーカー"
    when 3 then "街の探索者"
    when 4 then "路地裏の住人"
    when 5 then "健脚の冒険家"
    when 6 then "ストリートランナー"
    when 7 then "都市の遊撃手"
    when 8 then "風の旅人"
    when 9 then "レジェンドウォーカー"
    else "散歩の神"
    end
  end

  # 次のレベルまでの残り距離 (Next XP)
  def distance_to_next_level
    total_dist = total_distance
    next_threshold = case level
                     when 1 then 10
                     when 2 then 30
                     when 3 then 60
                     when 4 then 100
                     when 5 then 150
                     when 6 then 220
                     when 7 then 300
                     when 8 then 400
                     when 9 then 550
                     else 550 + ((level - 9) * 200)
                     end
    (next_threshold - total_dist).round(2)
  end

  # 現在のレベルの進行度 (%)
  def level_progress_percentage
    total_dist = total_distance
    current_level_start = case level
                          when 1 then 0
                          when 2 then 10
                          when 3 then 30
                          when 4 then 60
                          when 5 then 100
                          when 6 then 150
                          when 7 then 220
                          when 8 then 300
                          when 9 then 400
                          else 550 + ((level - 10) * 200)
                          end

    next_level_start = case level
                       when 1 then 10
                       when 2 then 30
                       when 3 then 60
                       when 4 then 100
                       when 5 then 150
                       when 6 then 220
                       when 7 then 300
                       when 8 then 400
                       when 9 then 550
                       else 550 + ((level - 9) * 200)
                       end

    range = next_level_start - current_level_start
    current_pos = total_dist - current_level_start

    return 0 if range.zero?
    ((current_pos / range) * 100).clamp(0, 100).round(1)
  end

  # 獲得済み称号 (Achievements) リスト
  # 返り値: [{ id: :rain_walker, name: "雨天決行", description: "...", icon: "...", obtained: true/false }, ...]
  def achievements
    walks = user.walks
    posts = user.posts

    list = [
      # --- 基本 ---
      {
        id: :first_step,
        name: "冒険の始まり",
        description: "初めて散歩を記録した",
        icon: "footprint",
        condition: -> { walks.exists? }
      },
      {
        id: :three_day_streak,
        name: "三日坊主卒業",
        description: "3日連続で歩いた",
        icon: "looks_3",
        condition: -> { current_streak >= 3 }
      },
      {
        id: :seven_day_streak,
        name: "一週間の奇跡",
        description: "7日連続で歩いた",
        icon: "looks_one",
        condition: -> { current_streak >= 7 }
      },
      {
        id: :thirty_day_streak,
        name: "継続の達人",
        description: "30日連続で歩いた",
        icon: "calendar_month",
        condition: -> { current_streak >= 30 }
      },

      # --- 天候・環境 ---
      {
        id: :rain_walker,
        name: "雨天強行軍",
        description: "雨の日に散歩に出かけた",
        icon: "rainy",
        condition: -> {
          posts.where(weather: :rainy).any? do |post|
            walks.where(walked_on: post.created_at.to_date).exists?
          end
        }
      },
      {
        id: :storm_walker,
        name: "嵐を呼ぶ者 (Storm Bringer)",
        description: "嵐の中でも歩みを止めなかった",
        icon: "thunderstorm",
        condition: -> {
          posts.where(weather: :stormy).any? do |post|
            walks.where(walked_on: post.created_at.to_date).exists?
          end
        }
      },

      # --- 時間帯 ---
      {
        id: :early_bird,
        name: "暁の冒険者",
        description: "早朝(4:00〜8:59)に歩いた",
        icon: "wb_twilight",
        condition: -> {
          walks.where(time_of_day: :early_morning).exists?
        }
      },
      {
        id: :sun_child,
        name: "太陽の申し子",
        description: "日中(9:00〜15:59)に歩いた",
        icon: "sunny",
        condition: -> {
          walks.where(time_of_day: :day).exists?
        }
      },
      {
        id: :twilight_traveler,
        name: "黄昏の旅人",
        description: "夕方(16:00〜18:59)に歩いた",
        icon: "wb_horizon",
        condition: -> {
          walks.where(time_of_day: :evening).exists?
        }
      },
      {
        id: :night_owl,
        name: "月下の徘徊者 (Moon Walker)",
        description: "夜間(19:00〜3:59)に歩いた",
        icon: "dark_mode",
        condition: -> {
          walks.where(time_of_day: :night).exists?
        }
      },

      # --- 距離・強度 ---
      {
        id: :long_distance,
        name: "限界突破 (Limit Break)",
        description: "1回の散歩で10km以上歩いた",
        icon: "hiking",
        condition: -> { walks.where("distance >= ?", 10).exists? }
      },
      {
        id: :marathon,
        name: "マラソン完走",
        description: "累計距離が42.195kmを超えた",
        icon: "sports_score",
        condition: -> { total_distance >= 42.195 }
      },
      {
        id: :weekend_warrior,
        name: "週末の英雄 (Weekend Hero)",
        description: "土日で合計20km以上歩いた",
        icon: "event_available",
        condition: -> {
          # 土曜日(6)または日曜日(0)の記録を抽出し、合計距離を計算
          # PostgreSQLのDOW (Day Of Week): 日曜=0, 月曜=1, ..., 土曜=6
          walks.where("EXTRACT(DOW FROM walked_on) IN (0, 6)").sum(:distance) >= 20
        }
      },

      # --- ソーシャル・メンタル ---
      {
        id: :bard,
        name: "吟遊詩人",
        description: "散歩の記録(投稿)を50回以上行った",
        icon: "history_edu",
        condition: -> { posts.count >= 50 }
      },
      {
        id: :popular,
        name: "街の人気者",
        description: "投稿へのリアクションを合計100回もらった",
        icon: "favorite",
        condition: -> {
          # ReactionモデルがPostに紐付いていると仮定
          Reaction.where(post_id: posts.select(:id)).count >= 100
        }
      },
      {
        id: :indomitable,
        name: "不屈の精神",
        description: "「ヘトヘト」な気分でも歩いた",
        icon: "fitness_center",
        condition: -> { posts.where(feeling: :exhausted).exists? }
      }
    ]

    list.map do |item|
      item.merge(obtained: item[:condition].call)
    end
  end

  private

  # 今月の日数
  def days_in_current_month
    Date.current.end_of_month.day
  end
end
