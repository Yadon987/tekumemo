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
  end
end
