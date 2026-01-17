module UsersHelper
  # ユーザーのアバターを表示するヘルパー
  # 使い方: <%= user_avatar(current_user, classes: "w-20 h-20 text-2xl") %>
  def user_avatar(user, classes: "w-12 h-12 text-lg",
                  default_color_classes: "bg-gradient-to-br from-blue-500 to-indigo-600 text-white")
    # 共通のスタイル（円形、中央寄せ、影など）
    base_classes = "rounded-full flex items-center justify-center font-bold shadow-md transition-transform hover:scale-105 #{classes}"

    avatar_source = user.display_avatar_url

    if avatar_source.is_a?(ActiveStorage::Attached::One) && avatar_source.attached?
      # アップロード画像（Active Storage）
      image_tag avatar_source, alt: user.name, class: "#{base_classes} object-cover"
    elsif avatar_source.is_a?(String)
      # Google画像（URL）
      image_tag avatar_source, alt: user.name, class: "#{base_classes} object-cover", referrerpolicy: "no-referrer"
    else
      # デフォルト：名前の頭文字3文字を取得して表示
      # 例: "Tech Memo" -> "TEC", "山田太郎" -> "山田太"
      initials = user.name.to_s.strip.slice(0, 3).upcase
      initials = "ゲスト" if initials.blank?

      # 3文字の場合、枠に収まるようにフォントサイズを小さくし、文字間を詰める
      # whitespace-nowrap: 改行禁止
      # leading-none: 行間を詰めて垂直中央寄せを安定させる
      adjust_class = initials.length >= 3 ? "text-[0.7em] tracking-tighter whitespace-nowrap leading-none" : "whitespace-nowrap leading-none"

      # 背景色はグラデーションにする（アプリの雰囲気に合わせる）
      content_tag :div, class: "#{base_classes} #{default_color_classes}" do
        content_tag :span, initials, class: adjust_class
      end
    end
  end
end
