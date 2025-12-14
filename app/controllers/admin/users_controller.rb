module Admin
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc).page(params[:page]).per(20)
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to admin_users_path, notice: "ユーザー「#{@user.name}」を削除しました。"
    end
  end
end
