# Geocoder の設定
Geocoder.configure(
  # タイムアウト設定（秒）
  timeout: 5,

  # IP位置情報のルックアップサービスを設定
  # 優先順位順に複数のサービスを設定可能
  ip_lookup: :ipapi_com,

  # キャッシュ設定（Railsのキャッシュストアを使用）
  cache: Rails.cache,
  cache_prefix: "geocoder:",

  # 言語設定
  language: :ja,

  # 単位（距離計算用）
  units: :km,

  # ログレベル
  logger: Rails.logger,

  # 各サービスごとの設定
  ipapi_com: {
    # ip-api.com は無料で利用可能
    # レート制限: 45リクエスト/分
  }

  # フォールバック用に別のサービスも設定可能
  # 例: ipinfo_io, ipstack, maxmind など
  # ipinfo_io: {
  #   api_key: ENV["IPINFO_IO_API_KEY"]
  # }
)
