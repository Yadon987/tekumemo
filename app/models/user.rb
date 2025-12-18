class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  # ユーザー権限（0: 一般, 1: 管理者）
  enum :role, { general: 0, admin: 1 }

  # 散歩記録との関連付け（1人のユーザーは複数の散歩記録を持つ）
  # dependent: :destroy は、ユーザーが削除されたときに関連する散歩記録も一緒に削除する
  has_many :walks, dependent: :destroy

  # SNS機能の関連付け
  has_many :posts, dependent: :destroy
  has_many :reactions, dependent: :destroy

  # 通知機能の関連付け
  has_many :notifications, dependent: :destroy
  has_many :web_push_subscriptions, dependent: :destroy

  # Active Storage: ランキングOGP画像の添付
  has_one_attached :ranking_ogp_image

  # Active Storage: Googleアバター画像のキャッシュ（OGP生成高速化のため）
  has_one_attached :cached_avatar


  # ユーザー名のバリデーション
  validates :name, presence: true

  # 目標距離のバリデーション
  # 1. 必須であること（デフォルト値があるため通常は問題ないが、念のため）
  # 2. 数値であること
  # 3. 0より大きいこと
  validates :target_distance, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100_000 }

  # 通知設定のバリデーション
  validates :inactive_days_threshold, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 30 }
  validates :walk_reminder_time, presence: true, if: :walk_reminder_enabled?

  # Google OAuth2認証のコールバック処理
  # OmniAuthから返されたデータを使って、ユーザー情報とトークンを保存する
  def self.from_omniauth(auth)
    # Google UIDでユーザーを検索
    # メールアドレスでの自動紐付けは行わない（セキュリティと意図しない連携を防ぐため）
    user = User.find_by(google_uid: auth.uid)

    if user
      # 既存ユーザー（連携済み）の場合、Google認証情報を更新
      user.update(
        google_uid: auth.uid,
        google_token: auth.credentials.token,
        google_refresh_token: auth.credentials.refresh_token,
        google_expires_at: Time.at(auth.credentials.expires_at),
        avatar_url: auth.info.image # アバター画像を更新
      )
    end

    user
  end

  # Google Fitのアクセストークンが有効かチェック
  # 期限切れの場合は自動的にリフレッシュを試みる
  def google_token_valid?
    return false unless google_token.present? && google_refresh_token.present?

    # トークンの有効期限をチェック
    if google_expires_at.present? && google_expires_at > Time.current
      true
    else
      # 期限切れの場合、リフレッシュトークンで自動更新を試みる
      refresh_google_token!
    end
  end

  # リフレッシュトークンを使用してアクセストークンを更新する
  def refresh_google_token!
    return false unless google_refresh_token.present?

    require "net/http"
    require "json"

    # Google OAuth2のトークンエンドポイント
    uri = URI("https://oauth2.googleapis.com/token")

    # リフレッシュリクエストのパラメータ
    google_creds = Rails.application.credentials.google || {}
    params = {
      client_id: google_creds[:client_id],
      client_secret: google_creds[:client_secret],
      refresh_token: google_refresh_token,
      grant_type: "refresh_token"
    }

    begin
      # POSTリクエストを送信
      response = Net::HTTP.post_form(uri, params)
      data = JSON.parse(response.body)

      if response.is_a?(Net::HTTPSuccess) && data["access_token"]
        # 新しいトークン情報で更新
        update!(
          google_token: data["access_token"],
          google_expires_at: Time.current + data["expires_in"].to_i.seconds
        )

        Rails.logger.info "Google token refreshed successfully for user #{id}"
        true
      else
        # リフレッシュ失敗（リフレッシュトークンも無効）
        Rails.logger.error "Failed to refresh Google token for user #{id}: #{data['error']}"
        false
      end
    rescue StandardError => e
      Rails.logger.error "Error refreshing Google token for user #{id}: #{e.message}"
      false
    end
  end

  # 連続して散歩した日数を計算する
  # 注意: 今日の記録がある場合は今日から、ない場合は昨日から遡ってカウントする
  #       これにより、今日歩いた瞬間に+1日として反映され、
  #       今日歩いていなくても昨日までの連続記録が維持される
  def consecutive_walk_days
    # 今日の記録があるかチェック
    has_walked_today = walks.exists?(walked_on: Date.current)

    # カウント開始日を決定（今日歩いた場合は今日から、そうでなければ昨日から）
    start_date = has_walked_today ? Date.current : Date.yesterday

    # N+1対策: ループ内でのクエリ発行を避けるため、必要な日付データを一括取得
    # 開始日以前の記録の日付を重複なしで降順（新しい順）に取得
    walk_dates = walks.where("walked_on <= ?", start_date)
                      .select(:walked_on)
                      .distinct
                      .order(walked_on: :desc)
                      .pluck(:walked_on)

    consecutive_count = 0
    check_date = start_date

    walk_dates.each do |date|
      if date == check_date
        # 日付が一致すればカウントアップし、チェック対象を前日にずらす
        consecutive_count += 1
        check_date -= 1.day
      else
        # 日付が連続していない（飛んでいる）場合、そこで終了
        break
      end
    end

    consecutive_count
  end

  # ランキング集計
  def self.ranking(period: "daily", limit: 100)
    range = case period.to_s
    when "daily"
      Date.current..Date.current
    when "monthly"
      Date.current.beginning_of_month..Date.current
    when "yearly"
      Date.current.beginning_of_year..Date.current
    else
      Date.current
    end

    joins(:walks)
      .where(walks: { walked_on: range })
      .group("users.id")
      .select("users.*, SUM(walks.distance) as total_distance")
      .order("SUM(walks.distance) DESC")
      .limit(limit)
  end

  # 未読通知数を取得
  def unread_notifications_count
    notifications.unread.count
  end
end
