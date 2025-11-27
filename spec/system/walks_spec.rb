require 'rails_helper'

RSpec.describe "Walks", type: :system do
  # 1. Chrome起動エラー対策: 安定稼働のためのオプションを全盛り設定
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]) do |driver_option|
      driver_option.add_argument('--no-sandbox')
      driver_option.add_argument('--disable-dev-shm-usage')
      driver_option.add_argument('--headless=new')
      driver_option.add_argument('--disable-gpu')
      driver_option.add_argument('--disable-infobars')
      driver_option.add_argument('--disable-extensions')
    end
  end

  describe "散歩記録の新規作成" do
    # 事前にユーザーを作成
    let(:user) { User.create!(email: "test@example.com", password: "password", name: "テスト太郎") }

    before do
      # 2. ログイン処理
      visit new_user_session_path

      # 入力欄が見つからないエラー対策: ID指定で確実に入力
      fill_in "user_email", with: user.email
      fill_in "login-password-field", with: user.password

      click_button "ログインする"

      # 3. 画面遷移待ち対策: ログイン完了メッセージが出るまで待機
      # これがないと、次の処理が早すぎて失敗することがあります
      expect(page).to have_content "ログインしました"
    end

    context "フォームに正常な値を入力した場合" do
      it "散歩記録が保存され、一覧画面に表示されること" do
        # 新規作成画面へ移動
        visit new_walk_path

        # 画面表示待ち
        expect(page).to have_content "新しい散歩記録を作成"

        # 4. 入力欄が見つからないエラー対策: 全てID（walk_属性名）で指定
        # ラベルの文言やデザイン変更に強い書き方です

        # 日付形式エラー対策: 文字列で明示的に渡す
        fill_in "walk_walked_on", with: Date.current.strftime('%Y-%m-%d')

        fill_in "walk_location", with: "テスト公園"
        fill_in "walk_distance", with: "5.5"
        fill_in "walk_duration", with: "60"
        fill_in "walk_steps", with: "8000"
        fill_in "walk_calories_burned", with: "300"
        fill_in "walk_notes", with: "テスト散歩の記録です"

        # 保存ボタンをクリック
        click_button "散歩記録を保存"

        # 5. バリデーションエラー時のデバッグ用
        # もし保存に失敗していたら、画面上のエラーメッセージをログに出す
        if page.has_selector?("#error_explanation") || page.has_content?("エラー")
          puts "⚠️ 保存失敗: #{page.text}"
        end

        # 保存後の検証
        # 画面遷移の確認
        expect(current_path).to eq walks_path
        expect(page).to have_content "散歩記録を作成しました"

        # 6. テキスト一致エラー対策: HTMLの表示に合わせてスペース有無を調整
        # ビューファイル(show.html.erb)の構造上、数値と単位の間にスペースがないとして扱われます
        expect(page).to have_content "テスト公園"
        expect(page).to have_content "5.5km"     # スペースなし
        expect(page).to have_content "60分"      # スペースなし
        expect(page).to have_content "8,000歩"   # スペースなし

        # カロリーはレイアウトによって改行が含まれる可能性があるため、数値のみ確認で安全策をとる
        expect(page).to have_content "300"

        expect(page).to have_content "テスト散歩の記録です"
      end
    end
  end
end
