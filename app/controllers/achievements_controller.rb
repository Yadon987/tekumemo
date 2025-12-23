class AchievementsController < ApplicationController
  before_action :authenticate_user!

  def index
    @achievements = Achievement.all
    # ユーザーが獲得済みの実績IDのリストを取得（ビューでの判定を高速化するため）
    @earned_achievement_ids = current_user.user_achievements.pluck(:achievement_id)
  end
end
