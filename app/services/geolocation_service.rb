require "net/http"
require "json"

# IP位置情報を取得するサービスクラス
class GeolocationService
  # IPから位置情報を取得するAPI（無料で使えるipapi.co）
  API_URL = "https://ipapi.co"

  # IPアドレスから位置情報を取得
  def self.get_location(ip_address)
    # ローカルホストやプライベートIPの場合はデフォルト（東京）を返す
    if local_ip?(ip_address)
      return default_location
    end

    begin
      # APIリクエスト
      url = "#{API_URL}/#{ip_address}/json/"
      uri = URI(url)

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        # エラーがある場合はデフォルトを返す
        if data["error"]
          Rails.logger.warn("位置情報API エラー: #{data['reason']}")
          return default_location
        end

        {
          latitude: data["latitude"],
          longitude: data["longitude"],
          city: data["city"],
          region: data["region"],
          country: data["country_name"]
        }
      else
        default_location
      end
    rescue => e
      Rails.logger.error("位置情報の取得に失敗: #{e.message}")
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
