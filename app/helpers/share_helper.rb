module ShareHelper
  # X（旧Twitter）でシェアするURLを生成
  # @param text [String] ツイート本文
  # @param url [String] シェアするURL（省略可）
  # @param hashtags [Array<String>] ハッシュタグ（省略可）
  # @return [String] Twitter Web Intent URL
  def twitter_share_url(text:, url: nil, hashtags: [])
    params = {
      text: text,
      url: url,
      hashtags: hashtags.join(",")
    }.compact

    "https://twitter.com/intent/tweet?#{params.to_query}"
  end

  # 投稿をXでシェアするURLを生成
  def share_post_on_twitter_url(post)
    user = post.user

    # 今日の歩行距離
    today_distance = user.walks.where(walked_on: Date.current).sum(:distance)
    today_km = (today_distance / 1000.0).round(2)

    # 今月のランキング順位
    rankings = User.ranking(period: "monthly", limit: 1000).to_a
    user_in_ranking = rankings.find { |u| u.id == user.id }

    rank_str = "-"
    if user_in_ranking
      my_dist = user_in_ranking.total_distance.to_f
      higher_rankers = rankings.count { |u| u.total_distance.to_f > my_dist }
      rank_str = "#{higher_rankers + 1}th"
    end

    # メッセージ（投稿本文があれば優先、なければランダム）
    message = post.body.present? ? "「#{post.body.truncate(30)}」" : get_flavor_text(today_km)

    text = generate_rpg_text(distance: today_km, rank: rank_str, message: message)
    twitter_share_url(text: text)
  end

  # ランキングをXでシェアするURLを生成
  def share_ranking_on_twitter_url(user:, rank:, distance:, period: "monthly")
    distance_km = (distance / 1000.0).round(2)
    rank_str = rank ? "#{rank}th" : "-"

    # ランキングシェア時はランダムフレーバーテキスト
    message = get_flavor_text(distance_km)

    text = generate_rpg_text(distance: distance_km, rank: rank_str, message: message)
    twitter_share_url(text: text)
  end

  private

  def get_flavor_text(distance_km)
    flavor_texts = [
      "「いい気分転換になった！」",
      "「明日はどこまで行こうかな？」",
      "「継続は力なり！ナイス！」",
      "「歩いた後のご飯は美味しいぞ！」"
    ]
    # 5km以上歩いた時のレアメッセージ
    flavor_texts << "「伝説級のウォーキングだ...！」" if distance_km > 5.0
    flavor_texts.sample
  end

  def generate_rpg_text(distance:, rank:, message:)
    exp = (distance * 100).to_i

    <<~TEXT
      ✨ 𝐐𝐔𝐄𝐒𝐓 𝐂𝐎𝐌𝐏𝐋𝐄𝐓𝐄 ✨

      👟 𝐃𝐢𝐬𝐭𝐚𝐧𝐜𝐞 : #{distance}km
      👑 𝐑𝐚𝐧𝐤𝐢𝐧𝐠  : #{rank}

      ⚔️ 獲得経験値... #{exp} exp
      💬 #{message}
      ━━━━━━━━━━━━
      一緒に歩いて強くなろう🛡️
      👇
      https://tekumemo.onrender.com
      #てくメモ #RUNTEQ #散歩
    TEXT
  end
end
