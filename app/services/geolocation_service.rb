require "net/http"
require "json"

# IP位置情報を取得するサービスクラス
class GeolocationService
  # IPから位置情報を取得するAPI（無料で使えるip-api.com）
  # より正確で信頼性が高く、レート制限も緩い（45リクエスト/分）
  API_URL = "http://ip-api.com/json"

  # IPアドレスから位置情報を取得
  def self.get_location(ip_address)
    # ローカルホストやプライベートIPの場合はデフォルト（東京）を返す
    if local_ip?(ip_address)
      Rails.logger.info("ローカルIPアドレスを検出: #{ip_address}、デフォルト位置を使用")
      return default_location
    end

    begin
      # APIリクエスト（言語を日本語に設定）
      url = "#{API_URL}/#{ip_address}?lang=ja"
      uri = URI(url)

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        # APIのステータスを確認（"success" or "fail"）
        if data["status"] != "success"
          Rails.logger.warn("位置情報API エラー: #{data['message']} (IP: #{ip_address})")
          return default_location
        end

        # デバッグ用ログ
        Rails.logger.info("位置情報を取得: IP=#{ip_address}, City=#{data['city']}, Lat=#{data['lat']}, Lon=#{data['lon']}")

        {
          latitude: data["lat"],
          longitude: data["lon"],
          city: data["city"],
          region: data["regionName"],
          country: data["country"]
        }
      else
        Rails.logger.error("位置情報API HTTPエラー: #{response.code} (IP: #{ip_address})")
        default_location
      end
    rescue => e
      Rails.logger.error("位置情報の取得に失敗: #{e.message} (IP: #{ip_address})")
      default_location
    end
  end

  private

  # ローカルIPまたはプライベートIPかどうかを判定
  def self.local_ip?(ip)
    return true if ip.nil? || ip.blank?
    return true if ip == "127.0.0.1" || ip == "::1" || ip == "localhost"

    # プライベートIPアドレスの範囲
    private_ranges = [
      /^10\./,
      /^172\.(1[6-9]|2[0-9]|3[0-1])\./,
      /^192\.168\./
    ]

    private_ranges.any? { |range| ip.match?(range) }
  end

  # デフォルトの位置情報（東京）
  def self.default_location
    {
      latitude: 35.6762,
      longitude: 139.6503,
      city: "東京",
      region: "東京都",
      country: "日本"
    }
  end
end
