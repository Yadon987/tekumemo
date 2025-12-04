class RankingsController < ApplicationController
  before_action :authenticate_user!

  def index
    # パラメータ取得
    @period = params[:period] || "monthly"

    # キャッシュキー生成（日付ごとに更新）
    cache_key = case @period
    when "daily"
                  "rankings_daily_#{Date.today}"
    when "monthly"
                  "rankings_monthly_#{Date.today.strftime('%Y-%m')}"
    when "all_time"
                  "rankings_all_time_#{Date.today}"
    else
                  "rankings_monthly_#{Date.today.strftime('%Y-%m')}"
    end

    # ランキング取得（1時間キャッシュ）
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
    # キャッシュキーの生成（期間と現在の時間に基づいて1時間ごとに更新）
    # Time.current.hour をキーに含めることで、毎時0分にキャッシュが無効化される
    cache_key = "rankings_#{period}_#{Time.current.strftime('%Y%m%d%H')}"

    @rankings = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      User.ranking(period: period).to_a
    end
  end

  def find_my_rank
    # @rankingsの中から自分のIDを探す（キャッシュされた配列から探すので高速）
    user_in_ranking = @rankings.find { |user| user.id == current_user.id }

    if user_in_ranking
      # ランキング内にいれば、そのインデックス+1が順位
      @my_rank = @rankings.index(user_in_ranking) + 1
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
      when "daily" then Time.current.all_day
      when "monthly" then Time.current.all_month
      when "yearly" then Time.current.all_year
      else Time.current.all_day
      end

      @my_distance = current_user.walks.where(walked_on: range).sum(:distance) # walked_onカラムを使用
    end
  end
end
