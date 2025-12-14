class Admin::AnnouncementsController < Admin::BaseController
  before_action :set_announcement, only: %i[edit update destroy publish unpublish]

  # お知らせ一覧
  def index
    @announcements = Announcement.order(published_at: :desc, created_at: :desc).page(params[:page]).per(20)
  end

  # 新規作成フォーム
  def new
    @announcement = Announcement.new
  end

  # 作成処理
  def create
    @announcement = Announcement.new(announcement_params)

    if @announcement.save
      redirect_to admin_announcements_path, notice: "お知らせを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 編集フォーム
  def edit
  end

  # 更新処理
  def update
    if @announcement.update(announcement_params)
      redirect_to admin_announcements_path, notice: "お知らせを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @announcement.destroy
    redirect_to admin_announcements_path, notice: "お知らせを削除しました"
  end

  # 公開
  def publish
    # 公開日時が未設定の場合のみ現在時刻を設定
    published_at = @announcement.published_at || Time.current
    @announcement.update(is_published: true, published_at: published_at)
    redirect_to admin_announcements_path, notice: "お知らせを公開しました"
  end

  # 非公開
  def unpublish
    @announcement.update(is_published: false)
    redirect_to admin_announcements_path, notice: "お知らせを非公開にしました"
  end

  private



  def set_announcement
    @announcement = Announcement.find(params[:id])
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content, :announcement_type, :published_at, :expires_at, :priority)
  end
end
