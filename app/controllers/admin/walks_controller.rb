class Admin::WalksController < Admin::BaseController
  def index
    @walks = Walk.includes(:user)

    # 検索（ユーザー名）
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      @walks = @walks.joins(:user).where("users.name ILIKE ?", search_term)
    end

    # フィルタ（距離範囲）
    if params[:min_distance].present?
      @walks = @walks.where("distance >= ?", params[:min_distance].to_i)
    end

    if params[:max_distance].present?
      @walks = @walks.where("distance <= ?", params[:max_distance].to_i)
    end

    # フィルタ（日付範囲）
    if params[:start_date].present?
      @walks = @walks.where("walked_on >= ?", params[:start_date])
    end

    if params[:end_date].present?
      @walks = @walks.where("walked_on <= ?", params[:end_date])
    end

    @walks = @walks.order(walked_on: :desc, created_at: :desc).page(params[:page]).per(20)
  end

  def show
    @walk = Walk.find(params[:id])
  end

  def destroy
    @walk = Walk.find(params[:id])
    walk_user_name = @walk.user.name
    walk_date = @walk.walked_on.strftime('%Y/%m/%d')
    @walk.destroy
    redirect_to admin_walks_path, notice: "「#{walk_user_name}」さんの散歩記録（#{walk_date}）を削除しました"
  end
end
