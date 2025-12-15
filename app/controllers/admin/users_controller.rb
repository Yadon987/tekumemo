module Admin
  class UsersController < BaseController
    def index
      @users = User.all

      # 検索（名前・メールアドレス）
      if params[:q].present?
        search_term = "%#{params[:q]}%"
        @users = @users.where("name ILIKE ? OR email ILIKE ?", search_term, search_term)
      end

      # フィルタ（権限）
      if params[:role].present?
        @users = @users.where(role: params[:role])
      end

      @users = @users.order(created_at: :desc).page(params[:page]).per(20)
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to admin_users_path, notice: "ユーザー「#{@user.name}」を削除しました。"
    end
  end
end
