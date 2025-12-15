class Admin::DashboardController < Admin::BaseController
  def index
    # ユーザー統計
    @total_users = User.count
    @users_this_month = User.where(created_at: Time.current.beginning_of_month..Time.current).count
    @active_users_today = User.where("current_sign_in_at >= ?", Time.current.beginning_of_day).count
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

    # 人気投稿（リアクションが多い順 TOP5）
    @popular_posts = Post.left_joins(:reactions)
                         .select('posts.*, COUNT(reactions.id) as reactions_count')
                         .group('posts.id')
                         .order('reactions_count DESC')
                         .limit(5)
                         .includes(:user)

    # 最近の投稿（5件）
    @recent_posts = Post.order(created_at: :desc).limit(5).includes(:user)

    # 最近の登録ユーザー（5件）
    @recent_users = User.order(created_at: :desc).limit(5)

    # === 異常検知 ===
    detect_anomalies
  end

  private

  def detect_anomalies
    @anomalies = {}

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

    # 4. 非アクティブアカウント（投稿・散歩0件で登録から30日以上経過）
    @anomalies[:inactive_accounts] = User.left_joins(:posts, :walks)
                                         .where("users.created_at < ?", 30.days.ago)
                                         .group("users.id")
                                         .having("COUNT(DISTINCT posts.id) = 0 AND COUNT(DISTINCT walks.id) = 0")
                                         .limit(10)

    # 異常の総数を計算（配列に変換してからサイズを取得）
    @total_anomalies = @anomalies.values.sum { |v| v.to_a.size }
  end
end
