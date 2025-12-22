class GoogleFitController < ApplicationController
  # ログインしていないユーザーはアクセスできないようにする
  before_action :authenticate_user!



  # Google Fitとの連携状態を確認する
  # GET /google_fit/status
  def status
    if current_user.google_token_valid?
      render json: {
        connected: true,
        email: current_user.email
      }
    else
      render json: {
        connected: false
      }
    end
  end

  # 指定した日のGoogle Fitデータを取得する
  # GET /google_fit/daily_data?date=YYYY-MM-DD
  def daily_data
    unless current_user.google_token_valid?
      render json: { error: "Google Fit not connected" }, status: :unauthorized
      return
    end

    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    service = GoogleFitService.new(current_user)

    # 指定日のデータを取得
    activities = service.fetch_activities(date, date)
    data = activities[date]

    if data
      # 時間の概算（時速4kmと仮定）: 距離(km) / 4(km/h) * 60(min)
      # 距離が0の場合は0
      duration = data[:distance] > 0 ? (data[:distance] / 4.0 * 60).round : 0

      render json: {
        date: date.to_s,
        steps: data[:steps],
        distance: data[:distance],
        calories: data[:calories],
        duration: duration,
        start_time: date.to_time.change(hour: 9) # デフォルトで朝9時とする（APIからは取れないため）
      }
    else
      render json: {
        date: date.to_s,
        steps: 0,
        distance: 0.0,
        calories: 0,
        duration: 0
      }
    end
  rescue => e
    Rails.logger.error "Google Fit API Error: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end
end
