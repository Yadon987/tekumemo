class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  # ユーザー権限（0: 一般, 1: 管理者, 2: ゲスト管理者）
  # guest: 管理画面へアクセス可だが、閲覧のみ等の制限あり
  enum :role, { general: 0, admin: 1, guest: 2 }

  # 散歩記録との関連付け（1人のユーザーは複数の散歩記録を持つ）
  # dependent: :destroy は、ユーザーが削除されたときに関連する散歩記録も一緒に削除する
  has_many :walks, dependent: :destroy

  # SNS機能の関連付け
  has_many :posts, dependent: :destroy
  has_many :reactions, dependent: :destroy

  # 通知機能の関連付け
  has_many :notifications, dependent: :destroy
  has_many :web_push_subscriptions, dependent: :destroy

  # 実績機能の関連付け
  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements

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

  # ポートフォリオ閲覧用ゲストユーザーを作成
  # 管理者（Admin）のデータをコピーして、リッチな体験を提供する
  def self.create_portfolio_guest
    # 古いゲストユーザーをお掃除（作成から24時間以上経過）
    cleanup_old_guests

    # コピー元となるユーザーを取得
    # 1. 散歩記録が多い管理者を優先（リッチなデータをコピーするため）
    # 2. いなければ管理者の最初
    admin_user = User.admin.joins(:walks).group("users.id").order("COUNT(walks.id) DESC").first || User.admin.first

    # 互換性のため、ID:2が存在し、かつデータがあるならそれを使う手もあるが、動的なデータ量を優先する

    Rails.logger.info "Guest Mode: Selected admin user candidate ID: #{admin_user&.id}"

    # 万が一管理者がいない場合は、最低限のゲストを作成して返す
    unless admin_user
      return create_fallback_guest
    end

    # トランザクションで一括処理
    transaction do
      # ゲストユーザー作成
      guest_email = "guest_#{Time.current.to_i}_#{SecureRandom.hex(4)}@example.com"
      guest = User.create!(
        email: guest_email,
        password: SecureRandom.urlsafe_base64,
        name: "ゲストユーザー",
        role: :guest,
        target_distance: admin_user.target_distance,
        avatar_type: :default,
        # 通知設定などはデフォルトでOK
      )

      # === データコピー処理 (直近3ヶ月分) ===

      # 1. 散歩記録（Walks）のコピー
      # コピー対象期間
      range = 3.months.ago.to_date..Date.current

      source_walks = admin_user.walks.where(walked_on: range)
      Rails.logger.info "Guest Mode: Cloning data from Admin ID: #{admin_user.id}"
      Rails.logger.info "Guest Mode: Copying #{source_walks.count} walks..."

      # insert_allのためのハッシュ配列を作成
      walks_data = source_walks.map do |walk|
        walk.attributes.except("id", "user_id", "created_at", "updated_at").merge(
          "user_id" => guest.id,
          "created_at" => Time.current,
          "updated_at" => Time.current
        )
      end

      # 一括挿入（バリデーションスキップ・高速化）
      Walk.insert_all(walks_data) if walks_data.present?

      # 2. 投稿（Posts）のコピー
      # タイムスタンプも維持したいので、created_atもコピーする
      source_posts = admin_user.posts.where(created_at: 3.months.ago..Time.current)

      posts_data = source_posts.map do |post|
        post.attributes.except("id", "user_id").merge(
          "user_id" => guest.id
        )
      end

      Post.insert_all(posts_data) if posts_data.present?

      # 3. 実績（Achievements）のコピー
      # 中間テーブル UserAchievement をコピー
      source_achievements = admin_user.user_achievements

      achievements_data = source_achievements.map do |ua|
        ua.attributes.except("id", "user_id", "created_at", "updated_at").merge(
          "user_id" => guest.id,
          "created_at" => Time.current,
          "updated_at" => Time.current
        )
      end

      UserAchievement.insert_all(achievements_data) if achievements_data.present?

      # 作成したゲストユーザーを返す
      guest
    end
  end

  # 管理者がいない場合のフォールバック用ゲスト作成
  def self.create_fallback_guest
    guest_email = "guest_#{Time.current.to_i}@example.com"
    User.create!(
      email: guest_email,
      password: SecureRandom.urlsafe_base64,
      name: "ゲストユーザー",
      role: :guest,
      target_distance: 5000,
      avatar_type: :default
    )
  end

  # 古いゲストアカウントのお掃除
  def self.cleanup_old_guests
    # role: guest かつ 作成から24時間以上経過したユーザーを削除
    User.where(role: :guest).where("created_at < ?", 24.hours.ago).destroy_all
  end

  # Google Fitのアクセストークンが有効かチェック
  # 期限切れの場合は自動的にリフレッシュを試みる
  def google_token_valid?
    return true if guest? # ゲストユーザーは常に連携済み（デモ用）
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

  # ランキング用クラスメソッド
  # 期間ごとの距離を集計して降順に並べる
  # @param period [String] 期間（weekly, monthly, all_time）
  def self.ranking(period: "weekly", limit: 100)
    # 期間に応じた日付範囲を取得
    start_date = case period
    when "weekly"
                   Date.current.beginning_of_week
    when "monthly"
                   Date.current.beginning_of_month
    when "yearly"
                   Date.current.beginning_of_year
    when "all_time"
                   nil # 全期間
    else
                   Date.current.beginning_of_week
    end

    # 実際に歩いた距離を集計
    relation = joins(:walks)

    relation = relation.where(walks: { walked_on: start_date..Date.current }) if start_date

    relation
      .group(:id)
      .select("users.*, SUM(walks.distance) as total_distance")
      .order(Arel.sql("total_distance DESC"))
      .limit(limit) # 制限行数
  end

  # 閲覧ユーザーに応じたランキングスコープ
  # ゲスト以外が見る場合、ゲストユーザーはランキングから除外して「汚染」を防ぐ
  # ゲスト自身が見る場合、自分（と他のゲスト）も含めて表示し、自分の順位を確認できるようにする
  scope :ranking_for, ->(user, period: "weekly") {
    if user&.guest?
      # ゲストが見る場合: 全ユーザーを対象（現在のランキングロジックそのまま）
      ranking(period: period)
    else
      # 一般ユーザー/未ログインが見る場合: ゲストを除外
      ranking(period: period).where.not(role: :guest)
    end
  }

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
