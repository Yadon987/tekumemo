class RankingsController < ApplicationController
  # OGPメタタグ取得のため、ログインなしでもアクセス可能にする
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    # パラメータ取得
    @period = params[:period] || "weekly"

    # キャッシュキー生成（日付ごとに更新）
    cache_key = case @period
    when "weekly"
                  "rankings_weekly_#{Date.current.beginning_of_week}"
    when "monthly"
                  "rankings_monthly_#{Date.current.strftime('%Y-%m')}"
    when "all_time"
                  "rankings_all_time_#{Date.current}"
    else
                  "rankings_weekly_#{Date.current.beginning_of_week}"
    end

    # ランキング取得（1時間キャッシュ）
    fetch_rankings_for_period(@period)

    # 自分の順位と距離を特定
    if user_signed_in?
      find_my_rank
      calculate_my_distance

      # OGP画像の事前生成をキック（非同期）
      GenerateRankingOgpImageJob.perform_later(current_user)

      # 1位との差分を計算（自分が1位でない場合）
      if @my_rank && @my_rank > 1 && @rankings.present?
        top_distance = @rankings.first.total_distance
        @distance_to_top = top_distance - @my_distance
      else
        @distance_to_top = 0
      end
    end
  end

  private

  def fetch_rankings_for_period(period)
    # キャッシュキーの生成
    # 1. 期間 (period)
    # 2. 時間 (Time.current.hour): 1時間ごとに強制更新
    # 3. ユーザー更新 (User.maximum(:updated_at)): プロフィール変更（アバター等）を即時反映させるため
    # 4. 閲覧ユーザーの属性 (guest or general): ゲストと一般でランキング内容を変えるため
    latest_update = User.maximum(:updated_at).to_i
    viewer_role = current_user&.guest? ? "guest" : "general"
    cache_key = "rankings_#{period}_#{Time.current.strftime('%Y%m%d%H')}_#{latest_update}_#{viewer_role}"

    cached_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      {
        updated_at: Time.current,
        rankings: User.ranking_for(current_user, period: period).to_a
      }
    end

    @rankings = cached_data[:rankings]
    @last_data_updated_at = cached_data[:updated_at]
    # 次回キャッシュ更新時刻 = データ取得時刻の30分後
    @next_cache_update_at = @last_data_updated_at + 30.minutes
  end

  def find_my_rank
    # @rankingsの中から自分のIDを探す（キャッシュされた配列から探すので高速）
    user_in_ranking = @rankings.find { |user| user.id == current_user.id }

    if user_in_ranking
      # ランキング内にいれば、順位を計算（同順位対応）
      # 自分より距離が多い人の数 + 1
      my_dist = user_in_ranking.total_distance.to_f.round(2)
      higher_rankers = @rankings.count { |u| u.total_distance.to_f.round(2) > my_dist }
      @my_rank = higher_rankers + 1
    else
      # ランキング外の場合、DBから直接順位を計算するのは重いので、
      # ここでは「ランキング外」として扱う（nilのまま）
      # 必要であれば別途COUNTクエリを発行するが、今回はMVPなので省略
      @my_rank = nil
    end
  end

  def calculate_my_distance
    # ランキング内にいれば、その集計値を使う
    user_in_ranking = @rankings.find { |user| user.id == current_user.id }

    if user_in_ranking
      @my_distance = user_in_ranking.total_distance
    else
      # ランキング外の場合、個別に集計する
      range = case @period
      when "weekly" then Date.current.beginning_of_week..Date.current.end_of_week
      when "monthly" then Date.current.beginning_of_month..Date.current
      when "yearly" then Date.current.beginning_of_year..Date.current
      else Date.current.beginning_of_week..Date.current.end_of_week
      end

      @my_distance = current_user.walks.where(walked_on: range).sum(:distance) # walked_onカラムを使用
    end
  end
end
