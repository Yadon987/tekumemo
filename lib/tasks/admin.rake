namespace :admin do
  desc "現在の管理者ユーザーを表示"
  task list: :environment do
    admins = User.where(role: "admin")

    if admins.any?
      puts "=" * 60
      puts "現在の管理者ユーザー（#{admins.count}名）"
      puts "=" * 60
      admins.each do |user|
        puts "ID: #{user.id}"
        puts "名前: #{user.name}"
        puts "メール: #{user.email}"
        puts "登録日: #{user.created_at.strftime('%Y-%m-%d %H:%M')}"
        puts "-" * 60
      end
    else
      puts "管理者ユーザーが存在しません"
    end
  end

  desc "指定したメールアドレスのユーザーに管理者権限を付与"
  task :grant, [ :email ] => :environment do |t, args|
    email = args[:email] || ENV["ADMIN_EMAIL"]

    if email.blank?
      puts "エラー: メールアドレスが指定されていません"
      puts "使用方法: rake admin:grant[email@example.com]"
      puts "または: ADMIN_EMAIL=email@example.com rake admin:grant"
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "エラー: メールアドレス '#{email}' のユーザーが見つかりません"
      exit 1
    end

    if user.admin?
      puts "ユーザー '#{user.name}' (#{user.email}) は既に管理者です"
    else
      user.update!(role: "admin")
      puts "✅ 成功: ユーザー '#{user.name}' (#{user.email}) に管理者権限を付与しました"
    end
  end

  desc "指定したメールアドレスのユーザーから管理者権限を削除"
  task :revoke, [ :email ] => :environment do |t, args|
    email = args[:email] || ENV["ADMIN_EMAIL"]

    if email.blank?
      puts "エラー: メールアドレスが指定されていません"
      puts "使用方法: rake admin:revoke[email@example.com]"
      puts "または: ADMIN_EMAIL=email@example.com rake admin:revoke"
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "エラー: メールアドレス '#{email}' のユーザーが見つかりません"
      exit 1
    end

    if user.general?
      puts "ユーザー '#{user.name}' (#{user.email}) は既に一般ユーザーです"
    else
      user.update!(role: "general")
      puts "✅ 成功: ユーザー '#{user.name}' (#{user.email}) から管理者権限を削除しました"
    end
  end
end
