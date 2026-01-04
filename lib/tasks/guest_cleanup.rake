namespace :guest do
  desc "Check for guest users and orphaned data"
  task check: :environment do
    puts "=== 1. Suspicious User Accounts ==="
    users = User.where(role: :guest)
                .or(User.where("email LIKE ?", 'guest_%'))
                .or(User.where("name LIKE ?", '%guest%'))
                .or(User.where("name LIKE ?", '%ゲスト%'))

    if users.exists?
      users.find_each do |u|
        puts "User ID: #{u.id}, Name: #{u.name}, Email: #{u.email}, Role: #{u.role}"
      end
    else
      puts "No suspicious user accounts found."
    end

    puts "\n=== 2. Orphaned Data (Records without valid User) ==="
    
    # Userが存在しないWalk
    orphaned_walks = Walk.where.not(user_id: User.select(:id))
    puts "Orphaned Walks: #{orphaned_walks.count}"
    
    # Userが存在しないPost
    orphaned_posts = Post.where.not(user_id: User.select(:id))
    puts "Orphaned Posts: #{orphaned_posts.count}"
    
    # Userが存在しないUserAchievement
    orphaned_achievements = UserAchievement.where.not(user_id: User.select(:id))
    puts "Orphaned UserAchievements: #{orphaned_achievements.count}"
    
    # Userが存在しないNotification
    orphaned_notifications = Notification.where.not(user_id: User.select(:id))
    puts "Orphaned Notifications: #{orphaned_notifications.count}"

    # Userが存在しないReaction
    orphaned_reactions = Reaction.where.not(user_id: User.select(:id))
    puts "Orphaned Reactions: #{orphaned_reactions.count}"
  end

  desc "Clean up orphaned data"
  task clean_orphans: :environment do
    puts "Cleaning up orphaned data..."
    
    Reaction.where.not(user_id: User.select(:id)).delete_all
    Notification.where.not(user_id: User.select(:id)).delete_all
    UserAchievement.where.not(user_id: User.select(:id)).delete_all
    Post.where.not(user_id: User.select(:id)).delete_all
    Walk.where.not(user_id: User.select(:id)).delete_all
    
    puts "Done."
  end

  desc "Clean up actual guest users (strict check)"
  task clean_users: :environment do
    puts "Searching for guest users to delete..."
    # 条件: roleがguest かつ emailが guest_ で始まり @example.com で終わるもの
    # これにより一般ユーザーや開発用アカウントの誤削除を防ぐ
    targets = User.where(role: :guest).where("email LIKE ?", "guest_%@example.com")
    
    count = targets.count
    if count == 0
      puts "No guest users found matching the strict criteria."
      next
    end

    puts "Found #{count} guest users. Deleting..."
    
    targets.find_each do |user|
      print "Deleting User ID: #{user.id} (#{user.email})... "
      
      # SessionsController#destroy と同様に、関連データを高速削除
      user.reactions.delete_all
      user.notifications.delete_all
      user.user_achievements.delete_all
      # 依存関係順序: posts -> walks
      user.posts.delete_all
      user.walks.delete_all
      
      # 本体削除
      user.destroy
      puts "Done."
    end
    puts "All specified guest users have been removed."
  end
end
