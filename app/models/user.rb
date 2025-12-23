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

  # Active Storage: ユーザーアップロードのアバター画像
  has_one_attached :uploaded_avatar

  # アバターの種類（0: デフォルト, 1: Google画像, 2: アップロード画像）
  enum :avatar_type, { default: 0, google: 1, uploaded: 2 }

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

  # アバター画像のバリデーション
  validate :validate_uploaded_avatar

  private

  def validate_uploaded_avatar
    return unless uploaded_avatar.attached?

    # ファイルサイズ制限 (5MB)
    if uploaded_avatar.blob.byte_size > 5.megabytes
      errors.add(:uploaded_avatar, "は5MB以下にしてください")
    end

    # ファイル形式制限
    unless uploaded_avatar.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:uploaded_avatar, "は画像ファイル（JPG, PNG, GIF, WEBP）のみアップロード可能です")
    end
  end

  public

  # 表示するアバターURLを決定するメソッド
  # 優先順位: uploaded > google > default
  # ただし、avatar_typeの設定に従って返す
  def display_avatar_url
    if uploaded?
      uploaded_avatar if uploaded_avatar.attached?
    elsif google?
      avatar_url if avatar_url.present?
    else
      nil # デフォルト（イニシャル画像など）を表示
    end
  end

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
        avatar_url: auth.info.image, # アバター画像を更新
        avatar_type: :google # アバター種別をGoogleに設定
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

  # 過去の最大連続記録日数を計算する
  def max_consecutive_walk_days
    # 日付のみを取得してソート（重複排除）
    dates = walks.order(walked_on: :asc).pluck(:walked_on).uniq

    return 0 if dates.empty?

    max_streak = 0
    current_streak = 0
    prev_date = nil

    dates.each do |date|
      if prev_date.nil? || date == prev_date + 1.day
        current_streak += 1
      else
        # 連続が途切れた場合、最大値を更新してリセット
        max_streak = [ max_streak, current_streak ].max
        current_streak = 1
      end
      prev_date = date
    end

    # 最後のストリークも含めて最大値を返す
    [ max_streak, current_streak ].max
  end

  # ランキング集計
  def self.ranking(period: "daily", limit: 100)
    range = case period.to_s
    when "weekly"
      Date.current.beginning_of_week..Date.current.end_of_week
    when "monthly"
      Date.current.beginning_of_month..Date.current
    when "yearly"
      Date.current.beginning_of_year..Date.current
    else
      Date.current.beginning_of_week..Date.current.end_of_week # デフォルトもweeklyにする
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

  # ランキングOGP画像生成用の週間統計情報を取得
  def weekly_ranking_stats
    start_date = Date.current.beginning_of_week
    end_date = Date.current.end_of_week

    # 週間データ集計
    weekly_walks = walks.reload.where(walked_on: start_date..end_date)
    total_distance = weekly_walks.sum(:distance)
    total_steps = weekly_walks.sum(:steps)

    # 順位計算
    # 自分より距離が長いユーザーの数をカウント + 1 = 順位
    higher_rank_users_count = User.joins(:walks)
                                  .where(walks: { walked_on: start_date..end_date })
                                  .group("users.id")
                                  .having("SUM(walks.distance) > ?", total_distance)
                                  .pluck("users.id")
                                  .count

    rank = higher_rank_users_count + 1

    # 英語の序数を生成（ロケール設定に依存しないように自前で処理）
    suffix = case rank % 100
    when 11, 12, 13 then "th"
    else
               case rank % 10
               when 1 then "st"
               when 2 then "nd"
               when 3 then "rd"
               else "th"
               end
    end
    rank_with_ordinal = "#{rank}#{suffix}"

    # レベル計算
    level = StatsService.new(self).level

    {
      level: level,
      date: "#{start_date.strftime('%m/%d')} - #{end_date.strftime('%m/%d')}",
      label1: "RANK",
      value1: rank_with_ordinal,
      label2: "STEPS",
      value2: ActiveSupport::NumberHelper.number_to_delimited(total_steps),
      label3: "DISTANCE",
      value3: "#{total_distance.round(1)} km",
      period_key: "#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}"
    }
  end
end
