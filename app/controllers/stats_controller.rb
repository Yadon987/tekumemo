# frozen_string_literal: true

# 統計・分析ページのコントローラー
class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    # StatsServiceインスタンスを作成
    @stats_service = StatsService.new(current_user)

    # 基本統計データ
    @total_distance = @stats_service.total_distance
    @total_days = @stats_service.total_days
    @current_streak = @stats_service.current_streak
    @average_distance = @stats_service.average_distance_per_day
    @max_distance = @stats_service.max_distance
    @monthly_goal_rate = @stats_service.monthly_goal_achievement_rate
  end

  # グラフデータをJSON形式で返すAPI
  # Stimulusコントローラーから非同期で呼び出される
  def chart_data
    stats_service = StatsService.new(current_user)
    chart_type = params[:type]

    # パラメータのホワイトリスト検証
    allowed_types = %w[daily weekly monthly weekday pace calories time_of_day]
    unless allowed_types.include?(chart_type)
      render json: { error: "Invalid chart type. Allowed types: #{allowed_types.join(', ')}" }, status: :bad_request
      return
    end

    data = case chart_type
    when "daily"
      stats_service.daily_distances_last_30_days
    when "weekly"
      stats_service.weekly_distances_last_12_weeks
    when "monthly"
      stats_service.monthly_distances_last_12_months
    when "weekday"
      stats_service.average_distance_by_weekday
    when "pace"
      stats_service.pace_trend_last_30_days
    when "calories"
      stats_service.calories_trend_last_30_days
    when "time_of_day"
      stats_service.walks_count_by_time_of_day
    end

    render json: data
  rescue StandardError => e
    # 予期せぬエラーをログに記録し、500エラーを返す
    Rails.logger.error("StatsController#chart_data error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { error: "Internal server error" }, status: :internal_server_error
  end
end
