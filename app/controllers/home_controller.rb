class HomeController < ApplicationController
  # ApplicationControllerで認証済みなので、ここでのbefore_actionは不要

  def index
    # ホーム画面の表示
    # 今後、ユーザーの散歩データなどを取得する処理を追加

    # ユーザーのIPアドレスを取得
    # プロキシ環境（Cloudflare等）では X-Forwarded-For ヘッダーの最初の値が実際のクライアントIP
    user_ip = GeolocationService.extract_ip(request)

    # デバッグ用：取得したIPアドレスをログに出力（本番環境では出力しない）
    Rails.logger.debug("========================================")
    Rails.logger.debug("リクエストIP情報:")
    Rails.logger.debug("  使用するIP: #{user_ip}")
    Rails.logger.debug("  remote_ip: #{request.remote_ip}")
    Rails.logger.debug("  ip: #{request.ip}")
    Rails.logger.debug("  X-Forwarded-For: #{request.headers['X-Forwarded-For']}")
    Rails.logger.debug("  X-Real-IP: #{request.headers['X-Real-IP']}")
    Rails.logger.debug("========================================")

    # IP位置情報を取得
    @location = GeolocationService.get_location(user_ip)

    # 位置情報の名前を設定
    @location_name = @location[:city] || @location[:region] || "不明な場所"

    # 天気情報を取得（位置情報を使用）
    # 外部APIへのリクエストを減らすため、1時間キャッシュする
    # キーには緯度経度を含める（場所が変われば再取得）
    weather_cache_key = "weather_cache_#{@location[:latitude]}_#{@location[:longitude]}"
    @weather = Rails.cache.fetch(weather_cache_key, expires_in: 1.hour) do
      WeatherService.get_forecast(
        lat: @location[:latitude],
        lon: @location[:longitude]
      )
    end

    # 今日の散歩記録を取得
    @today_walk = current_user.walks.find_by(walked_on: Date.current)

    # 最新の投稿を取得
    @latest_post = Post.with_associations.recent.first

    # 最新のお知らせを取得（公開中かつ有効期限内、最新3件）
    @announcements = Announcement.active.recent.limit(3)

    # ===== 月間ランキング情報の取得 =====
    # キャッシュキー: ユーザーIDと日付（月）ベース
    # ユーザー体験向上のため、15分ごとに更新する（モチベーション維持）
    # Time.current.to_i / 15.minutes.to_i で15分ごとのタイムスタンプを生成
    cache_timestamp = Time.current.to_i / 15.minutes.to_i
    cache_key = "ranking/monthly/#{current_user.id}/#{Date.current.strftime('%Y-%m')}/#{cache_timestamp}"

    ranking_data = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
      start_date = Date.current.beginning_of_month
      end_date = Date.current

      # 1. 自分の今月の総距離
      my_total_distance = current_user.walks.where(walked_on: start_date..end_date).sum(:distance)

      # 2. 全ユーザー数（歩いていないユーザーも含む）
      total_users = User.count

      # 3. 自分の順位（自分より多く歩いている人数 + 1）
      #    SQL最適化: to_a.size でメモリ展開せず、サブクエリを使ってDB側でカウントする
      #    小数点以下の誤差対策: ROUND関数で小数点第2位までで比較する
      higher_rankers_query = User.joins(:walks)
                                 .where(walks: { walked_on: start_date..end_date })
                                 .group(:id)
                                 .having("ROUND(SUM(walks.distance), 2) > ?", my_total_distance.round(2))
                                 .select(:id) # SELECT句を最小限に

      # User.from を使ってサブクエリの結果セットの行数をカウント
      higher_rankers_count = User.from(higher_rankers_query, :users).count

      my_rank = higher_rankers_count + 1

      # 4. 上位何%か
      percentile = if total_users > 0
                     ((my_rank.to_f / total_users) * 100).ceil
      else
                     0
      end

      {
        rank: my_rank,
        total_users: total_users,
        percentile: percentile
      }
    end

    @my_rank = ranking_data[:rank]
    @ranking_total_users = ranking_data[:total_users]
    @ranking_percentile = ranking_data[:percentile]
  end
end
