module UsersHelper
  # ユーザーのアバターを表示するヘルパー
  # 使い方: <%= user_avatar(current_user, classes: "w-20 h-20 text-2xl") %>
  def user_avatar(user, classes: "w-12 h-12 text-lg")
    # 共通のスタイル（円形、中央寄せ、影など）
    base_classes = "rounded-full flex items-center justify-center font-bold shadow-md transition-transform hover:scale-105 #{classes}"

    if user.avatar_url.present? && user.use_google_avatar?
      # Googleのアバター画像がある場合
      image_tag user.avatar_url, alt: user.name, class: "#{base_classes} object-cover", referrerpolicy: "no-referrer"
    else
      # 画像がない場合：名前の頭文字2文字を取得して表示
      # 例: "Tech Memo" -> "TM", "山田太郎" -> "山田"
      initials = user.name.to_s.strip.slice(0, 2).upcase
      initials = "ゲスト" if initials.blank?

      # 背景色はグラデーションにする（アプリの雰囲気に合わせる）
      content_tag :div, class: "#{base_classes} bg-gradient-to-br from-blue-500 to-indigo-600 text-white" do
        initials
      end
    end
  end
end
