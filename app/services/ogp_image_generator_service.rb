# MiniMagickはBundler.requireで自動読み込みされる

class OgpImageGeneratorService
  def initialize(post)
    @post = post
  end

  def generate
    require "mini_magick" unless defined?(MiniMagick)

    # 1. 黒背景の生成 (1200x630)
    # systemコマンドで確実に生成する（Tempfileで並行リクエストの競合を回避）
    temp_file = Tempfile.new([ "ogp_base", ".png" ])
    base_image_path = temp_file.path
    temp_file.close # 重要: パスを使う前に閉じる

    # 処理後に削除するために後でunlinkするが、TempfileオブジェクトがGCされると消えるので注意
    # 1. ベース画像の生成 (1200x630)
    # 背景色をダークネイビー(#0f172a)に変更
    image = ::MiniMagick::Image.open(base_image_path)
    # image = ::MiniMagick::Image.open(base_image_path) # この行は削除される

    font_path = Rails.root.join("public/fonts/MPLUS1p-Bold.ttf").to_s

    # Walkデータの取得（直接紐付け or 同日の記録）
    walk = @post.walk || @post.user.walks.find_by(walked_on: @post.created_at.to_date)

    # ---    # ベース画像の生成 (1200x630, 背景色: #0f172a)
    # MiniMagick::Tool::Convert が不安定なため、確実なsystemコマンドに戻す
    # systemコマンドの引数を配列にすることでシェル経由の実行を回避（セキュリティ対策）
    system("convert", "-size", "1200x630", "xc:#0f172a", base_image_path)

    image = ::MiniMagick::Image.new(base_image_path)

    # --- アバター画像の処理 ---
    avatar_path = Tempfile.new([ "avatar", ".png" ]).path
    avatar_size = 360
    user = @post.user
    avatar_used = false

    if user.avatar_url.present? && user.use_google_avatar
      begin
        # Googleアバター画像のダウンロード
        require "open-uri"
        # タイムアウトを設定して、外部要因での遅延を防ぐ
        URI.open(user.avatar_url, read_timeout: 3, open_timeout: 3) do |f|
          File.binwrite(avatar_path, f.read)
        end

        # リサイズとトリミング (360x360) - MiniMagickで処理してプロセス起動コストを削減
        avatar = ::MiniMagick::Image.new(avatar_path)
        avatar.combine_options do |c|
          c.resize "#{avatar_size}x#{avatar_size}^"
          c.gravity "center"
          c.extent "#{avatar_size}x#{avatar_size}"
        end
        avatar_used = true
      rescue => e
        Rails.logger.error "Failed to download avatar: #{e.message}"
        # 失敗時はフォールバックへ
      end
    end

    unless avatar_used
      # フォールバック: イニシャル画像 (2文字)
      initial = user.name[0..1].upcase rescue "U"

      # 背景: 青(#3b82f6) - systemコマンドで確実に生成
      system("convert", "-size", "#{avatar_size}x#{avatar_size}", "xc:#3b82f6", avatar_path)

      # 文字合成はMiniMagickで行う
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

    # --- 3. 描画処理 (枠線・テキスト・アバター合成を一括実行) ---
    # プロセス起動回数を減らすため、compositeを使わずdraw imageで合成する
    image.combine_options do |c|
      c.font font_path

      # アバター合成 (draw image Over x,y w,h 'filename')
      # 座標: +50+120, サイズ: 360x360
      c.draw "image Over 50,120 360,360 '#{avatar_path}'"

      # --- ヘッダーエリア ---
      # タイトル枠
      c.fill "none"
      c.stroke "#fbbf24" # 金色
      c.strokewidth 3
      c.draw "roundrectangle 50,30 500,100 10,10"

      # タイトルテキスト "QUEST COMPLETE"
      c.stroke "none"
      c.fill "#fbbf24"
      c.gravity "NorthWest"
      c.pointsize 40
      c.annotate "+85+35", "QUEST COMPLETE" # 位置調整 (Y:40->35, X:70->85)

      # 日付 (右上のデジタル時計風)
      c.fill "#94a3b8" # 薄いグレー
      c.pointsize 30
      c.gravity "NorthEast"
      date_text = walk&.walked_on&.strftime("%Y-%m-%d") || @post.created_at.strftime("%Y-%m-%d")
      c.annotate "+50+45", date_text

      # --- 左側: アバター枠 & 情報 ---
      c.fill "none"
      c.stroke "#cbd5e1" # シルバー
      c.strokewidth 4
      c.draw "rectangle 50,120 410,480" # アバター枠 (360x360)

      # ユーザー名プレート
      c.fill "#1e293b" # 濃い背景
      c.stroke "#cbd5e1"
      c.strokewidth 2
      # 下端を 550 -> 600 に変更（右側のステータスバーに合わせる）
      c.draw "rectangle 50,480 410,600"

      # ラベル "PLAYER"
      c.stroke "none"
      c.fill "#94a3b8" # ラベル色
      c.pointsize 20
      c.gravity "NorthWest"
      c.annotate "+65+490", "PLAYER"

      # ユーザー名
      c.fill "#ffffff"

      # 文字数に応じたフォントサイズ自動調整
      # 枠幅: 約340px
      clean_name = strip_emoji(user.name)
      user_name = clean_name.truncate(20) # 最大20文字まで

      # 簡易的な文字幅計算 (全角を1、半角を0.5として計算するのが理想だが、ここでは文字数で簡易判定)
      # 日本語メインと仮定して、文字数で段階的にサイズを下げる
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

      # フォントサイズに応じてY座標を微調整（文字が小さいと上に寄って見えるため）
      y_pos = 530
      y_pos += 5 if font_size < 40

      c.annotate "+65+#{y_pos}", user_name

      # Lvバッジ (黄色い四角)
      c.fill "#fbbf24"
      c.draw "rectangle 330,450 410,480"
      c.fill "#000000"
      c.pointsize 22 # 24 -> 22 に縮小
      # Lv = 総歩数 / 5000 + 1 (5000歩ごとにレベルアップ)
      total_steps = user.walks.sum(:steps)
      level = (total_steps / 5000) + 1
      c.annotate "+340+453", "Lv.#{level}" # 位置を微調整

      # --- 右側: メッセージウィンドウ ---
      c.fill "none"
      c.stroke "#cbd5e1"
      c.strokewidth 3
      c.draw "roundrectangle 440,120 1150,480 10,10"

      # メッセージ本文
      c.stroke "none"
      c.fill "#ffffff"
      c.gravity "NorthWest"
      c.pointsize 36 # 32 -> 36 に少し戻して視認性を上げる
      # c.interline_spacing -5 # 行間詰めは削除して自然な間隔に

      if @post.body.present?
        # 改行をスペースに置換して1行にしてからtruncateする（予期せぬ改行によるはみ出し防止）
        clean_text = strip_emoji(@post.body).gsub(/\R/, " ").squeeze(" ")
        # 70文字だとギリギリ溢れることがあるので65文字に微調整
        body_text = clean_text.truncate(65)
        # フォントサイズ36に合わせて1行17文字程度に調整
        wrapped_body = wrap_text(body_text, 17)
      else
        # デフォルトメッセージは手動で改行しているのでwrap_textを通さない
        wrapped_body = "冒険の記録が更新されました！\n明日もまた、新たな旅へ出かけよう。"
      end

      c.annotate "+480+160", wrapped_body

      # --- 下部: ステータスバー ---
      # 枠組み (3分割)
      c.fill "none"
      c.stroke "#cbd5e1"
      c.strokewidth 2
      # 左: Distance
      c.draw "rectangle 440,500 660,600"
      # 中: Exp (Steps)
      c.draw "rectangle 680,500 900,600"
      # 右: Location/Weather
      c.draw "rectangle 920,500 1150,600"

      # ラベルと値
      c.stroke "none"
      c.fill "#94a3b8" # ラベル色
      c.pointsize 20

      # Distance
      c.annotate "+460+510", "DISTANCE"
      c.fill "#fbbf24" # 値色(金)
      c.pointsize 40
      dist = walk&.distance || 0
      c.annotate "+480+540", "#{dist} km"

      # Exp (Steps)
      c.fill "#94a3b8"
      c.pointsize 20
      c.annotate "+700+510", "EXP (STEPS)"
      c.fill "#fbbf24"
      c.pointsize 40
      steps = walk&.steps || 0
      c.annotate "+720+540", "#{steps}"

      # Location
      c.fill "#94a3b8"
      c.pointsize 20
      c.annotate "+940+510", "LOCATION"
      c.fill "#ffffff"
      c.pointsize 36 # 34 -> 36 に拡大
      loc = walk&.location.presence || "TekuMemo"
      c.annotate "+950+545", strip_emoji(loc).truncate(10) # 位置調整 (X:960->950, Y:550->545)
    end
    File.unlink(avatar_path) if File.exist?(avatar_path)

    image.format "jpg"
    blob = image.to_blob
    image.destroy!
    File.unlink(base_image_path) if File.exist?(base_image_path)

    blob
  end

  private

  def wrap_text(text, max_width)
    text.scan(/.{1,#{max_width}}/m).join("\n")
  end

  def strip_emoji(text)
    # 簡易的な絵文字除去
    text.to_s.gsub(/[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}]/, "")
  end
end
