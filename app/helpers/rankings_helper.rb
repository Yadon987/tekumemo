module RankingsHelper
  def rank_color_class(rank)
    case rank
    when 1
      "bg-gradient-to-br from-yellow-300 to-yellow-500 text-yellow-900"
    when 2
      "bg-gradient-to-br from-slate-300 to-slate-400 text-slate-700"
    when 3
      "bg-gradient-to-br from-orange-300 to-orange-400 text-orange-800"
    else
      "bg-slate-100 text-slate-600"
    end
  end

  def rank_icon(rank)
    case rank
    when 1
      content_tag(:span, "🥇", class: "text-2xl animate-pulse")
    when 2
      content_tag(:span, "🥈", class: "text-2xl")
    when 3
      content_tag(:span, "🥉", class: "text-2xl")
    else
      content_tag(:span, rank, class: "text-lg font-black")
    end
  end

  def period_label_ja(period)
    case period
    when 'daily'
      '今日'
    when 'monthly'
      '今月'
    when 'yearly'
      '今年'
    else
      '今日'
    end
  end

  # 英語の序数サフィックスを返す（st, nd, rd, th）
  def ordinal_suffix(number)
    n = number.to_i.abs
    return 'th' if (11..13).include?(n % 100)

    case n % 10
    when 1 then 'st'
    when 2 then 'nd'
    when 3 then 'rd'
    else 'th'
    end
  end
end
