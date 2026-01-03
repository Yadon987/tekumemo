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
    return if user.admin? # 管理者はAPIクライアント初期化不要

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
    return { data: fetch_dummy_activities(start_date, end_date) } if @user.admin?

    # タイムゾーンを考慮して、開始日の00:00:00から終了日の23:59:59までのミリ秒を取得
    start_time_millis = start_date.beginning_of_day.to_i * 1000
    end_time_millis = end_date.end_of_day.to_i * 1000

    # 集計リクエストの作成
    aggregate_request = Google::Apis::FitnessV1::AggregateRequest.new(
      aggregate_by: [
        # 歩数
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.step_count.delta"
        ),
        # 距離
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.distance.delta"
        ),
        # カロリー（アクティビティ別に取得）
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.calories.expended"
        )
      ],
      # アクティビティセグメントごとに集計（徒歩、自転車などを区別するため）
      bucket_by_activity_segment: Google::Apis::FitnessV1::BucketByActivity.new(
        min_duration_millis: 0 # 短いアクティビティも含める
      ),
      start_time_millis: start_time_millis,
      end_time_millis: end_time_millis
    )

    begin
      # APIリクエスト実行
      response = @client.aggregate_dataset("me", aggregate_request)

      # 日別集計用ハッシュ (初期値0)
      daily_stats = Hash.new { |h, k| h[k] = { steps: 0, distance_m: 0.0, duration_min: 0, calories: 0, max_calories: 0, start_time: nil } }

      response.bucket.each do |bucket|
        # アクティビティタイプを取得 (int)
        activity_type = bucket.activity

        # 対象のアクティビティ以外はスキップ
        next unless TARGET_ACTIVITY_TYPES.include?(activity_type)

        # バケットの開始時間を取得して日付に変換（JSTで扱う）
        bucket_time = Time.at(bucket.start_time_millis / 1000).in_time_zone
        bucket_date = bucket_time.to_date

        # セグメントの継続時間を計算（ミリ秒 → 分）
        duration_millis = bucket.end_time_millis - bucket.start_time_millis
        duration_min = (duration_millis / 1000.0 / 60.0).round

        # データセットから値を抽出
        steps, distance, calories = extract_data_from_bucket(bucket)

        # サイクリングの換算処理などを適用
        steps, distance, duration_min = apply_activity_conversion(activity_type, steps, distance, duration_min)

        # 日別ハッシュに加算
        daily_stats[bucket_date][:steps] += steps
        daily_stats[bucket_date][:distance_m] += distance
        daily_stats[bucket_date][:duration_min] += duration_min
        daily_stats[bucket_date][:calories] += calories

        # このセグメントのカロリーが最大なら、開始時刻を記録（時間帯判定用）
        if calories > daily_stats[bucket_date][:max_calories]
          daily_stats[bucket_date][:max_calories] = calories
          daily_stats[bucket_date][:start_time] = bucket_time
        end
      end

      # 結果の整形（メートル→キロメートル）
      result = {}
      daily_stats.each do |date, stats|
        distance_km = (stats[:distance_m] / 1000.0).round(2)

        result[date] = {
          steps: stats[:steps],
          distance: distance_km,
          calories: stats[:calories],
          duration: stats[:duration_min],
          start_time: stats[:start_time]
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

  # 管理者ユーザー用のダミーデータを生成する
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

  # バケットから歩数、距離、カロリーを抽出
  def extract_data_from_bucket(bucket)
    steps = 0
    distance = 0.0
    calories = 0

    bucket.dataset.each_with_index do |dataset, index|
      dataset.point.each do |point|
        point.value.each do |value|
          case index
          when 0 # 歩数
            steps += value.int_val if value.int_val
          when 1 # 距離
            distance += value.fp_val if value.fp_val
          when 2 # カロリー
            calories += value.fp_val.to_i if value.fp_val
          end
        end
      end
    end

    [ steps, distance, calories ]
  end

  # アクティビティタイプに応じた換算処理
  def apply_activity_conversion(activity_type, steps, distance, duration_min)
    # 自転車の場合、距離データが空なら時間から推定
    # 街乗り自転車の平均速度 15km/h と仮定
    if activity_type == ACTIVITY_TYPE_BIKING && distance == 0.0
      distance = (duration_min / 60.0) * 15 * 1000 # メートル単位
    end

    # 自転車の場合は距離・時間を換算し、歩数を距離から逆算
    if activity_type == ACTIVITY_TYPE_BIKING
      distance = distance / 4.0  # 距離は1/4に換算
      duration_min = (duration_min / 2.0).round  # 時間は1/2に換算（METs基準）
      # 歩数を距離から逆算 (1km = 約1300歩)
      steps = ((distance / 1000.0) * 1300).round
    end

    [ steps, distance, duration_min ]
  end
end
