require "net/http"
require "json"

# 天気情報を取得するサービスクラス
class WeatherService
  # OpenWeatherMapのAPIエンドポイント
  API_URL = "https://api.openweathermap.org/data/2.5/forecast"

  # 東京の緯度経度（デフォルト）
  DEFAULT_LAT = 35.6762
  DEFAULT_LON = 139.6503

  # 天気情報を取得するメソッド
  # lat: 緯度、lon: 経度（指定されない場合はデフォルト値を使用）
  def self.get_forecast(lat: DEFAULT_LAT, lon: DEFAULT_LON)
    # 環境変数からAPIキーを取得
    api_key = ENV["OPENWEATHER_API_KEY"]

    # APIキーが設定されていない場合はダミーデータを返す
    if api_key.blank?
      return dummy_data
    end

    begin
      # APIリクエストのURLを組み立てる
      url = "#{API_URL}?lat=#{lat}&lon=#{lon}&appid=#{api_key}&units=metric&lang=ja"
      uri = URI(url)

      # HTTPリクエストを送信
      response = Net::HTTP.get_response(uri)

      # レスポンスが成功した場合
      if response.is_a?(Net::HTTPSuccess)
        # JSONをパース
        data = JSON.parse(response.body)

        # 今日と明日の天気情報を抽出
        format_forecast(data)
      else
        # エラーが発生した場合はダミーデータを返す
        dummy_data
      end
    rescue => e
      # 例外が発生した場合もダミーデータを返す
      Rails.logger.error("天気情報の取得に失敗しました: #{e.message}")
      dummy_data
    end
  end

  private

  # APIレスポンスから必要な情報を抽出して整形するメソッド
  def self.format_forecast(data)
    forecasts = data["list"]

    # 今日の日付
    today = Date.current
    # 明日の日付
    tomorrow = today + 1

    # 今日の天気情報を取得（最初の予報データ）
    today_forecast = forecasts.first

    # 明日の天気情報を取得（日付が変わる最初のデータを探す）
    tomorrow_forecast = forecasts.find do |forecast|
      forecast_date = Time.zone.at(forecast["dt"]).to_date
      forecast_date == tomorrow
    end

    # 整形したデータを返す
    {
      today: {
        temp: today_forecast["main"]["temp"].round,
        description: today_forecast["weather"].first["description"],
        icon: weather_icon(today_forecast["weather"].first["main"])
      },
      tomorrow: tomorrow_forecast ? {
        temp: tomorrow_forecast["main"]["temp"].round,
        description: tomorrow_forecast["weather"].first["description"],
        icon: weather_icon(tomorrow_forecast["weather"].first["main"])
      } : nil
    }
  end

  # 天気の状態に応じたアイコン名を返すメソッド
  def self.weather_icon(weather_main)
    case weather_main
    when "Clear"
      "sunny"
    when "Clouds"
      "cloud"
    when "Rain", "Drizzle"
      "rainy"
    when "Thunderstorm"
      "thunderstorm"
    when "Snow"
      "ac_unit"
    when "Mist", "Fog"
      "mist"
    else
      "wb_cloudy"
    end
  end

  # ダミーデータを返すメソッド（APIキーが無い場合や、エラー時に使用）
  def self.dummy_data
    {
      today: {
        temp: 22,
        description: "\u6674\u308C",
        icon: "sunny"
      },
      tomorrow: {
        temp: 20,
        description: "\u66C7\u308A",
        icon: "cloud"
      }
    }
  end
end
