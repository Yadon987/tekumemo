require 'rails_helper'

RSpec.describe "Posts", type: :system, js: true do
  let(:user) { FactoryBot.create(:user, email: "test@example.com", name: "テストユーザー") }
  let(:other_user) { FactoryBot.create(:user, email: "other@example.com", name: "他のユーザー") }

  before do
    login_as(user, scope: :user)
  end

  context "投稿がある場合" do
      before do
        # 他のユーザーの投稿を作成
        other_user.posts.create!(body: "今日はいい天気でした", weather: "sunny", feeling: "great")
        # 自分の投稿を作成
        user.posts.create!(body: "5km歩きました", weather: "cloudy", feeling: "good")
      end

      it "投稿一覧が表示されること" do
        visit posts_path
        expect(page).to have_content "今日はいい天気でした"
        expect(page).to have_content "5km歩きました"
        expect(page).to have_content "他のユーザー"
        expect(page).to have_content "テストユーザー"
    end
  end

  describe "新規投稿" do
    xit "新しい投稿を作成できること", js: true do
      visit posts_path
      expect(page).to have_content "みんな"

      # モーダルを開く（トリガーをクリック）
      sleep 1
      first(".cursor-pointer").click

      # フォームに入力
      within "#new_post_modal" do
        fill_in "post[body]", with: "新しい散歩の記録です！"
        # 天気を選択（ラジオボタン）
        choose "post_weather_sunny"
        # 気分を選択（ラジオボタン）
        choose "post_feeling_great"

        click_button "シェアする"
      end

      # 投稿完了のメッセージと投稿内容を確認
      expect(page).to have_content "投稿しました！"
      expect(page).to have_content "新しい散歩の記録です！"
      # 天気と気分の絵文字が表示されているか（sunny: ☀️, great: 😆）
      expect(page).to have_content "☀️"
      expect(page).to have_content "😆"
    end
  end

  describe "投稿の削除" do
    before do
      user.posts.create!(body: "削除する投稿", weather: "rainy", feeling: "tired")
      other_user.posts.create!(body: "他人の投稿", weather: "sunny", feeling: "great")
    end

    it "自分の投稿は削除できること", js: true do
      visit posts_path

      # 自分の投稿には削除ボタンがある
      # 削除ボタンはアイコン（delete）で探すか、リンクのhrefで探す
      # ここでは削除ボタンを含む要素内のテキストやクラスで特定

      # 削除確認ダイアログをOKする
      accept_confirm do
        # 自分の投稿の削除ボタンをクリック
        # 複数の投稿がある場合、特定が難しいので、一番新しい（上にある）ものを削除すると仮定
        first("a[data-turbo-method='delete']").click
      end

      expect(page).to have_content "投稿を削除しました"
      expect(page).not_to have_content "削除する投稿"
    end

    it "他人の投稿には削除ボタンが表示されないこと" do
      visit posts_path
      # 他人の投稿の要素内には削除ボタンがないことを確認したいが、
      # ページ全体で削除ボタンが1つもないことを確認する（自分の投稿がない場合）

      # 一旦自分の投稿を削除して、他人の投稿だけの状態にする
      user.posts.destroy_all
      visit posts_path

      expect(page).to have_content "他人の投稿"
      expect(page).not_to have_selector "a[data-turbo-method='delete']"
    end
  end

  describe "リアクション" do
    before do
      other_user.posts.create!(body: "リアクションしてね", weather: "sunny", feeling: "great")
    end

    it "他人の投稿にリアクションできること", js: true do
      visit posts_path

      # リアクション追加ボタンをクリック
      find("button[title='リアクションを追加']").click

      # ポップオーバーが表示されるのを待つ（タイムアウトを延長）
      using_wait_time(10) do
        expect(page).to have_selector("button", text: "👍", visible: true)
        # ピッカー内の「いいね」ボタンをクリック
        find("button", text: "👍").click

        # リアクション数が増えることを確認（非同期更新）
        expect(page).to have_selector(".reaction-btn", text: "1", visible: true)
      end
    end
  end
end
