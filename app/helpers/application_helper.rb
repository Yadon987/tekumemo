module ApplicationHelper
  # 相対時刻表示（ソーシャルゲーム風）
  def time_ago_in_words_game_style(time)
    return "未ログイン" if time.nil?

    distance = Time.current - time
    minutes = (distance / 60).to_i
    hours = (distance / 3600).to_i
    days = (distance / 86_400).to_i

    if minutes < 1
      "1分未満"
    elsif minutes < 60
      "#{minutes}分前"
    elsif hours < 24
      "#{hours}時間前"
    elsif days < 30
      "#{days}日前"
    elsif days < 365
      "#{(days / 30).to_i}ヶ月前"
    else
      "#{(days / 365).to_i}年前"
    end
  end
end
