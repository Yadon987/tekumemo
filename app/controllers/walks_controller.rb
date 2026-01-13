class WalksController < ApplicationController
  # ログインしていないユーザーはアクセスできないようにする
  before_action :authenticate_user!

  # show、edit、update、destroyアクションの前に、対象の散歩記録を取得する
  before_action :set_walk, only: %i[show edit update destroy]

  # 散歩記録一覧ページ（GET /walks）
  def index
    # ログインしているユーザーの散歩記録だけを取得する
    # Walkモデルのdefault_scopeにより、日付順（新しい順）で自動ソートされる
    @walks = current_user.walks.recent.page(params[:page]).per(10)
  end

  # 散歩記録詳細ページ（GET /walks/:id）
  def show
    # before_actionで@walkが設定されているので、ここでは何もしない
  end

  # 新規散歩記録作成ページ（GET /walks/new）
  def new
    # 新しい散歩記録のインスタンスを作成
    # デフォルト値として今日の日付を設定
    @walk = Walk.new(walked_on: Date.current)

    # 現在時刻に基づいて時間帯の初期値をセット
    hour = Time.current.hour
    @walk.daypart = case hour
    when 4..8 then :early_morning
    when 9..15 then :day
    when 16..18 then :evening
    else :night
    end
  end

  # 散歩記録編集ページ（GET /walks/:id/edit）
  def edit
    # before_actionで@walkが設定されているので、ここでは何もしない
  end

  # 散歩記録の作成処理（POST /walks）
  def create
    # ログインしているユーザーに紐づけて散歩記録を作成
    @walk = current_user.walks.build(walk_params)

    # データベースに保存を試みる
    if @walk.save
      # 保存に成功した場合、一覧ページにリダイレクトして成功メッセージを表示
      redirect_to walks_path, notice: t("flash.walks.create.notice")
    else
      # 保存に失敗した場合（バリデーションエラー）、新規作成ページを再表示
      render :new, status: :unprocessable_entity
    end
  end

  # 散歩記録の更新処理（PATCH/PUT /walks/:id）
  def update
    # 散歩記録を更新
    if @walk.update(walk_params)
      # 更新に成功した場合、詳細ページにリダイレクトして成功メッセージを表示
      redirect_to @walk, notice: t("flash.walks.update.notice")
    else
      # 更新に失敗した場合（バリデーションエラー）、編集ページを再表示
      render :edit, status: :unprocessable_entity
    end
  end

  # 散歩記録の削除処理（DELETE /walks/:id）
  def destroy
    # 散歩記録を削除
    @walk.destroy
    # 一覧ページにリダイレクトして削除完了メッセージを表示
    redirect_to walks_path, notice: t("flash.walks.destroy.notice")
  end

  # Google Fitからデータをインポート（POST /walks/import_google_fit）
  def import_google_fit
    token_status = current_user.google_token_status

    case token_status
    when :not_connected
      redirect_to walks_path, alert: "Google Fitと連携してください。"
      return
    when :expired_need_reauth
      redirect_to walks_path, alert: "Google認証の有効期限が切れました。再度連携してください。"
      return
    when :temporary_error
      redirect_to walks_path, alert: "Googleとの通信に一時的な問題が発生しました。しばらく経ってから再試行してください。"
      return
    end

    service = GoogleFitService.new(current_user)
    # 直近30日分（今日を含む）
    end_date = Date.current
    start_date = end_date - 29.days

    result = service.fetch_activities(start_date, end_date)

    if result[:error]
      flash[:alert] = case result[:error]
      when :auth_expired
                        "Google認証の期限が切れました。再度連携してください。"
      when :rate_limited
                        result[:message]
      when :api_error
                        "Google Fit APIエラー: #{result[:message]}"
      else
                        "データの取得に失敗しました。"
      end
      redirect_to walks_path
      return
    end

    activities = result[:data]
    created_count = 0
    updated_count = 0
    failed_dates = []

    # トランザクションで囲むことでデータの一貫性を保証
    ActiveRecord::Base.transaction do
      activities.each do |date, data|
        # 距離が0以下の場合はスキップ（DBを汚さない）
        next if data[:distance] <= 0

        walk = current_user.walks.find_or_initialize_by(walked_on: date)

        # モデルのメソッドを使ってデータをマージ
        walk.merge_google_fit_data(data)

        # 何らかの変更があった場合のみ保存処理を続行
        if walk.changed?
          if walk.save
            if walk.previously_new_record?
              created_count += 1
            else
              updated_count += 1
            end
          else
            failed_dates << date
            Rails.logger.error "Failed to save walk for #{date}: #{walk.errors.full_messages.join(', ')}"
          end
        end
      end

      # 失敗があった場合はロールバック
      raise ActiveRecord::Rollback if failed_dates.any?
    end

    if failed_dates.any?
      flash[:alert] = "データの保存中にエラーが発生しました（日付: #{failed_dates.join(', ')}）。処理は中断されました。"
    elsif created_count > 0 || updated_count > 0
      flash[:notice] = "#{created_count}件の記録を作成、#{updated_count}件の記録を更新しました。"

      # データ更新があったので、ランキングOGP画像を強制再生成
      GenerateRankingOgpImageJob.perform_later(current_user, force: true)
    else
      flash[:info] = "新しいデータはありませんでした（または既存データの方が最新でした）。"
    end

    redirect_to walks_path
  end

  # 管理者用：ランダムな散歩記録を一瞬で作成（POST /walks/quick_create）
  def quick_create
    unless current_user.admin?
      redirect_to walks_path, alert: "管理者権限が必要です。"
      return
    end

    # ランダムなデータを生成（0.7〜1.6kmを基準）
    distance = rand(0.7..1.6).round(2)
    # 歩数: 1kmあたり約1,300歩（身長により若干変動）
    steps = (distance * 1300).to_i + rand(-100..100)
    # 時間: 1kmあたり約12〜15分（時速4〜5km）
    duration = (distance * rand(12..15)).to_i + rand(-2..2)
    # カロリー: 1kmあたり約40〜60kcal（体重により変動）
    calories = (distance * rand(40..60)).to_i

    # 最低値を保証
    steps = [steps, 500].max
    duration = [duration, 5].max
    calories = [calories, 20].max

    # 今日の記録があれば更新、なければ新規作成
    walk = current_user.walks.find_or_initialize_by(walked_on: Date.current)
    is_new_record = walk.new_record?

    walk.assign_attributes(
      distance: distance,
      steps: steps,
      duration: duration,
      calories_burned: calories,
      location: %w[近所の公園 河川敷 商店街 隣町まで 海沿い 近所のスーパー].sample,
      notes: nil,
      daypart: Walk.dayparts.keys.sample
    )

    if walk.save
      action_word = is_new_record ? "登録" : "上書き"
      redirect_to walks_path, notice: "⚡️テスト入力#{action_word}完了！ (#{distance}km, #{steps}歩)"
      # OGP画像の生成（非同期）
      GenerateRankingOgpImageJob.perform_later(current_user, force: true)
    else
      redirect_to walks_path, alert: "テスト入力失敗: #{walk.errors.full_messages.join(', ')}"
    end
  end

  private

  # 対象の散歩記録を取得するメソッド
  # ログインユーザーの散歩記録の中から、指定されたIDの記録を取得する
  # これにより、他のユーザーの散歩記録にアクセスできないようにする
  def set_walk
    @walk = current_user.walks.find(params[:id])
  end

  # フォームから送信されたパラメータを許可するメソッド
  # セキュリティのため、必要なパラメータだけを許可する
  def walk_params
    params.require(:walk).permit(:walked_on, :duration, :distance, :steps, :calories_burned, :location, :notes,
                                 :daypart)
  end
end
