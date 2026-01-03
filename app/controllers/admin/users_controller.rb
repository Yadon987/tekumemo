module Admin
  class UsersController < BaseController
    # ソートオプションのホワイトリスト
    ALLOWED_SORT_OPTIONS = {
      "last_login_asc" => Arel.sql("current_sign_in_at ASC NULLS LAST"),
      "last_login_desc" => Arel.sql("current_sign_in_at DESC NULLS LAST"),
      "created_at_asc" => { created_at: :asc },
      "created_at_desc" => { created_at: :desc }
    }.freeze

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

      # ソート
      @users = @users.order(sort_clause)
      @users = @users.page(params[:page]).per(20)
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to admin_users_path, notice: "ユーザー「#{@user.name}」を削除しました。"
    end

    private

    def sort_clause
      ALLOWED_SORT_OPTIONS.fetch(params[:sort], { created_at: :desc })
    end
  end
end
