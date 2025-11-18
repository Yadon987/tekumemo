class LoginStampsController < ApplicationController
  # ログインしていないユーザーはアクセスできないようにする
  before_action :authenticate_user!

  # ログインスタンプカレンダーページ（GET /login_stamps）
  def index
    # カレンダーの表示月を設定
    # params[:start_date]がない場合は今月を表示
    if params[:start_date]
      # URLパラメータから日付を取得
      @start_date = Date.parse(params[:start_date])
    else
      # 今月の1日を設定
      @start_date = Date.today.beginning_of_month
    end

    # 表示する月の範囲を設定
    # カレンダー表示のため、前月末から翌月初めまでの範囲を取得
    month_start = @start_date.beginning_of_month
    month_end = @start_date.end_of_month

    # カレンダー表示用に前後の日付も含めた範囲を設定
    calendar_start = month_start.beginning_of_week(:sunday)
    calendar_end = month_end.end_of_week(:sunday)

    # ログインユーザーの散歩記録を取得
    # カレンダー表示範囲内の記録のみ取得
    @walks = current_user.walks
                         .where(walked_on: calendar_start..calendar_end)
                         .order(:walked_on)

    # 日付ごとにグループ化（カレンダー表示用）
    # { Date => [Walk, Walk, ...] } の形式
    @walks_by_date = @walks.group_by { |walk| walk.walked_on }

    # 今月の散歩日数を計算
    @monthly_walk_count = current_user.walks
                                      .where(walked_on: month_start..month_end)
                                      .select(:walked_on)
                                      .distinct
                                      .count

    # 連続日数を計算
    @consecutive_days = calculate_consecutive_days
  end

  private

  # 連続日数を計算するメソッド
  def calculate_consecutive_days
    # 今日から過去に向かって、連続して散歩した日数を数える
    consecutive_count = 0
    check_date = Date.today

    # 今日から過去に向かって1日ずつチェック
    loop do
      # その日の散歩記録があるかチェック
      if current_user.walks.exists?(walked_on: check_date)
        # 記録があれば連続日数をカウント
        consecutive_count += 1
        # 1日前に移動
        check_date = check_date - 1.day
      else
        # 記録がなければループを終了
        break
      end
    end

    consecutive_count
  end
end
