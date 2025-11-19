class HomeController < ApplicationController
  # ApplicationControllerで認証済みなので、ここでのbefore_actionは不要

  def index
    # ホーム画面の表示
    # 今後、ユーザーの散歩データなどを取得する処理を追加

    # ユーザーのIPアドレスを取得
    user_ip = request.remote_ip

    # IP位置情報を取得
    location = GeolocationService.get_location(user_ip)

    # 位置情報の名前を設定
    @location_name = location[:city] || location[:region] || "不明な場所"

    # 天気情報を取得（位置情報を使用）
    @weather = WeatherService.get_forecast(
      lat: location[:latitude],
      lon: location[:longitude]
    )
  end
end
