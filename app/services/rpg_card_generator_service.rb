class RpgCardGeneratorService
  # レイアウト定数
  IMAGE_SIZE = "1200x630".freeze
  AVATAR_SIZE = 360
  AVATAR_POS = "50,120".freeze

  # ヘッダー
  HEADER_TITLE_POS = "+85+35".freeze
  HEADER_DATE_POS = "+50+45".freeze

  # 左カラム
  PLAYER_LABEL_POS = "+65+490".freeze
  USER_NAME_BASE_Y = 530
  LV_BADGE_POS = "+340+453".freeze

  # 右カラム
  MESSAGE_POS = "+480+160".freeze

  # ステータスバー
  STATUS_LABEL_Y = 510
  STATUS_VALUE_Y = 540
  STATUS_COL1_X = 460 # Distance/Rank
  STATUS_COL2_X = 700 # Steps
  STATUS_COL3_X = 940 # Location

  def initialize(user:, title:, message:, stats: {}, theme: :quest)
    @user = user
    @title = title
    @message = message
    @stats = stats
    @theme = theme
  end

  def generate
    require "mini_magick" unless defined?(MiniMagick)

    base_tempfile = nil
    avatar_tempfile = nil
    base_image_path = nil
    avatar_path = nil

    begin
      # 1. ベース画像生成
      base_tempfile = Tempfile.new([ "ogp_base", ".png" ])
      base_image_path = base_tempfile.path
      base_tempfile.close

      # 背景色設定
      colors = theme_colors
      system("convert", "-size", IMAGE_SIZE, "xc:#{colors[:background]}", base_image_path)

      image = ::MiniMagick::Image.new(base_image_path)
      font_path = Rails.root.join("public/fonts/MPLUS1p-Bold.ttf").to_s

      # 2. アバター画像の準備
      avatar_tempfile, avatar_path = prepare_avatar_image

      # 3. 描画処理一括実行
      image.combine_options do |c|
        c.font font_path

        # アバター合成
        c.draw "image Over #{AVATAR_POS} #{AVATAR_SIZE},#{AVATAR_SIZE} '#{avatar_path}'"

        # --- ヘッダーエリア ---
        # タイトル枠
        c.fill "none"
        c.stroke colors[:accent]
        c.strokewidth 3
        c.draw "roundrectangle 50,30 500,100 10,10"

        # タイトルテキスト
        c.stroke "none"
        c.fill colors[:accent]
        c.gravity "NorthWest"
        c.pointsize 40
        c.annotate HEADER_TITLE_POS, @title

        # 日付 (右上のデジタル時計風)
        c.fill colors[:text_secondary]
        c.pointsize 30
        c.gravity "NorthEast"
        date_text = @stats[:date] || Time.current.strftime("%Y-%m-%d")
        c.annotate HEADER_DATE_POS, date_text

        # --- 左側: アバター枠 & 情報 ---
        c.fill "none"
        c.stroke colors[:border]
        c.strokewidth 4
        c.draw "rectangle 50,120 410,480" # アバター枠

        # ユーザー名プレート
        c.fill colors[:panel_bg]
        c.stroke colors[:border]
        c.strokewidth 2
        c.draw "rectangle 50,480 410,600"

        # ラベル "PLAYER"
        c.stroke "none"
        c.fill colors[:text_secondary]
        c.pointsize 20
        c.gravity "NorthWest"
        c.annotate PLAYER_LABEL_POS, "PLAYER"

        # ユーザー名
        c.fill colors[:text_primary]
        draw_user_name(c, @user.name)

        # Lvバッジ
        if @stats[:level].present?
          c.fill colors[:accent]
          c.draw "rectangle 330,450 410,480"
          c.fill "#000000"
          c.pointsize 22
          c.annotate LV_BADGE_POS, "Lv.#{@stats[:level]}"
        end

        # --- 右側: メッセージウィンドウ ---
        c.fill "none"
        c.stroke colors[:border]
        c.strokewidth 3
        c.draw "roundrectangle 440,120 1150,480 10,10"

        # メッセージ本文
        c.stroke "none"
        c.fill colors[:text_primary]
        c.gravity "NorthWest"
        c.pointsize 36

        draw_message_body(c, @message)

        # --- 下部: ステータスバー ---
        draw_status_bar(c, colors)
      end

      image.format "jpg"
      blob = image.to_blob
      image.destroy!

      blob
    ensure
      # 確実にTempfileをクリーンアップ
      avatar_tempfile&.close!
      base_tempfile&.close!
    end
  end

  private

  def theme_colors
    case @theme
    when :ranking
      {
        background: "#1a0b2e", # Deep Purple
        text_primary: "#ffffff",
        text_secondary: "#a78bfa", # Light Purple
        accent: "#ffd700", # Gold
        border: "#8b5cf6", # Violet
        panel_bg: "#2e1065" # Darker Purple
      }
    else # :quest (default)
      {
        background: "#0f172a", # Dark Navy
        text_primary: "#ffffff",
        text_secondary: "#94a3b8", # Slate 400
        accent: "#fbbf24", # Amber 400 (Gold-ish)
        border: "#cbd5e1", # Slate 300
        panel_bg: "#1e293b" # Slate 800
      }
    end
  end

  def prepare_avatar_image
    avatar_tempfile = Tempfile.new([ "avatar", ".png" ])
    avatar_path = avatar_tempfile.path
    avatar_used = false

    if @user.avatar_url.present? && @user.use_google_avatar
      begin
        require "open-uri"
        URI.open(@user.avatar_url, read_timeout: 3, open_timeout: 3) do |f|
          File.binwrite(avatar_path, f.read)
        end

        avatar = ::MiniMagick::Image.new(avatar_path)
        avatar.combine_options do |c|
          c.resize "#{AVATAR_SIZE}x#{AVATAR_SIZE}^"
          c.gravity "center"
          c.extent "#{AVATAR_SIZE}x#{AVATAR_SIZE}"
        end
        avatar_used = true
      rescue => e
        Rails.logger.error "Failed to download avatar: #{e.message}"
      end
    end

    unless avatar_used
      # フォールバック: イニシャル画像
      initial = @user.name[0..1].upcase rescue "U"
      system("convert", "-size", "#{AVATAR_SIZE}x#{AVATAR_SIZE}", "xc:#3b82f6", avatar_path)

      font_path = Rails.root.join("public/fonts/MPLUS1p-Bold.ttf").to_s
      temp_img = ::MiniMagick::Image.new(avatar_path)
      temp_img.combine_options do |c|
        c.font font_path
        c.gravity "Center"
        c.pointsize 150
        c.fill "#ffffff"
        c.annotate "+0+0", initial
      end
      temp_img.write(avatar_path)
    end

    # Tempfileオブジェクトとパスの両方を返す（ensureブロックでクリーンアップできるように）
    [ avatar_tempfile, avatar_path ]
  end

  def draw_user_name(c, name)
    clean_name = strip_emoji(name)
    user_name = clean_name.truncate(20)

    font_size = if user_name.length <= 6
                  50
    elsif user_name.length <= 10
                  35
    elsif user_name.length <= 15
                  24
    else
                  18
    end

    c.pointsize font_size
    y_pos = USER_NAME_BASE_Y
    y_pos += 5 if font_size < 40
    c.annotate "+65+#{y_pos}", user_name
  end

  def draw_message_body(c, message)
    if message.present?
      clean_text = strip_emoji(message).gsub(/\R/, " ").squeeze(" ")
      body_text = clean_text.truncate(65)
      wrapped_body = wrap_text(body_text, 17)
    else
      wrapped_body = "冒険の記録が更新されました！\n明日もまた、新たな旅へ出かけよう。"
    end
    c.annotate MESSAGE_POS, wrapped_body
  end

  def draw_status_bar(c, colors)
    # 枠組み (3分割)
    c.fill "none"
    c.stroke colors[:border]
    c.strokewidth 2

    # 左: Distance / Rank
    c.draw "rectangle 440,500 660,600"
    # 中: Exp (Steps)
    c.draw "rectangle 680,500 900,600"
    # 右: Location / Period
    c.draw "rectangle 920,500 1150,600"

    # ラベルと値
    c.stroke "none"
    c.fill colors[:text_secondary]
    c.pointsize 20

    # Item 1 (Distance or Rank)
    label1 = @stats[:label1] || "DISTANCE"
    value1 = @stats[:value1] || "0 km"
    c.annotate "+#{STATUS_COL1_X}+#{STATUS_LABEL_Y}", label1
    c.fill colors[:accent]
    c.pointsize 40
    c.annotate "+#{STATUS_COL1_X + 20}+#{STATUS_VALUE_Y}", value1.to_s

    # Item 2 (Steps)
    c.fill colors[:text_secondary]
    c.pointsize 20
    label2 = @stats[:label2] || "EXP (STEPS)"
    value2 = @stats[:value2] || "0"
    c.annotate "+#{STATUS_COL2_X}+#{STATUS_LABEL_Y}", label2
    c.fill colors[:accent]
    c.pointsize 40
    c.annotate "+#{STATUS_COL2_X + 20}+#{STATUS_VALUE_Y}", value2.to_s

    # Item 3 (Location or Period)
    c.fill colors[:text_secondary]
    c.pointsize 20
    label3 = @stats[:label3] || "LOCATION"
    value3 = @stats[:value3] || "TekuMemo"
    c.annotate "+#{STATUS_COL3_X}+#{STATUS_LABEL_Y}", label3
    c.fill colors[:text_primary]
    c.pointsize 36
    c.annotate "+#{STATUS_COL3_X + 10}+#{STATUS_VALUE_Y + 5}", strip_emoji(value3).truncate(10)
  end

  def wrap_text(text, max_width)
    text.scan(/.{1,#{max_width}}/m).join("\n")
  end

  def strip_emoji(text)
    # 基本的な絵文字範囲 + 異体字セレクタなどを除去
    # 完全にすべての絵文字を除去するのは難しいが、主要な範囲をカバー
    text.to_s.scrub('')
        .gsub(/[\u{1F300}-\u{1F9FF}]/, "") # Miscellaneous Symbols and Pictographs
        .gsub(/[\u{2600}-\u{26FF}]/, "")   # Miscellaneous Symbols
        .gsub(/[\u{2700}-\u{27BF}]/, "")   # Dingbats
        .gsub(/[\u{1F600}-\u{1F64F}]/, "") # Emoticons
        .gsub(/[\u{1F680}-\u{1F6FF}]/, "") # Transport and Map Symbols
        .gsub(/[\u{1F900}-\u{1F9FF}]/, "") # Supplemental Symbols and Pictographs
        .gsub(/[\u{1FA70}-\u{1FAFF}]/, "") # Symbols and Pictographs Extended-A
        .gsub(/\u{FE0F}/, "")              # Variation Selector-16 (emoji style)
        .strip
  end
end
