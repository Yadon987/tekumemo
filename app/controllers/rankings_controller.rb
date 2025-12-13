class RankingsController < ApplicationController
  before_action :authenticate_user!

  def index
    # パラメータ取得
    @period = params[:period] || "monthly"

    # キャッシュキー生成（日付ごとに更新）
    cache_key = case @period
    when "daily"
                  "rankings_daily_#{Date.current}"
    when "monthly"
                  "rankings_monthly_#{Date.current.strftime('%Y-%m')}"
    when "all_time"
                  "rankings_all_time_#{Date.current}"
    else
                  "rankings_monthly_#{Date.current.strftime('%Y-%m')}"
    end

    # ランキング取得（1時間キャッシュ）
    fetch_rankings_for_period(@period)

    # 自分の順位と距離を特定
    if user_signed_in?
      find_my_rank
      calculate_my_distance

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
    #    注意: ユーザー数が数万規模になると maximum(:updated_at) 自体が重くなる可能性があるため、
    #          その場合はキャッシュ戦略の見直し（IDのみキャッシュして表示時にロードするなど）が必要。
    latest_update = User.maximum(:updated_at).to_i
    cache_key = "rankings_#{period}_#{Time.current.strftime('%Y%m%d%H')}_#{latest_update}"

    cached_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      {
        updated_at: Time.current,
        rankings: User.ranking(period: period).to_a
      }
    end

    @rankings = cached_data[:rankings]
    @last_data_updated_at = cached_data[:updated_at]
    # 次回キャッシュ更新時刻 = データ取得時刻の1時間後
    @next_cache_update_at = @last_data_updated_at + 1.hour
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
      when "daily" then Date.current
      when "monthly" then Date.current.beginning_of_month..Date.current
      when "yearly" then Date.current.beginning_of_year..Date.current
      else Date.current
      end

      @my_distance = current_user.walks.where(walked_on: range).sum(:distance) # walked_onカラムを使用
    end
  end
end
