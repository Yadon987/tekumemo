class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  # POST /posts/:post_id/reactions
  # リアクションを追加（トグル動作）
  def create
    # 既に同じリアクションがあるか確認
    @reaction = @post.reactions.find_by(user: current_user, kind: reaction_params[:kind])

    if @reaction
      # 既にある場合は削除（トグル動作）
      @reaction.destroy
      @action = "removed"
    else
      # 新しいリアクションを作成
      @reaction = @post.reactions.build(reaction_params)
      @reaction.user = current_user

      unless @reaction.save
        # 保存失敗時
        respond_to do |format|
          format.json { render json: { error: "リアクションできませんでした" }, status: :unprocessable_entity }
          format.any { redirect_back(fallback_location: posts_path, alert: "リアクションできませんでした") }
        end
        return
      end
      @action = "added"
    end

    respond_to do |format|
      # JSON: Stimulusコントローラー用（優先）
      format.json do
        render json: {
          reacted: @action == "added",
          count: @post.reactions.where(kind: reaction_params[:kind]).count
        }
      end
      # Turbo Stream: リアクションボタンのみ更新（既存機能維持）
      format.turbo_stream
      # HTML: 通常のリダイレクト
      format.html { redirect_back(fallback_location: posts_path) }
    end
  end

  # DELETE /posts/:post_id/reactions/:id
  # リアクションを削除
  def destroy
    @reaction = @post.reactions.find_by(id: params[:id], user: current_user)

    if @reaction&.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back(fallback_location: posts_path) }
      end
    else
      redirect_back(fallback_location: posts_path, alert: "リアクションが見つかりませんでした")
    end
  end

  private

  # 対象の投稿を取得
  def set_post
    @post = Post.find(params[:post_id])
  end

  # 許可するパラメータ
  def reaction_params
    params.require(:reaction).permit(:kind)
  end
end
