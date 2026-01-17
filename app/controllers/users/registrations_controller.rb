# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # ユーザー情報の更新前に、許可するパラメータを追加する
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/edit
  # Deviseのデフォルトのeditアクションをそのまま使うので、オーバーライド不要
  # ただし、ビューは app/views/devise/registrations/edit.html.erb を使うことになる

  # PUT /resource
  # 更新処理
  def update
    # ゲストユーザーは更新不可
    if current_user.guest?
      redirect_to edit_user_registration_path, alert: "ゲストユーザーは設定を変更できません。"
      return
    end

    # Google連携済みなどでパスワードなしで更新したい場合のロジック
    # Devise標準の update_resource をオーバーライドしてもいいが、
    # ここでは super を呼ぶ前にパラメータを調整したり、
    # update_resource メソッド自体をオーバーライドするのが一般的。
    super
  end

  # Google連携解除アクション
  # これはDevise標準にはないので、独自に追加
  def disconnect_google
    # ゲストユーザーは操作不可
    if current_user.guest?
      redirect_to edit_user_registration_path, alert: "ゲストユーザーは設定を変更できません。"
      return
    end

    # Googleのみで登録したユーザー（パスワード未設定）のチェック
    # Googleログインのみで登録したユーザーは、自分のパスワードを知らない状態
    # そのため、先にパスワードを設定してもらう必要がある
    unless user_has_usable_password?(current_user)
      redirect_to edit_user_registration_path,
                  alert: "Google連携を解除する前に、セキュリティ設定で新しいパスワードを設定してください。パスワード設定後、再度連携解除を実行できます。"
      return
    end

    # パスワード入力チェック
    if params[:user].nil? || params[:user][:current_password].blank?
      redirect_to edit_user_registration_path, alert: "連携解除にはパスワードの入力が必要です。"
      return
    end

    # パスワード検証
    unless current_user.valid_password?(params[:user][:current_password])
      redirect_to edit_user_registration_path, alert: "パスワードが正しくありません。"
      return
    end

    if current_user.update(
      google_uid: nil,
      google_token: nil,
      google_refresh_token: nil,
      google_expires_at: nil,
      avatar_type: :default
    )
      redirect_to edit_user_registration_path, notice: "Google連携を解除しました。次回からはパスワードでログインしてください。"
    else
      redirect_to edit_user_registration_path, alert: "解除に失敗しました: #{current_user.errors.full_messages.join(', ')}"
    end
  end

  # アップロード画像の削除
  def delete_uploaded_avatar
    # ゲストユーザーは操作不可
    if current_user.guest?
      redirect_to edit_user_registration_path, alert: "ゲストユーザーは設定を変更できません。"
      return
    end

    if current_user.uploaded_avatar.attached?
      current_user.uploaded_avatar.purge
      current_user.update(avatar_type: :default)
      redirect_to edit_user_registration_path, notice: "アップロード画像を削除しました"
    else
      redirect_to edit_user_registration_path, alert: "削除する画像がありません"
    end
  end

  protected

  # アカウント更新時に許可するストロングパラメータの設定
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [
                                        :name,
                                        :goal_meters,
                                        :avatar_type,
                                        :uploaded_avatar,
                                        # 通知設定
                                        :is_walk_reminder,
                                        :walk_reminder_time,
                                        :is_inactive_reminder,
                                        :inactive_days,
                                        :is_reaction_summary
                                      ])
  end

  # 更新後のリダイレクト先
  def after_update_path_for(resource)
    edit_user_registration_path
  end

  # パスワードなしで更新する場合の対応
  def update_resource(resource, params)
    # 画像がアップロードされた場合、アバタータイプを自動的にuploadedにする
    params[:avatar_type] = "uploaded" if params[:uploaded_avatar].present?

    # パスワード入力がある、またはメールアドレス変更時はパスワード必須
    if params[:password].present? || (params[:email].present? && params[:email] != resource.email)
      resource.update_with_password(params)
    else
      # それ以外（名前や目標距離のみの変更）はパスワードなしで更新
      params.delete(:current_password)
      resource.update_without_password(params)
    end
  end

  # ユーザーが「使える」パスワードを持っているかを判定
  # Googleのみで登録したユーザーはパスワードを知らない状態
  def user_has_usable_password?(user)
    # パスワードが暗号化されていない（空）なら論外
    return false if user.encrypted_password.blank?

    # Google未連携ならパスワード設定済みとみなす（Email登録）
    return true if user.google_uid.blank?

    # Google連携済みの場合
    # 「Googleログインのみで作成されたユーザー」は、作成と同時に連携情報が保存されるため
    # created_at と updated_at がほぼ同時になる。
    # 一方、通常登録ユーザーが後からGoogle連携した場合、
    # 連携のupdateで updated_at が更新されるので created_at と差が出る。

    # したがって、created_at より updated_at が新しければ、
    # 「後から連携した＝元々パスワードを持っていた」と判断する。
    # (マイグレーション不要での暫定対策としてはこれが最も確実)
    user.updated_at > user.created_at
  end
end
