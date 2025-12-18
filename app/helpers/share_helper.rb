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

    # 投稿詳細ページのURLを含める（OGP画像表示のため）
    post_url = post_url(post, host: request.host, protocol: request.protocol)

    text = generate_rpg_text(distance: today_km, rank: rank_str, message: message)
    # URLとハッシュタグの間に改行を入れるため、ハッシュタグをテキストに含める
    text += "\n#てくメモ #RUNTEQ #散歩"
    twitter_share_url(text: text, url: post_url)
  end

  # ランキングをXでシェアするURLを生成
  def share_ranking_on_twitter_url(user:, rank:, distance:, period: "monthly")
    distance_km = (distance / 1000.0).round(2)
    rank_str = rank ? "#{rank}位" : "-"

    # ランキングシェア時はランダムフレーバーテキスト
    message = get_ranking_flavor_text(rank)

    # ランキングページのURLを含める（OGP画像表示のため）
    # 環境に応じて動的にURLを生成
    ranking_url = rankings_url(host: request.host, protocol: request.protocol, user_id: user.id)

    text = generate_rpg_text(distance: distance_km, rank: rank_str, message: message, type: :ranking)
    twitter_share_url(text: text, url: ranking_url)
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

  def get_ranking_flavor_text(rank)
    case rank
    when 1
      "「栄光の第1位！素晴らしい！」"
    when 2..3
      "「トップ3入り！すごい！」"
    when 4..10
      "「トップ10入り！頑張った！」"
    else
      "「今週もお疲れ様でした！」"
    end
  end

  def generate_rpg_text(distance:, rank:, message:, type: :quest)
    exp = (distance * 100).to_i

    if type == :ranking
      <<~TEXT
        🏆 𝐑𝐀𝐍𝐊𝐈𝐍𝐆 𝐂𝐇𝐀𝐌𝐏𝐈𝐎𝐍 🏆

        👟 𝐃𝐢𝐬𝐭𝐚𝐧𝐜𝐞 : #{distance}km
        👑 𝐑𝐚𝐧𝐤𝐢𝐧𝐠  : #{rank}

        💬 #{message}
        ━━━━━━━━━━━━
        一緒に歩いて強くなろう🛡️
      TEXT
    else
      <<~TEXT
        ✨ 𝐐𝐔𝐄𝐒𝐓 𝐂𝐎𝐌𝐏𝐋𝐄𝐓𝐄 ✨

        👟 𝐃𝐢𝐬𝐭𝐚𝐧𝐜𝐞 : #{distance}km
        👑 𝐑𝐚𝐧𝐤𝐢𝐧𝐠  : #{rank}

        ⚔️ 獲得経験値... #{exp} exp
        💬 #{message}
        ━━━━━━━━━━━━
        一緒に歩いて強くなろう🛡️
        👇
      TEXT
    end
  end
end
