class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # 散歩記録との関連付け（1人のユーザーは複数の散歩記録を持つ）
  # dependent: :destroy は、ユーザーが削除されたときに関連する散歩記録も一緒に削除する
  has_many :walks, dependent: :destroy

  # Google OAuth2認証のコールバック処理
  # OmniAuthから返されたデータを使って、ユーザー情報とトークンを保存する
  def self.from_omniauth(auth)
    # Google UIDでユーザーを検索、見つからなければメールアドレスで検索
    user = User.find_by(google_uid: auth.uid) || User.find_by(email: auth.info.email)

    if user
      # 既存ユーザーの場合、Google認証情報を更新
      user.update(
        google_uid: auth.uid,
        google_token: auth.credentials.token,
        google_refresh_token: auth.credentials.refresh_token,
        google_expires_at: Time.at(auth.credentials.expires_at),
        avatar_url: auth.info.image # アバター画像を更新
      )
    else
      # 新規ユーザーの場合、アカウントを作成
      user = User.create(
        email: auth.info.email,
        password: Devise.friendly_token[0, 20],
        google_uid: auth.uid,
        google_token: auth.credentials.token,
        google_refresh_token: auth.credentials.refresh_token,
        google_expires_at: Time.at(auth.credentials.expires_at),
        avatar_url: auth.info.image # アバター画像を保存
      )
    end

    user
  end

  # Google Fitのアクセストークンが有効かチェック
  def google_token_valid?
    google_token.present? && google_expires_at.present? && google_expires_at > Time.now
  end
end
