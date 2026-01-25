class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2]
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
  has_many :reminder_logs, dependent: :destroy
  has_many :web_push_subscriptions, dependent: :destroy

  # コールバック: 新規ユーザー登録時に公開済みお知らせの通知を作成
  after_create :create_reminder_logs_for_active_announcements

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
  validates :goal_meters, presence: true,
                          numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100_000 }

  # 通知設定のバリデーション
  validates :inactive_days, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 30 }
  validates :walk_reminder_time, presence: true, if: :is_walk_reminder?

  # アバター画像のバリデーション
  validate :validate_uploaded_avatar

  private

  def validate_uploaded_avatar
    return unless uploaded_avatar.attached?

    # ファイルサイズ制限 (5MB)
    errors.add(:uploaded_avatar, "は5MB以下にしてください") if uploaded_avatar.blob.byte_size > 5.megabytes

    # ファイル形式制限
    return if uploaded_avatar.content_type.in?(%w[image/jpeg image/png image/gif image/webp])

    errors.add(:uploaded_avatar, "は画像ファイル（JPG, PNG, GIF, WEBP）のみアップロード可能です")
  end

  # 新規ユーザー登録時に、公開済みのお知らせに対する通知を作成
  # これにより、新規ユーザーも過去のお知らせを確認できる
  def create_reminder_logs_for_active_announcements
    Announcement.active.find_each do |announcement|
      reminder_logs.create!(
        announcement: announcement,
        category: :announcement,
        read_at: nil
      )
    rescue ActiveRecord::RecordNotUnique
      # ユニークインデックス違反 = すでに通知が存在するためスキップ
      Rails.logger.debug "Notification already exists for user #{id} and announcement #{announcement.id}"
      next
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
      # 更新用のハッシュを構築
      # refresh_tokenはnilで返ってくる場合があるため、存在する場合のみ更新
      # （Google OAuthの仕様：2回目以降の認証ではrefresh_tokenが返らない場合がある）
      update_hash = {
        google_uid: auth.uid,
        google_token: auth.credentials.token,
        google_expires_at: Time.at(auth.credentials.expires_at),
        avatar_url: auth.info.image, # アバター画像を更新
        avatar_type: :google # アバター種別をGoogleに設定
      }

      # refresh_tokenが存在する場合のみ更新（nilで上書きしない）
      update_hash[:google_refresh_token] = auth.credentials.refresh_token if auth.credentials.refresh_token.present?

      user.update(update_hash)
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
    return create_fallback_guest unless admin_user

    # トランザクションで一括処理
    transaction do
      # ゲストユーザー作成
      guest_email = "guest_#{Time.current.to_i}_#{SecureRandom.hex(4)}@example.com"
      guest = User.create!(
        email: guest_email,
        password: SecureRandom.urlsafe_base64,
        name: "ゲストユーザー",
        role: :guest,
        goal_meters: admin_user.goal_meters,
        avatar_type: :default
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

      # 新しく挿入されたゲストのWalkを取得し、walked_onとkilometersでマッピング用のハッシュを作成
      # キー: [walked_on, kilometers], 値: ゲストのWalk ID
      guest_walks = guest.walks.reload.index_by { |w| [w.walked_on, w.kilometers] }

      # 2. 投稿（Posts）のコピー
      # タイムスタンプも維持したいので、created_atもコピーする
      source_posts = admin_user.posts.where(created_at: 3.months.ago..Time.current)

      posts_data = source_posts.map do |post|
        # walk_idをゲストのWalkにマッピング
        new_walk_id = if post.walk_id
                        original_walk = Walk.find_by(id: post.walk_id)
                        if original_walk
                          guest_walk = guest_walks[[original_walk.walked_on, original_walk.kilometers]]
                          guest_walk&.id
                        end
        end

        post.attributes.except("id", "user_id", "walk_id").merge(
          "user_id" => guest.id,
          "walk_id" => new_walk_id # ゲストのWalk IDにマッピング
        )
      end

      Post.insert_all(posts_data) if posts_data.present?
      Rails.logger.info "Guest Mode: Copied #{posts_data.size} posts" if posts_data.present?

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
      Rails.logger.info "Guest Mode: Copied #{achievements_data.size} achievements" if achievements_data.present?

      # 作成したゲストユーザーを返す
      guest
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Guest creation validation failed: #{e.message}"
      raise # トランザクションロールバック
    rescue StandardError => e
      Rails.logger.error "Guest creation failed: #{e.class} - #{e.message}"
      raise
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
      goal_meters: 5000,
      avatar_type: :default
    )
  end

  # 古いゲストアカウントのお掃除
  def self.cleanup_old_guests
    # role: guest かつ 作成から1時間以上経過したユーザーを削除
    # ゲストはお試し用なので1時間で十分
    deleted_count = User.where(role: :guest).where("created_at < ?", 1.hour.ago).destroy_all.size
    Rails.logger.info "[Cleanup] Deleted #{deleted_count} old guest users" if deleted_count > 0
  end

  def google_token_valid?
    google_token_status == :valid
  end

  # Googleトークンの詳細なステータスを返す
  # @return [Symbol] :valid, :not_connected, :expired_need_reauth, :temporary_error
  def google_token_status
    # ゲストユーザーは常に連携済み（ダミーデータを使用するため）
    return :valid if guest?

    # 管理者も一般ユーザーと同様にトークンチェックを行う
    # （トークンがクリアされた場合は再連携を促す）

    # トークンの存在確認を強化
    return :not_connected unless google_token.present?
    return :not_connected unless google_refresh_token.present?

    # 有効期限が未設定の場合は再認証必要（不完全なトークン状態）
    return :expired_need_reauth unless google_expires_at.present?

    # トークンの有効期限をチェック
    if google_expires_at > Time.current
      :valid
    else
      # 期限切れの場合、リフレッシュトークンで自動更新を試みる
      case refresh_google_token!
      when true then :valid
      when :reauth_required then :expired_need_reauth
      else :temporary_error
      end
    end
  end

  # リフレッシュトークンを使用してアクセストークンを更新する
  # @return [Boolean, Symbol] true:成功, :reauth_required:再認証が必要, false:その他エラー
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
        error_type = data["error"]
        if error_type == "invalid_grant"
          # リフレッシュトークンが無効化された（許可剥奪など）
          Rails.logger.error "Google refresh token revoked for user #{id}"
          :reauth_required
        else
          Rails.logger.error "Failed to refresh Google token for user #{id}: #{error_type}"
          false
        end
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
      break unless date == check_date

      # 日付が一致すればカウントアップし、チェック対象を前日にずらす
      consecutive_count += 1
      check_date -= 1.day

      # 日付が連続していない（飛んでいる）場合、そこで終了
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
        max_streak = [max_streak, current_streak].max
        current_streak = 1
      end
      prev_date = date
    end

    # 最後のストリークも含めて最大値を返す
    [max_streak, current_streak].max
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
      .select("users.*, SUM(walks.kilometers) as total_distance")
      .order(Arel.sql("total_distance DESC"))
      .limit(limit) # 制限行数
  end

  # 閲覧ユーザーに応じたランキングスコープ
  # ゲスト以外が見る場合、ゲストユーザーはランキングから除外して「汚染」を防ぐ
  # ゲスト自身が見る場合、自分（と他のゲスト）も含めて表示し、自分の順位を確認できるようにする
  scope :ranking_for, lambda { |user, period: "weekly"|
    if user&.guest?
      # ゲストが見る場合: 全ユーザーを対象（現在のランキングロジックそのまま）
      ranking(period: period)
    else
      # 一般ユーザー/未ログインが見る場合: ゲストを除外
      ranking(period: period).where.not(role: :guest)
    end
  }

  # 未読通知数を取得
  def unread_reminder_logs_count
    reminder_logs.unread.count
  end

  # ランキングOGP画像生成用の週間統計情報を取得
  def weekly_ranking_stats
    start_date = Date.current.beginning_of_week
    end_date = Date.current.end_of_week

    # 週間データ集計
    weekly_walks = walks.reload.where(walked_on: start_date..end_date)
    total_distance = weekly_walks.sum(:kilometers)
    total_steps = weekly_walks.sum(:steps)

    # 順位計算
    # 自分より距離が長いユーザーの数をカウント + 1 = 順位
    higher_rank_users_count = User.joins(:walks)
                                  .where(walks: { walked_on: start_date..end_date })
                                  .group("users.id")
                                  .having("SUM(walks.kilometers) > ?", total_distance)
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
