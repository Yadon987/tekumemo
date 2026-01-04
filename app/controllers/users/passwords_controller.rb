# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # パスワードリセット機能は現在未実装のため、アクセスをブロックする
  # 開発者ツールでComing Soonオーバーレイを削除してもアクセスできないようにする

  # GET /users/password/new
  def new
    redirect_to new_user_session_path,
                alert: "パスワードリセット機能は現在準備中です。Googleアカウントでログインするか、サポートにお問い合わせください。"
  end

  # POST /users/password
  def create
    redirect_to new_user_session_path,
                alert: "パスワードリセット機能は現在準備中です。"
  end

  # GET /users/password/edit?reset_password_token=abcdef
  def edit
    redirect_to new_user_session_path,
                alert: "パスワードリセット機能は現在準備中です。"
  end

  # PUT /users/password
  def update
    redirect_to new_user_session_path,
                alert: "パスワードリセット機能は現在準備中です。"
  end
end
