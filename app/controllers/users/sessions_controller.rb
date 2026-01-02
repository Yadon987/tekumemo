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
      # 削除対象のIDを保持（削除後に参照できなくなるため）
      guest_id = current_user.id

      # Deviseのログアウト処理
      super do
        # ログアウト後に削除実行 (superのブロック内はログアウト後...いや、sign_out後だがセッションはまだ？)
        # 安全のため、ユーザーを削除するのはsign_outの後
        User.find_by(id: guest_id)&.destroy
      end
    else
      super
    end
  end
end
