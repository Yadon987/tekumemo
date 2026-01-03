class Users::SessionsController < Devise::SessionsController
  # ゲストログイン
  def new_guest
    resource = User.create_portfolio_guest
    sign_in(resource_name, resource)
    redirect_to root_path, notice: "ゲストモードとしてログインしました。"
  end

  # ログアウト時にゲストユーザーなら削除する
  def destroy
    if current_user && current_user.guest?
      host_guest = current_user
      # 高速化: 関連データを一括削除 (N+1削除の回避)
      # 削除対象が多い順に処理
      host_guest.walks.delete_all
      host_guest.posts.delete_all
      host_guest.user_achievements.delete_all
      host_guest.notifications.delete_all
      host_guest.reactions.delete_all

      # 削除対象のIDを保持（削除後に参照できなくなるため）
      guest_id = host_guest.id

      # Deviseのログアウト処理
      super do
        # ログアウト後に削除実行
        # 主なデータは既に削除済みなので、destroyは軽量に動作する
        User.find_by(id: guest_id)&.destroy
      end
    else
      super
    end
  end
end
