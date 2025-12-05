module PostsHelper
  # 投稿の天気・気分スコアに基づいてカラーテーマを決定する
  # 強度スコアに基づく配色ロジック（高スコア＝Vivid, 低スコア＝Pastel）
  def post_color_theme(post)
    # 1. 各要素の強度スコアを定義（同点なし）
    weather_scores = {
      'stormy' => 9,    # 嵐：最強（Vivid Purple）
      'snowy' => 6,     # 雪：強い（Bright Sky）
      'sunny' => 5,     # 晴れ：中強（Bright Orange）
      'rainy' => 4,     # 雨：中弱（Soft Blue）
      'cloudy' => 1     # 曇り：弱い（Soft Gray）
    }

    feeling_scores = {
      'exhausted' => 8, # ヘトヘト：最強（Vivid Rose）
      'great' => 7,     # 最高：強い（Bright Yellow）
      'tired' => 3,     # 疲れた：中弱（Soft Slate）
      'good' => 2,      # 良い：弱い（Soft Lime）
      'normal' => 0     # 普通：最弱（Soft Stone）
    }

    # 2. 現在の投稿のスコアを取得
    w_score = weather_scores[post.weather] || 0
    f_score = feeling_scores[post.feeling] || 0

    # 3. スコア比較で勝者を決定
    winner = if w_score > f_score
               { type: 'weather', key: post.weather, score: w_score }
             elsif f_score > w_score
               { type: 'feeling', key: post.feeling, score: f_score }
             else
               # 万が一同点なら天気を優先
               { type: 'weather', key: post.weather, score: w_score }
             end

    # 4. 勝者に基づいたカラーテーマ定義
    # Light: Claymorphism (Puni-Puni)
    # Dark: Neon Noir / Synthwave (Atmospheric Glow)
    case winner[:key]
    # === Lv.High (Ultraviolet & Hot Pink) ===
    when 'stormy'
      {
        bg: 'bg-[#faf5ff] dark:bg-[#1a0b2e]/90',
        border: 'border-purple-100/50 dark:border-purple-500/50',
        text: 'text-purple-800 dark:text-purple-200',
        inner_bg: 'bg-purple-50/50 dark:bg-purple-900/30',
        shadow: 'shadow-[8px_8px_16px_rgba(168,85,247,0.15),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_30px_rgba(168,85,247,0.4),inset_0_0_20px_rgba(168,85,247,0.1)]'
      }
    when 'exhausted'
      {
        bg: 'bg-[#fff1f2] dark:bg-[#2e0b16]/90',
        border: 'border-rose-100/50 dark:border-rose-500/50',
        text: 'text-rose-800 dark:text-rose-200',
        inner_bg: 'bg-rose-50/50 dark:bg-rose-900/30',
        shadow: 'shadow-[8px_8px_16px_rgba(244,63,94,0.15),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_30px_rgba(244,63,94,0.4),inset_0_0_20px_rgba(244,63,94,0.1)]'
      }

    # === Lv.Mid (Sunset Gradient Glow) ===
    when 'great'
      {
        bg: 'bg-[#fffbeb] dark:bg-[#2e200b]/90',
        border: 'border-yellow-100/50 dark:border-yellow-500/50',
        text: 'text-yellow-700 dark:text-yellow-200',
        inner_bg: 'bg-yellow-50/50 dark:bg-yellow-900/30',
        shadow: 'shadow-[8px_8px_16px_rgba(234,179,8,0.15),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_30px_rgba(234,179,8,0.3),inset_0_0_20px_rgba(234,179,8,0.1)]'
      }
    when 'snowy'
      {
        bg: 'bg-[#f0f9ff] dark:bg-[#0b1e2e]/90',
        border: 'border-sky-100/50 dark:border-cyan-400/50',
        text: 'text-sky-700 dark:text-cyan-200',
        inner_bg: 'bg-sky-50/50 dark:bg-cyan-900/30',
        shadow: 'shadow-[8px_8px_16px_rgba(14,165,233,0.15),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_30px_rgba(34,211,238,0.4),inset_0_0_20px_rgba(34,211,238,0.1)]'
      }
    when 'sunny'
      {
        bg: 'bg-[#fff7ed] dark:bg-[#2e150b]/90',
        border: 'border-orange-100/50 dark:border-orange-500/50',
        text: 'text-orange-700 dark:text-orange-200',
        inner_bg: 'bg-orange-50/50 dark:bg-orange-900/30',
        shadow: 'shadow-[8px_8px_16px_rgba(249,115,22,0.15),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_30px_rgba(249,115,22,0.4),inset_0_0_20px_rgba(249,115,22,0.1)]'
      }

    # === Lv.Low (Midnight Blue Glow) ===
    when 'rainy'
      {
        bg: 'bg-[#eff6ff] dark:bg-[#0b102e]/90',
        border: 'border-blue-100/50 dark:border-blue-500/50',
        text: 'text-blue-600 dark:text-blue-200',
        inner_bg: 'bg-blue-50/50 dark:bg-blue-900/30',
        shadow: 'shadow-[8px_8px_16px_rgba(59,130,246,0.1),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_30px_rgba(59,130,246,0.3),inset_0_0_20px_rgba(59,130,246,0.1)]'
      }
    when 'tired'
      {
        bg: 'bg-[#f8fafc] dark:bg-[#0f172a]/90',
        border: 'border-slate-100/50 dark:border-slate-500/50',
        text: 'text-slate-600 dark:text-slate-300',
        inner_bg: 'bg-slate-50/50 dark:bg-slate-800/50',
        shadow: 'shadow-[8px_8px_16px_rgba(100,116,139,0.1),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_20px_rgba(148,163,184,0.2),inset_0_0_10px_rgba(148,163,184,0.05)]'
      }
    when 'good'
      {
        bg: 'bg-[#f7fee7] dark:bg-[#142e0b]/90',
        border: 'border-lime-100/50 dark:border-lime-500/50',
        text: 'text-lime-600 dark:text-lime-200',
        inner_bg: 'bg-lime-50/50 dark:bg-lime-900/30',
        shadow: 'shadow-[8px_8px_16px_rgba(132,204,22,0.1),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_30px_rgba(132,204,22,0.3),inset_0_0_20px_rgba(132,204,22,0.1)]'
      }
    when 'cloudy'
      {
        bg: 'bg-[#f9fafb] dark:bg-[#111827]/90',
        border: 'border-gray-100/50 dark:border-gray-600/50',
        text: 'text-gray-500 dark:text-gray-300',
        inner_bg: 'bg-gray-50/50 dark:bg-gray-800/50',
        shadow: 'shadow-[8px_8px_16px_rgba(107,114,128,0.1),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_20px_rgba(156,163,175,0.2),inset_0_0_10px_rgba(156,163,175,0.05)]'
      }

    # === Default ===
    else
      {
        bg: 'bg-[#fafaf9] dark:bg-[#1c1917]/90',
        border: 'border-stone-100/50 dark:border-stone-600/50',
        text: 'text-stone-500 dark:text-stone-300',
        inner_bg: 'bg-stone-50/50 dark:bg-stone-900/50',
        shadow: 'shadow-[8px_8px_16px_rgba(166,175,195,0.4),-8px_-8px_16px_rgba(255,255,255,0.8)] dark:shadow-[0_0_20px_rgba(168,162,158,0.2),inset_0_0_10px_rgba(168,162,158,0.05)]'
      }
    end
  end
end
