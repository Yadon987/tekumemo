class Admin::DashboardController < Admin::BaseController
  skip_before_action :require_admin
  before_action :require_admin_or_guest

  def index
    # ユーザー統計
    @total_users = User.count
    @users_this_month = User.where(created_at: Time.current.beginning_of_month..Time.current).count
    @active_users_today = User.where("current_sign_in_at >= ?", Time.current.beginning_of_day).count

    if current_user.guest?
      # ゲスト用ダミーデータ
      # アクティブユーザーリストもダミーにする
      @active_users_today_list = ["ユーザーA", "ユーザーB", "ユーザーC"]

      # 統計情報の非表示やダミー化が必要ならここで行うが、
      # グローバル統計は見せても良い方針なのでそのまま

      @active_users_this_week = 1234 # User.where(...).count
      @active_users_this_month = 5678

      # 投稿統計
      @total_posts = 9876
      @posts_today = 123
      @posts_this_month = 456

      # 散歩統計
      @total_walks = 5432
      @total_distance = 12345.6
      @distance_this_month = 789.0

      # === リスト系のダミー化（ぼかし表示の下に置くためそれっぽいデータ） ===
      @popular_posts = create_dummy_posts(5)
      @recent_posts = create_dummy_posts(5)
      @recent_users = create_dummy_users(5)

      # === 異常検知（ダミー） ===
      generate_dummy_anomalies
    else
      # 管理者用（リアルデータ）
      @active_users_today_list = User.where("current_sign_in_at >= ?", Time.current.beginning_of_day)
                                      .order(current_sign_in_at: :desc)
                                      .limit(3)
                                      .pluck(:name)
      @active_users_this_week = User.where("current_sign_in_at >= ?", Time.current.beginning_of_week).count
      @active_users_this_month = User.where("current_sign_in_at >= ?", Time.current.beginning_of_month).count

      # 投稿統計
      @total_posts = Post.count
      @posts_today = Post.where(created_at: Time.current.beginning_of_day..Time.current).count
      @posts_this_month = Post.where(created_at: Time.current.beginning_of_month..Time.current).count

      # 散歩統計
      @total_walks = Walk.count
      @total_distance = Walk.sum(:distance) || 0
      @distance_this_month = Walk.where(walked_on: Time.current.beginning_of_month.to_date..Time.current.to_date).sum(:distance) || 0

      # 人気投稿
      @popular_posts = Post.left_joins(:reactions)
                           .select("posts.*, COUNT(reactions.id) as reactions_count")
                           .group("posts.id")
                           .order("reactions_count DESC")
                           .limit(5)
                           .includes(user: { uploaded_avatar_attachment: :blob })

      # 最近の投稿
      @recent_posts = Post.order(created_at: :desc).limit(5).includes(user: { uploaded_avatar_attachment: :blob })

      # 最近のユーザー
      @recent_users = User.order(created_at: :desc).limit(5)

      # 異常検知
      detect_anomalies
    end
  end

  private

  def create_dummy_posts(count)
    (1..count).map do |i|
      OpenStruct.new(
        id: i,
        body: "これはダミーの投稿です。内容は表示されません。",
        created_at: Time.current - i.hours,
        user: OpenStruct.new(
          name: "ダミーユーザー#{i}",
          email: "dummy#{i}@example.com",
          display_avatar_url: nil
        ),
        reactions_count: rand(1..100),
        weather_label: "晴れ",
        feeling_label: "最高"
      )
    end
  end

  def create_dummy_users(count)
    (1..count).map do |i|
      OpenStruct.new(
        id: i,
        name: "新規ユーザー#{i}",
        email: "user#{i}@example.com",
        created_at: Time.current - i.days,
        current_sign_in_at: Time.current - i.hours,
        display_avatar_url: nil
      )
    end
  end

  def generate_dummy_anomalies
    @anomalies = {}

    # 1. スパム疑い
    @anomalies[:spam_users] = [
      OpenStruct.new(id: 1, name: "SpamBot01", email: "bot1@example.com", post_count: 25, created_at: 1.day.ago, current_sign_in_at: Time.current, display_avatar_url: nil),
      OpenStruct.new(id: 2, name: "AggressiveUser", email: "agg@example.com", post_count: 22, created_at: 2.days.ago, current_sign_in_at: Time.current, display_avatar_url: nil)
    ]

    # 2. データ整合性エラー (Walkのダミー)
    @anomalies[:invalid_walks] = [
      OpenStruct.new(
        id: 101, distance: 55000, steps: 100000,
        user: OpenStruct.new(id: 3, name: "WalkerPRO", email: "walk@example.com", display_avatar_url: nil)
      )
    ]

    # 3. セキュリティ懸念
    @anomalies[:security_concern] = [
      OpenStruct.new(id: 4, name: "HackedAccount?", email: "old@example.com", post_count: 0, created_at: 1.year.ago, current_sign_in_at: 35.days.ago, display_avatar_url: nil)
    ]

    # 4. 非アクティブアカウント（ダミーでは空）
    @anomalies[:inactive_accounts] = []

    @total_anomalies = @anomalies.values.sum { |v| v.to_a.size }
  end

  def detect_anomalies
    @anomalies = {}
    # ... (元のロジック)

    # 1. スパム疑いユーザー
    spam_users = User.joins(:posts)
                     .where("posts.created_at >= ?", 24.hours.ago)
                     .group("users.id")
                     .having("COUNT(posts.id) >= 20")
                     .select("users.*, COUNT(posts.id) as post_count")

    new_user_spam = User.joins(:posts)
                        .where("users.created_at >= ?", 1.hour.ago)
                        .group("users.id")
                        .having("COUNT(posts.id) >= 5")
                        .select("users.*, COUNT(posts.id) as post_count")

    @anomalies[:spam_users] = (spam_users + new_user_spam).uniq

    # 2. データ整合性エラー
    @anomalies[:invalid_walks] = Walk.where("distance > 50000 OR steps > 100000")
                                     .includes(:user)
                                     .limit(10)

    # 3. セキュリティ懸念（最終ログイン30日以上前なのに最近7日以内に投稿）
    @anomalies[:security_concern] = User.joins(:posts)
                                        .where("users.current_sign_in_at < ?", 30.days.ago)
                                        .where("posts.created_at >= ?", 7.days.ago)
                                        .distinct
                                        .limit(10)

    # 異常の総数を計算
    @total_anomalies = @anomalies.values.sum { |v| v.to_a.size }
  end
end
