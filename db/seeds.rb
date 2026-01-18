# frozen_string_literal: true

# db/seeds.rb

puts "🌱 Starting seeding..."

# 0. 実績マスターデータ作成
puts 'Creating achievements...'
achievements_data = [
  { title: '初めの一歩', flavor_text: '初めて歩数を記録した', metric: :total_steps, requirement: 1,
    badge_key: 'footprint' },
  { title: 'ウォーキングビギナー', flavor_text: '累計10,000歩を達成した', metric: :total_steps, requirement: 10_000,
    badge_key: 'directions_walk' },
  { title: 'ウォーキングマスター', flavor_text: '累計100,000歩を達成した', metric: :total_steps, requirement: 100_000,
    badge_key: 'hiking' },
  { title: 'マラソンランナー', flavor_text: '累計42kmを達成した', metric: :total_distance, requirement: 42,
    badge_key: 'sports_score' },
  { title: '地球一周', flavor_text: '累計40,000kmを達成した', metric: :total_distance, requirement: 40_000,
    badge_key: 'public' },
  { title: '三日坊主卒業', flavor_text: '3日連続でログインした', metric: :login_streak, requirement: 3,
    badge_key: 'history' },
  { title: '習慣化の達人', flavor_text: '30日連続でログインした', metric: :login_streak, requirement: 30,
    badge_key: 'calendar_month' },
  { title: '初めての投稿', flavor_text: '初めて日記を投稿した', metric: :post_count, requirement: 1,
    badge_key: 'edit_note' },
  { title: '日記職人', flavor_text: '日記を10回投稿した', metric: :post_count, requirement: 10,
    badge_key: 'library_books' }
]

achievements_data.each do |data|
  Achievement.find_or_create_by!(title: data[:title]) do |a|
    a.flavor_text = data[:flavor_text]
    a.metric = data[:metric]
    a.requirement = data[:requirement]
    a.badge_key = data[:badge_key]
  end
end

# 1. キャラクター設定（20人）
CHARACTERS = [
  { name: '竈門炭治郎', email: 'user1@example.com', quotes: ['頑張れ炭治郎頑張れ！', '俺は長男だから我慢できたけど次男だったら我慢できなかった。', '心を燃やせ！'] },
  { name: 'うずまきナルト', email: 'user2@example.com', quotes: ['まっすぐ自分の言葉は曲げねぇ。それが俺の忍道だ！', '俺は火影になる男だ！', 'だってばよ！'] },
  { name: 'モンキー・D・ルフィ', email: 'user3@example.com', quotes: ['海賊王に俺はなる！', '当たり前だ！！！！！', '腹減った〜！'] },
  { name: 'エドワード・エルリック', email: 'user4@example.com',
    quotes: ['立てよド三流。オレ達とおまえとの格の違いってやつを見せてやる！', '等価交換だ！', '降りてこいよド三流！'] },
  { name: '孫悟空', email: 'user5@example.com', quotes: ['オッス！オラ悟空！', 'クリリンのことかーっ！！！！！', 'ワクワクすっぞ！'] },
  { name: 'アーニャ・フォージャー', email: 'user6@example.com', quotes: ['アーニャ、ピーナッツが好き。', 'わくわく！', 'ちち、はは、仲良し！'] },
  { name: 'フリーレン', email: 'user7@example.com', quotes: ['ヒンメルならそうした。', '人の心を知る旅に出ることにしたの。', '魔法を集めるのが趣味だからね。'] },
  { name: '木之本桜', email: 'user8@example.com', quotes: ['絶対だいじょうぶだよ。', '汝のあるべき姿に戻れ！クロウカード！', 'ほえ〜！'] },
  { name: '月野うさぎ', email: 'user9@example.com', quotes: ['月にかわっておしおきよ！', '愛と正義のセーラー服美少女戦士、セーラームーン！', 'まもちゃん！'] },
  { name: '鹿目まどか', email: 'user10@example.com', quotes: ['クラスのみんなには内緒だよ！', '私、魔法少女になる。', 'もう何も怖くない。'] },
  { name: '五条悟', email: 'user11@example.com', quotes: ['大丈夫、僕最強だから。', '領域展開、無量空処。', '少し乱暴しようか。'] },
  { name: 'ロイド・フォージャー', email: 'user12@example.com', quotes: ['黄昏だ。', 'スマートにこなすのが私の流儀だ。', 'アーニャ、勉強の時間だ。'] },
  { name: 'ヨル・フォージャー', email: 'user13@example.com', quotes: ['息の根を止めて差し上げます。', '私、殺し屋ですので。', 'ロイドさん、素敵です！'] },
  { name: '工藤新一', email: 'user14@example.com', quotes: ['真実はいつもひとつ！', 'バーロー。', '推理に勝ったも負けたも、上も下もねーよ。'] },
  { name: '毛利蘭', email: 'user15@example.com', quotes: ['新一のバカ！', 'もう、どこ行ってたのよ！', '空手なら負けないわよ。'] },
  { name: 'キリト', email: 'user16@example.com', quotes: ['スターバースト・ストリーム！', '俺はビーターだ。', 'アスナは俺が守る。'] },
  { name: 'アスナ', email: 'user17@example.com', quotes: ['キリト君は私が守る。', '閃光のアスナよ。', '一緒に頑張ろうね。'] },
  { name: '坂田銀時', email: 'user18@example.com', quotes: ['糖分が足りねぇ。', '万事屋銀ちゃんのお通りだ！', 'ジャンプ読むの忙しいんだよ。'] },
  { name: '神楽', email: 'user19@example.com', quotes: ['酢昆布よこすアル。', '定春、噛み付くアル！', '銀ちゃん、お腹空いたネ。'] },
  { name: '志摩リン', email: 'user20@example.com', quotes: ['買っちった。', '焚き火、いいなぁ。', 'ソロキャン最高。'] }
]

