class HomeController < ApplicationController
  # ApplicationControllerで認証済みなので、ここでのbefore_actionは不要

  def index
    # ホーム画面の表示
    # 今後、ユーザーの散歩データなどを取得する処理を追加

    # 天気情報を取得
    @weather = WeatherService.get_forecast
  end
end
