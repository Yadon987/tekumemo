# Google Fit APIからデータを取得するサービスクラス
# ユーザーの散歩データ（歩数、距離、時間、カロリー）を取得する
class GoogleFitService
  require "google/apis/fitness_v1"

  # 初期化: ユーザー情報を受け取り、Google Fit APIクライアントをセットアップする
  def initialize(user)
    @user = user
    @service = Google::Apis::FitnessV1::FitnessService.new
    @service.authorization = authorize_user
  end

  # 指定した日付の散歩データを取得する
  # @param date [Date] 取得したい日付
  # @return [Hash] 歩数、距離、時間、カロリーのデータ
  def fetch_daily_data(date)
    # 指定日の開始時刻と終了時刻をミリ秒単位で取得
    start_time_millis = date.beginning_of_day.to_i * 1000
    end_time_millis = date.end_of_day.to_i * 1000

    # 各データを取得
    {
      steps: fetch_steps(start_time_millis, end_time_millis),
      distance: fetch_distance(start_time_millis, end_time_millis),
      duration: fetch_duration(start_time_millis, end_time_millis),
      calories: fetch_calories(start_time_millis, end_time_millis)
    }
  rescue Google::Apis::Error => e
    # APIエラーが発生した場合は、エラーメッセージをログに記録してnilを返す
    Rails.logger.error "Google Fit API error: #{e.message}"
    nil
  end

  private

  # ユーザーの認証情報を使ってGoogle APIを認証する
  def authorize_user
    return nil unless @user.google_token_valid?

    # Signetsegを使ってアクセストークンを設定
    auth = Signet::OAuth2::Client.new(
      token_credential_uri: "https://oauth2.googleapis.com/token",
      client_id: ENV.fetch("GOOGLE_CLIENT_ID", nil),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET", nil),
      refresh_token: @user.google_refresh_token,
      access_token: @user.google_token
    )

    # トークンが期限切れの場合は更新
    if @user.google_expires_at < Time.current
      auth.refresh!
      @user.update(
        google_token: auth.access_token,
        google_expires_at: Time.at(auth.expires_at)
      )
    end

    auth
  end

  # 歩数データを取得
  def fetch_steps(start_time, end_time)
    dataset_id = "#{start_time}000000-#{end_time}000000"
    data_source = "derived:com.google.step_count.delta:com.google.android.gms:estimated_steps"

    dataset = @service.get_user_data_source_dataset(
      "me",
      data_source,
      dataset_id
    )

    # データポイントから歩数を合計
    total_steps = 0
    (dataset.point || []).each do |point|
      point.value.each do |value|
        total_steps += value.int_val if value.int_val
      end
    end

    total_steps
  rescue => e
    Rails.logger.error "Steps fetch error: #{e.message}"
    0
  end

  # 距離データを取得（メートル単位をキロメートルに変換）
  def fetch_distance(start_time, end_time)
    dataset_id = "#{start_time}000000-#{end_time}000000"
    data_source = "derived:com.google.distance.delta:com.google.android.gms:merge_distance_delta"

    dataset = @service.get_user_data_source_dataset(
      "me",
      data_source,
      dataset_id
    )

    # データポイントから距離を合計（メートル → キロメートル）
    total_distance = 0.0
    (dataset.point || []).each do |point|
      point.value.each do |value|
        total_distance += value.fp_val if value.fp_val
      end
    end

    (total_distance / 1000.0).round(2) # メートルをキロメートルに変換
  rescue => e
    Rails.logger.error "Distance fetch error: #{e.message}"
    0.0
  end

  # 活動時間を取得（ミリ秒単位を分に変換）
  def fetch_duration(start_time, end_time)
    dataset_id = "#{start_time}000000-#{end_time}000000"
    data_source = "derived:com.google.active_minutes:com.google.android.gms:merge_active_minutes"

    dataset = @service.get_user_data_source_dataset(
      "me",
      data_source,
      dataset_id
    )

    # データポイントから時間を合計（分）
    total_minutes = 0
    dataset.point.each do |point|
      point.value.each do |value|
        total_minutes += value.int_val if value.int_val
      end
    end

    total_minutes
  rescue => e
    Rails.logger.error "Duration fetch error: #{e.message}"
    0
  end

  # 消費カロリーを取得（運動によるもののみ抽出）
  def fetch_calories(start_time, end_time)
    # アクティビティ別に集計するリクエストを作成
    aggregate_request = Google::Apis::FitnessV1::AggregateRequest.new(
      aggregate_by: [
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.calories.expended",
          data_source_id: "derived:com.google.calories.expended:com.google.android.gms:merge_calories_expended"
        )
      ],
      bucket_by_activity_type: Google::Apis::FitnessV1::BucketByActivity.new(
        min_duration_millis: 0
      ),
      start_time_millis: start_time,
      end_time_millis: end_time
    )

    # APIをコールして集計データを取得
    response = @service.aggregate_dataset("me", aggregate_request)

    total_calories = 0.0

    # 除外するアクティビティID（基礎代謝や非運動）
    # 0: In Vehicle (車)
    # 3: Still (静止)
    # 4: Unknown (不明 - 多くの場合、何もしていない時間)
    # 5: Tilting (端末の傾き - 通常は無視)
    # 72: Sleep (睡眠)
    excluded_activities = [ 0, 3, 4, 5, 72 ]

    response.bucket.each do |bucket|
      activity_id = bucket.activity

      # 除外対象のアクティビティでなければ加算
      unless excluded_activities.include?(activity_id)
        bucket.dataset.each do |dataset|
          dataset.point.each do |point|
            point.value.each do |value|
              total_calories += value.fp_val if value.fp_val
            end
          end
        end
      end
    end

    total_calories.round(0)
  rescue => e
    Rails.logger.error "Calories fetch error: #{e.message}"
    0
  end
end
