class GuestCleanupService
  # 削除対象のゲストユーザーを確認
  def self.check_guests
    User.where(role: :guest)
        .or(User.where("email LIKE ?", "guest_%"))
        .or(User.where("name LIKE ?", "%guest%"))
        .or(User.where("name LIKE ?", "%ゲスト%"))
  end

  # 孤立データのカウントを取得
  def self.count_orphans
    {
      walks: Walk.where.not(user_id: User.select(:id)).count,
      posts: Post.where.not(user_id: User.select(:id)).count,
      achievements: UserAchievement.where.not(user_id: User.select(:id)).count,
      notifications: Notification.where.not(user_id: User.select(:id)).count,
      reactions: Reaction.where.not(user_id: User.select(:id)).count,
      web_push_subscriptions: WebPushSubscription.where.not(user_id: User.select(:id)).count
    }
  end

  # 孤立データの削除
  def self.clean_orphans!
    deleted_counts = {}
    
    deleted_counts[:reactions] = Reaction.where.not(user_id: User.select(:id)).delete_all
    deleted_counts[:notifications] = Notification.where.not(user_id: User.select(:id)).delete_all
    deleted_counts[:achievements] = UserAchievement.where.not(user_id: User.select(:id)).delete_all
    deleted_counts[:web_push_subscriptions] = WebPushSubscription.where.not(user_id: User.select(:id)).delete_all
    deleted_counts[:posts] = Post.where.not(user_id: User.select(:id)).delete_all
    deleted_counts[:walks] = Walk.where.not(user_id: User.select(:id)).delete_all
    
    deleted_counts
  end

  # ゲストユーザーとそのデータの削除
  def self.clean_users!
    targets = User.where(role: :guest).where("email LIKE ?", "guest_%@example.com")
    deleted_count = 0
    
    targets.find_each do |user|
      user.reactions.delete_all
      user.notifications.delete_all
      user.user_achievements.delete_all
      user.posts.delete_all
      user.walks.delete_all
      user.destroy
      deleted_count += 1
    end
    
    deleted_count
  end
end
