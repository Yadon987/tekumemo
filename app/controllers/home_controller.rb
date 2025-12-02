class HomeController < ApplicationController
  # ApplicationControllerで認証済みなので、ここでのbefore_actionは不要

  def index
    # ホーム画面の表示
    # 今後、ユーザーの散歩データなどを取得する処理を追加

    # ユーザーのIPアドレスを取得
    # プロキシ環境（Cloudflare等）では X-Forwarded-For ヘッダーの最初の値が実際のクライアントIP
    user_ip = GeolocationService.extract_ip(request)

    # デバッグ用：取得したIPアドレスをログに出力
    Rails.logger.info("========================================")
    Rails.logger.info("リクエストIP情報:")
    Rails.logger.info("  使用するIP: #{user_ip}")
    Rails.logger.info("  remote_ip: #{request.remote_ip}")
    Rails.logger.info("  ip: #{request.ip}")
    Rails.logger.info("  X-Forwarded-For: #{request.headers['X-Forwarded-For']}")
    Rails.logger.info("  X-Real-IP: #{request.headers['X-Real-IP']}")
    Rails.logger.info("========================================")

    # IP位置情報を取得
    location = GeolocationService.get_location(user_ip)

    # 位置情報の名前を設定
    @location_name = location[:city] || location[:region] || "不明な場所"

    # 天気情報を取得（位置情報を使用）
    @weather = WeatherService.get_forecast(
      lat: location[:latitude],
      lon: location[:longitude]
    )

    # 今日の散歩記録を取得
    @today_walk = current_user.walks.find_by(walked_on: Date.today)
  end
end
