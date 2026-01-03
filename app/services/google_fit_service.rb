require "google/apis/fitness_v1"
require "signet/oauth_2/client"

class GoogleFitService
  # Google Fit Activity Types
  ACTIVITY_TYPE_BIKING = 1
  ACTIVITY_TYPE_WALKING = 7
  ACTIVITY_TYPE_RUNNING = 8
  TARGET_ACTIVITY_TYPES = [ ACTIVITY_TYPE_BIKING, ACTIVITY_TYPE_WALKING, ACTIVITY_TYPE_RUNNING ].freeze

  def initialize(user)
    @user = user
    return if user.guest? # ゲストユーザーはAPIクライアント初期化不要

    @client = Google::Apis::FitnessV1::FitnessService.new
    auth = Signet::OAuth2::Client.new(access_token: user.google_token)
    @client.authorization = auth
  end

  # 指定期間の歩数と距離データを日別で取得する
  # @param start_date [Date] 開始日
  # @param end_date [Date] 終了日
  # @return [Hash] 日付(Date)をキー、データ(Hash)を値とするハッシュ
  #   例: { Date.new(2025, 12, 20) => { steps: 5000, distance: 3.5, calories: 150 } }
  def fetch_activities(start_date, end_date)
    return { data: fetch_dummy_activities(start_date, end_date) } if @user.guest?

    # タイムゾーンを考慮して、開始日の00:00:00から終了日の23:59:59までのミリ秒を取得
    start_time_millis = start_date.beginning_of_day.to_i * 1000
    end_time_millis = end_date.end_of_day.to_i * 1000

    begin
      # === 1. 歩数データを日次バケットで取得（全歩数を正確に取得） ===
      steps_by_date = fetch_daily_steps(start_time_millis, end_time_millis)

      # === 2. 距離・カロリー・アクティビティ時間はアクティビティセグメントから取得 ===
      activity_data_by_date = fetch_activity_segment_data(start_time_millis, end_time_millis)

      # === 3. マージして結果を作成 ===
      result = {}

      # 両方のデータソースの日付を統合
      all_dates = (steps_by_date.keys + activity_data_by_date.keys).uniq

      all_dates.each do |date|
        steps = steps_by_date[date] || 0
        activity = activity_data_by_date[date] || { distance_m: 0.0, calories: 0, activity_duration_min: 0, cycling_duration_min: 0, start_time: nil }

        # 時間計算: 歩行時間（歩数÷100） + サイクリング時間（1/2換算後）
        walk_duration = (steps / 100.0).round
        total_duration = walk_duration + activity[:cycling_duration_min]

        result[date] = {
          steps: steps,
          distance: (activity[:distance_m] / 1000.0).round(2),
          calories: activity[:calories],
          duration: total_duration,
          start_time: activity[:start_time] || date.in_time_zone.change(hour: 8)
        }
      end

      { data: result }

    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "Google Fit Authorization Error for user #{@user.id}: #{e.message}"
      { error: :auth_expired }
    rescue Google::Apis::ClientError => e
      if e.status_code == 401 || e.status_code == 403
        Rails.logger.error "Google Fit Auth Error (#{e.status_code}) for user #{@user.id}: #{e.message}"
        { error: :auth_expired }
      else
        Rails.logger.error "Google Fit Client Error for user #{@user.id}: #{e.message}"
        { error: :api_error, message: e.message }
      end
    rescue Google::Apis::ServerError => e
      Rails.logger.error "Google Fit Server Error for user #{@user.id}: #{e.message}"
      { error: :api_error, message: "Google Fitサーバーエラー" }
    rescue StandardError => e
      Rails.logger.error "Unexpected error in GoogleFitService for user #{@user.id}: #{e.message}"
      { error: :api_error, message: "予期しないエラー" }
    end
  end

  private

  # 日次バケットで歩数のみ取得（全歩数を漏れなく取得）
  def fetch_daily_steps(start_time_millis, end_time_millis)
    request = Google::Apis::FitnessV1::AggregateRequest.new(
      aggregate_by: [
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.step_count.delta"
        )
      ],
      bucket_by_time: Google::Apis::FitnessV1::BucketByTime.new(
        duration_millis: 86400000  # 24時間（ミリ秒）
      ),
      start_time_millis: start_time_millis,
      end_time_millis: end_time_millis
    )

    response = @client.aggregate_dataset("me", request)
    result = {}

    response.bucket.each do |bucket|
      date = Time.at(bucket.start_time_millis / 1000).in_time_zone.to_date
      steps = 0

      bucket.dataset.each do |dataset|
        dataset.point.each do |point|
          point.value.each do |value|
            steps += value.int_val.to_i if value.int_val
          end
        end
      end

      result[date] = steps if steps > 0
    end

    result
  end

  # アクティビティセグメントで距離・カロリー・時間を取得（電車・車を除外）
  def fetch_activity_segment_data(start_time_millis, end_time_millis)
    request = Google::Apis::FitnessV1::AggregateRequest.new(
      aggregate_by: [
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.distance.delta"
        ),
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.calories.expended"
        )
      ],
      bucket_by_activity_segment: Google::Apis::FitnessV1::BucketByActivity.new(
        min_duration_millis: 0
      ),
      start_time_millis: start_time_millis,
      end_time_millis: end_time_millis
    )

    response = @client.aggregate_dataset("me", request)
    daily_stats = Hash.new { |h, k| h[k] = { distance_m: 0.0, calories: 0, activity_duration_min: 0, cycling_duration_min: 0, max_calories: 0, start_time: nil } }

    response.bucket.each do |bucket|
      activity_type = bucket.activity

      # 歩行(7)、ランニング(8)、サイクリング(1)のみ対象
      next unless TARGET_ACTIVITY_TYPES.include?(activity_type)

      bucket_time = Time.at(bucket.start_time_millis / 1000).in_time_zone
      bucket_date = bucket_time.to_date

      duration_millis = bucket.end_time_millis - bucket.start_time_millis
      duration_min = (duration_millis / 1000.0 / 60.0).round

      distance, calories = extract_distance_and_calories_from_bucket(bucket)

      # サイクリングの換算処理
      if activity_type == ACTIVITY_TYPE_BIKING
        # 距離データが空なら時間から推定（街乗り自転車の平均速度 15km/h）
        if distance == 0.0
          distance = (duration_min / 60.0) * 15 * 1000 # メートル単位
        end

        distance = distance / 4.0      # 距離1/4
        cycling_duration_min = (duration_min / 2.0).round  # 時間1/2
        daily_stats[bucket_date][:cycling_duration_min] += cycling_duration_min
      else
        # 歩行・ランニングの時間はそのまま加算しない（歩数から推定するため）
      end

      # 日別に加算
      daily_stats[bucket_date][:distance_m] += distance
      daily_stats[bucket_date][:calories] += calories

      # 最大カロリーのセグメントの開始時刻を記録（時間帯判定用）
      if calories > daily_stats[bucket_date][:max_calories]
        daily_stats[bucket_date][:max_calories] = calories
        daily_stats[bucket_date][:start_time] = bucket_time
      end
    end

    daily_stats
  end

  # バケットから距離とカロリーを抽出
  def extract_distance_and_calories_from_bucket(bucket)
    distance = 0.0
    calories = 0

    bucket.dataset.each_with_index do |dataset, index|
      dataset.point.each do |point|
        point.value.each do |value|
          case index
          when 0  # 距離
            distance += value.fp_val.to_f if value.fp_val
          when 1  # カロリー
            calories += value.fp_val.to_i if value.fp_val
          end
        end
      end
    end

    [ distance, calories ]
  end

  # 管理者またはゲストユーザー用のダミーデータを生成する
  def fetch_dummy_activities(start_date, end_date)
    result = {}
    (start_date..end_date).each do |date|
      # ランダムな歩数など（デモ用に少し変動させる）
      # 土日は少し多めに
      base_steps = date.saturday? || date.sunday? ? 8000 : 5000
      steps = base_steps + rand(-1000..3000)

      # 距離 (歩数 * 0.7m 概算)
      distance_m = steps * 0.7
      distance_km = (distance_m / 1000.0).round(2)

      # カロリー (歩数 * 0.04kcal 概算)
      calories = (steps * 0.04).round

      # 時間 (歩数 / 100歩/分 概算)
      duration = (steps / 100.0).round

      result[date] = {
        steps: steps,
        distance: distance_km,
        calories: calories,
        duration: duration,
        start_time: date.in_time_zone.change(hour: 8, min: 0) # 毎朝8時開始とする
      }
    end
    result
  end
end
