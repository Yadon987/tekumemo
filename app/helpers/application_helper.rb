module ApplicationHelper
  # アバター画像を表示するヘルパー（既存のまま）
  def user_avatar(user, classes: "")
    if user.use_google_avatar && user.avatar_url.present?
      # Google連携のアバター画像を使用
      image_tag user.avatar_url, alt: user.name, class: "rounded-full #{classes}"
    else
      # イニシャル表示
      initials = user.name.present? ? user.name[0].upcase : "？"
      content_tag(:div, initials, class: "inline-flex items-center justify-center rounded-full bg-gradient-to-br from-blue-400 to-purple-500 text-white font-bold #{classes}")
    end
  end

  # 相対時刻表示（ソーシャルゲーム風）
  def time_ago_in_words_game_style(time)
    return "未ログイン" if time.nil?

    distance = Time.current - time
    minutes = (distance / 60).to_i
    hours = (distance / 3600).to_i
    days = (distance / 86400).to_i

    case
    when minutes < 1
      "1分未満"
    when minutes < 60
      "#{minutes}分前"
    when hours < 24
      "#{hours}時間前"
    when days < 30
      "#{days}日前"
    when days < 365
      "#{(days / 30).to_i}ヶ月前"
    else
      "#{(days / 365).to_i}年前"
    end
  end
end
