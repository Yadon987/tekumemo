# IP位置情報を取得するサービスクラス
# geocoder gem を使用してより正確な位置情報を取得
class GeolocationService
  # IPアドレスから位置情報を取得
  def self.get_location(ip_address)
    # ローカルホストやプライベートIPの場合はデフォルト（東京）を返す
    if local_ip?(ip_address)
      Rails.logger.info("ローカルIPアドレスを検出: #{ip_address}、デフォルト位置を使用")
      return default_location
    end

    begin
      # geocoder gem を使用してIP位置情報を取得
      # 複数のプロバイダーをフォールバックで試行
      results = Geocoder.search(ip_address)

      if results.present? && results.first
        result = results.first

        # デバッグ用ログ
        Rails.logger.info("========================================")
        Rails.logger.info("Geocoder で位置情報を取得:")
        Rails.logger.info("  IP: #{ip_address}")
        Rails.logger.info("  City: #{result.city}")
        Rails.logger.info("  Region: #{result.state}")
        Rails.logger.info("  Country: #{result.country}")
        Rails.logger.info("  Latitude: #{result.latitude}")
        Rails.logger.info("  Longitude: #{result.longitude}")
        Rails.logger.info("========================================")

        {
          latitude: result.latitude || default_location[:latitude],
          longitude: result.longitude || default_location[:longitude],
          city: result.city || default_location[:city],
          region: result.state || default_location[:region],
          country: result.country || default_location[:country]
        }
      else
        Rails.logger.warn("位置情報が取得できませんでした (IP: #{ip_address})")
        default_location
      end
    rescue => e
      Rails.logger.error("位置情報の取得に失敗: #{e.message} (IP: #{ip_address})")
      Rails.logger.error(e.backtrace.join("\n"))
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
