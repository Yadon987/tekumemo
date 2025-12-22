require "google/apis/fitness_v1"
require "signet/oauth_2/client"

class GoogleFitService
  def initialize(user)
    @user = user
    @client = Google::Apis::FitnessV1::FitnessService.new
    # ユーザーのアクセストークンを設定
    # Signetクライアントを作成して渡すのが確実
    auth = Signet::OAuth2::Client.new(access_token: user.google_token)
    @client.authorization = auth
  end

  # 指定期間の歩数と距離データを日別で取得する
  # @param start_date [Date] 開始日
  # @param end_date [Date] 終了日
  # @return [Hash] 日付(Date)をキー、データ(Hash)を値とするハッシュ
  #   例: { Date.new(2025, 12, 20) => { steps: 5000, distance: 3.5, calories: 150 } }
  def fetch_activities(start_date, end_date)
    # タイムゾーンを考慮して、開始日の00:00:00から終了日の23:59:59までのミリ秒を取得
    # Google Fit APIはナノ秒またはミリ秒での指定が必要
    # JSTの時間をUTCミリ秒に変換する必要があるが、to_i はUnix Time (UTC) を返すのでそのまま使える
    start_time_millis = start_date.beginning_of_day.to_i * 1000
    end_time_millis = end_date.end_of_day.to_i * 1000

    # 集計リクエストの作成
    aggregate_request = Google::Apis::FitnessV1::AggregateRequest.new(
      aggregate_by: [
        # 歩数
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.step_count.delta",
          data_source_id: "derived:com.google.step_count.delta:com.google.android.gms:estimated_steps"
        ),
        # 距離
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.distance.delta",
          data_source_id: "derived:com.google.distance.delta:com.google.android.gms:merge_distance_delta"
        ),
        # 消費カロリー
        Google::Apis::FitnessV1::AggregateBy.new(
          data_type_name: "com.google.calories.expended",
          data_source_id: "derived:com.google.calories.expended:com.google.android.gms:merge_calories_expended"
        )
      ],
      bucket_by_time: Google::Apis::FitnessV1::BucketByTime.new(duration_millis: 86400000), # 1日単位 (24時間)
      start_time_millis: start_time_millis,
      end_time_millis: end_time_millis
    )

    begin
      # APIリクエスト実行
      response = @client.aggregate_dataset("me", aggregate_request)

      result = {}

      response.bucket.each do |bucket|
        # バケットの開始時間を取得して日付に変換（JSTで扱う）
        bucket_start_time = Time.at(bucket.start_time_millis / 1000).in_time_zone.to_date

        steps = 0
        distance = 0.0
        calories = 0

        # datasetは aggregate_by で指定した順序で返ってくる
        # 0: 歩数, 1: 距離, 2: カロリー
        bucket.dataset.each_with_index do |dataset, index|
          dataset.point.each do |point|
            point.value.each do |value|
              case index
              when 0 # 歩数 (int_val)
                steps += value.int_val if value.int_val
              when 1 # 距離 (fp_val)
                distance += value.fp_val if value.fp_val
                # when 2 # カロリー (fp_val)
                #   calories += value.fp_val if value.fp_val
              end
            end
          end
        end

        # 距離をメートルからキロメートルに変換
        distance_km = (distance / 1000.0).round(2)

        # カロリー計算 (Google Fitの値は基礎代謝込みで大きすぎるため、距離ベースの概算値を使用)
        # 体重60kgと仮定: 距離(km) * 60 = 消費カロリー(kcal)
        calories = (distance_km * 60).to_i

        # データが存在する場合のみ結果に含める（0歩かつ0kmの場合はスキップでも良いが、呼び出し元で判断させるため一旦返す）
        result[bucket_start_time] = {
          steps: steps,
          distance: distance_km,
          calories: calories
        }
      end

      result

    rescue Google::Apis::ClientError, Google::Apis::ServerError => e
      Rails.logger.error "Google Fit API Error: #{e.message}"
      # エラー時は空ハッシュを返す
      {}
    end
  end
end