# ランダムな日本の市
CITIES = %w[札幌市 仙台市 さいたま市 千葉市 横浜市 川崎市 相模原市 新潟市 静岡市 浜松市 名古屋市 京都市 大阪市 堺市 神戸市
            岡山市 広島市 北九州市 福岡市 熊本市]

puts 'Start seeding...'

# 全ユーザーを先に確保（リアクション用）
users = []
CHARACTERS.each do |char_data|
  user = User.find_or_create_by!(email: char_data[:email]) do |u|
    u.name = char_data[:name]
    u.password = 'password'
    u.password_confirmation = 'password'
  end
  users << user
end

# 各ユーザーについてデータ作成
users.each_with_index do |user, index|
  char_data = CHARACTERS[index]
  puts "Processing user: #{user.name}"

  # ---------------------------------------------------------
  # A. 過去30日分 + 今日 (0..30)
  # ---------------------------------------------------------
  (0..30).each do |day|
    date = Date.today - day.days

    # 既にその日の記録があればスキップ（重複防止）
    next if user.walks.exists?(walked_on: date)

    # 今日(day=0)は100%、それ以外は60%の確率で歩く
    probability = day == 0 ? 1.0 : 0.6
    next unless rand < probability

    # 距離: 0.1km 〜 0.6km のランダム
    distance = rand(0.1..0.6).round(2)

    # 歩数・時間・カロリー概算
    steps = (distance * 1300 * rand(0.9..1.1)).to_i
    duration = (distance * 15 * rand(0.9..1.1)).to_i
    calories = (distance * 50 * rand(0.9..1.1)).to_i

    # 作成時刻ランダム
    if day == 0
      hours_ago = rand(1..24)
      walk_time = Time.current - hours_ago.hours - rand(0..59).minutes
    else
      walk_time = date.to_time + rand(6..22).hours + rand(0..59).minutes
    end

    walk = user.walks.create!(
      walked_on: date,
      kilometers: distance,
      steps: steps,
      minutes: duration,
      calories: calories,
      location: CITIES.sample,
      created_at: walk_time,
      updated_at: walk_time
    )

    # SNS投稿（30%）
    next unless rand < 0.3

    pattern = %i[content_only weather_only feeling_only weather_feeling all].sample
    content = nil
    weather = nil
    feeling = nil

    case pattern
    when :content_only
      content = char_data[:quotes].sample
    when :weather_only
      weather = Post.weathers.keys.sample
    when :feeling_only
      feeling = Post.feelings.keys.sample
    when :weather_feeling
      weather = Post.weathers.keys.sample
      feeling = Post.feelings.keys.sample
    when :all
      content = char_data[:quotes].sample
      weather = Post.weathers.keys.sample
      feeling = Post.feelings.keys.sample
    end

    # 投稿時刻は散歩時刻の10分〜2時間後（ただし現在時刻は超えない）
    max_post_delay = day == 0 ? [(Time.current - walk_time - 1.minute).to_i / 60, 120].min : 120
    post_delay = rand(10..[max_post_delay, 10].max).minutes
    post_time = walk_time + post_delay
    post = user.posts.create!(
      content: content,
      weather: weather,
      feeling: feeling,
      walk: walk,
      created_at: post_time,
      updated_at: post_time
    )

    # リアクション（3〜8人）
    users.sample(rand(3..8)).each do |reactor|
      next if reactor == user
      next if post.reactions.exists?(user: reactor)

      reaction_time = post_time + rand(1..180).minutes
      post.reactions.create!(
        user: reactor,
        stamp: Reaction.stamps.keys.sample,
        created_at: reaction_time,
        updated_at: reaction_time
      )
    end
  end

  # ---------------------------------------------------------
  # B. 未来7日分 (1..7) - 900m以下
  # ---------------------------------------------------------
  (1..7).each do |day_offset|
    date = Date.today + day_offset.days
    next if user.walks.exists?(walked_on: date)

    distance = rand(0.1..0.6).round(2)
    steps = (distance * 1300 * rand(0.9..1.1)).to_i
    duration = (distance * 15 * rand(0.9..1.1)).to_i
    calories = (distance * 50 * rand(0.9..1.1)).to_i
    walk_time = date.to_time + rand(6..22).hours + rand(0..59).minutes

    user.walks.create!(
      walked_on: date,
      kilometers: distance,
      steps: steps,
      minutes: duration,
      calories: calories,
      location: CITIES.sample,
      created_at: walk_time,
      updated_at: walk_time
    )
  end
end

# 実績付与のシミュレーション
puts 'Assigning achievements...'
all_achievements = Achievement.all
users.each do |user|
  total_steps = user.walks.sum(:steps)
  # 累計距離
  total_distance = user.walks.sum(:kilometers)
  # 投稿数
  post_count = user.posts.count

  all_achievements.each do |achievement|
    earned = case achievement.metric.to_sym
    when :total_steps
               total_steps >= achievement.requirement
    when :total_distance
               total_distance >= achievement.requirement
    when :post_count
               post_count >= achievement.requirement
    when :login_streak
               # シードデータではログイン履歴を厳密に作っていないのでランダムで付与
               rand < 0.5
    else
               false
    end

    UserAchievement.find_or_create_by!(user: user, achievement: achievement) if earned
  end
end

puts "✨ Seeding completed successfully!"
