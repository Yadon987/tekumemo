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
  #
  # 歩数ロジック:
  #   - 歩行(Walking)・ランニング(Running)セグメント内の歩数のみを取得
  #   - 車・電車移動中の振動による誤検知歩数を除外
  #   - 自転車の移動距離を歩数に換算して加算（距離÷4÷0.7m）
  def fetch_activities(start_date, end_date)
    return { data: fetch_dummy_activities(start_date, end_date) } if @user.guest?

    # タイムゾーンを考慮して、開始日の00:00:00から終了日の23:59:59までのミリ秒を取得
    start_time_millis = start_date.beginning_of_day.to_i * 1000
    end_time_millis = end_date.end_of_day.to_i * 1000

    begin
      # === アクティビティセグメントから歩数・距離・カロリー・時間を取得 ===
      # 歩行(7)、ランニング(8)、サイクリング(1)のみを対象とし、
      # 車・電車などの移動は除外される
      activity_data_by_date = fetch_activity_segment_data(start_time_millis, end_time_millis)

      # === 結果を作成 ===
      result = {}

      activity_data_by_date.each do |date, activity|
        # 歩行・ランニングセグメントの歩数 + サイクリングの換算歩数
        # 平均歩幅 0.7m で計算
        segment_steps = activity[:steps] || 0
        cycling_steps = (activity[:cycling_distance_m] / 0.7).round
        total_steps = segment_steps + cycling_steps

        # 時間計算: セグメント時間を直接使用（より正確）
        # 歩行・ランニングのセグメント時間 + サイクリング時間（1/2換算後）
        total_duration = activity[:walk_run_duration_min] + activity[:cycling_duration_min]

        result[date] = {
          steps: total_steps,
          distance: (activity[:distance_m] / 1000.0).round(2),
          calories: activity[:calories],
          duration: total_duration,
          start_time: activity[:start_time] || date.in_time_zone.change(hour: 8)
        }
      end

      { data: result }

    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "Google Fit Authorization Error for user #{@user.id}: #{e.message}"

      # 無効なトークンをクリアして次回の再認証を促す
      # update_columnsを使用してバリデーションとコールバックをスキップ
      @user.update_columns(
        google_token: nil,
        google_expires_at: nil
      )
      Rails.logger.info "Cleared invalid Google tokens for user #{@user.id}"

      { error: :auth_expired }
    rescue Google::Apis::ClientError => e
      if e.status_code == 401 || e.status_code == 403
        Rails.logger.error "Google Fit Auth Error (#{e.status_code}) for user #{@user.id}: #{e.message}"

        # 無効なトークンをクリアして次回の再認証を促す
        @user.update_columns(
          google_token: nil,
          google_expires_at: nil
        )
        Rails.logger.info "Cleared invalid Google tokens for user #{@user.id}"

        { error: :auth_expired }
      else
        Rails.logger.error "Google Fit Client Error for user #{@user.id}: #{e.message}"
        { error: :api_error, message: e.message }
      end
    rescue Google::Apis::ServerError => e
      Rails.logger.error "Google Fit Server Error for user #{@user.id}: #{e.message}"
      { error: :api_error, message: "Google Fitサーバーエラー" }
    rescue StandardError => e
      Rails.logger.error "Unexpected error in GoogleFitService for user #{@user.id}: #{e.class} - #{e.message}"

      # 予期しないエラーでもトークンをクリアして再認証を促す
      # 認証関連の問題の可能性があるため、安全のためクリアする
      @user.update_columns(
        google_token: nil,
        google_expires_at: nil
      )
      Rails.logger.info "Cleared Google tokens due to unexpected error for user #{@user.id}"

      { error: :auth_expired }
    end
  end

  private

  # アクティビティセグメントで歩数・距離・カロリー・時間を取得（電車・車を除外）
  # 歩行(7)・ランニング(8)・サイクリング(1)のみを対象とする
  def fetch_activity_segment_data(start_time_millis, end_time_millis)
    request = Google::Apis::FitnessV1::AggregateRequest.new(
      aggregate_by: [
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.step_count.delta"
        ),
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
    daily_stats = Hash.new { |h, k| h[k] = {
      steps: 0,                   # 歩行・ランニングセグメントの歩数
      distance_m: 0.0,
      calories: 0,
      walk_run_duration_min: 0,   # 歩行・ランニングのセグメント時間
      cycling_duration_min: 0,    # サイクリング時間（1/2換算後）
      cycling_distance_m: 0.0,    # サイクリング距離（1/4換算後、歩数推定用）
      max_calories: 0,
      start_time: nil
    } }

    response.bucket.each do |bucket|
      activity_type = bucket.activity

      # 歩行(7)、ランニング(8)、サイクリング(1)のみ対象
      next unless TARGET_ACTIVITY_TYPES.include?(activity_type)

      bucket_time = Time.at(bucket.start_time_millis / 1000).in_time_zone
      bucket_date = bucket_time.to_date

      duration_millis = bucket.end_time_millis - bucket.start_time_millis
      duration_min = (duration_millis / 1000.0 / 60.0).round

      steps, distance, calories = extract_data_from_bucket(bucket)

      # サイクリングの換算処理
      if activity_type == ACTIVITY_TYPE_BIKING
        # 距離データが空なら時間から推定（街乗り自転車の平均速度 15km/h）
        if distance == 0.0
          distance = (duration_min / 60.0) * 15 * 1000 # メートル単位
        end

        distance = distance / 4.0      # 距離1/4
        cycling_duration_min = (duration_min / 2.0).round  # 時間1/2
        daily_stats[bucket_date][:cycling_duration_min] += cycling_duration_min
        daily_stats[bucket_date][:cycling_distance_m] += distance  # 換算後距離を記録（歩数推定用）
        # サイクリング中の歩数は無視（ペダリングの誤検知の可能性）
      else
        # 歩行・ランニングの歩数と時間を加算
        daily_stats[bucket_date][:steps] += steps
        daily_stats[bucket_date][:walk_run_duration_min] += duration_min
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

  # バケットから歩数・距離・カロリーを抽出
  # aggregate_by の順序: step_count.delta, distance.delta, calories.expended
  def extract_data_from_bucket(bucket)
    steps = 0
    distance = 0.0
    calories = 0

    bucket.dataset.each_with_index do |dataset, index|
      dataset.point.each do |point|
        point.value.each do |value|
          case index
          when 0  # 歩数
            steps += value.int_val.to_i if value.int_val
          when 1  # 距離
            distance += value.fp_val.to_f if value.fp_val
          when 2  # カロリー
            calories += value.fp_val.to_i if value.fp_val
          end
        end
      end
    end

    [ steps, distance, calories ]
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
