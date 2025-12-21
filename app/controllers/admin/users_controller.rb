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

      # ソート（最終ログイン時刻）
      # ブラウザリロード時はデフォルトに戻る（セッションに保存しない）
      if params[:sort] == "last_login_asc"
        @users = @users.order(Arel.sql("current_sign_in_at ASC NULLS LAST"))
      elsif params[:sort] == "last_login_desc"
        @users = @users.order(Arel.sql("current_sign_in_at DESC NULLS LAST"))
      else
        @users = @users.order(created_at: :desc)
      end

      @users = @users.page(params[:page]).per(20)
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to admin_users_path, notice: "ユーザー「#{@user.name}」を削除しました。"
    end
  end
end
