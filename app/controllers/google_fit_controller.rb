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
    # fetch_activitiesは { data: { Date => {...} } } または { error: ... } を返す
    result = service.fetch_activities(date, date)

    # エラーチェック
    if result[:error]
      case result[:error]
      when :auth_expired
        render json: { error: "Google Fit authentication expired" }, status: :unauthorized
      else
        render json: { error: result[:message] || "API error" }, status: :internal_server_error
      end
      return
    end

    data = result[:data]&.dig(date)

    if data
      render json: {
        date: date.to_s,
        steps: data[:steps],
        distance: data[:distance],
        calories: data[:calories],
        duration: data[:duration] || 0,
        start_time: data[:start_time]&.iso8601 || date.to_time.change(hour: 9).iso8601
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
