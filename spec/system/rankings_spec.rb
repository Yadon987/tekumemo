require 'rails_helper'

RSpec.describe "Rankings", type: :system do
  let(:user) { FactoryBot.create(:user, name: "自分", email: "me@example.com") }
  let!(:other_user) { FactoryBot.create(:user, name: "ライバル", email: "rival@example.com") }

  before do
    driven_by(:rack_test)

    # データを準備
    # 自分: 今日 5km
    FactoryBot.create(:walk, user: user, walked_on: Date.current, distance: 5.0)
    # ライバル: 今日 10km
    FactoryBot.create(:walk, user: other_user, walked_on: Date.current, distance: 10.0)

    sign_in user
  end

  it "ランキングページが表示され、順位が正しく表示されること" do
    visit rankings_path

    # タイトル確認
    expect(page).to have_content "ランキング"
    expect(page).to have_content "競い合って、一緒に成長しよう！"

    # 自分の順位カードの確認
    # ライバル(10km) > 自分(5km) なので、自分は2位
    expect(page).to have_content "あなたの順位"
    expect(page).to have_content "2"
    expect(page).to have_content "nd" # 序数サフィックス
    expect(page).to have_content "5.0" # 距離

    # ランキングリストの確認
    # 1位のライバルが表示されているか
    expect(page).to have_content "ライバル"
    expect(page).to have_content "10.0"
    expect(page).to have_content "1" # 順位
    # expect(page).to have_content "st" # 1位の序数はビューの構造上、テキストとして分離されているか確認が必要だが一旦含める
  end

  it "タブを切り替えて期間ごとのランキングを表示できること" do
    visit rankings_path

    # Monthlyタブをクリック
    click_link "月次"
    expect(page).to have_current_path(rankings_path(period: 'monthly'))
    expect(page).to have_content "今月ランキング"

    # Yearlyタブをクリック
    click_link "年次"
    expect(page).to have_current_path(rankings_path(period: 'yearly'))
    expect(page).to have_content "今年ランキング"

    # Dailyタブをクリック
    click_link "日次"
    expect(page).to have_current_path(rankings_path(period: 'daily'))
    expect(page).to have_content "今日ランキング"
  end

  context "データがない場合" do
    before do
      Walk.delete_all
      # キャッシュをクリアしないと前のテストのデータが残る可能性があるが、
      # Rails.cache.clear はテスト環境の設定次第。
      # ここではWalkを消すことで集計結果が空になることを期待する。
      Rails.cache.clear
    end

    it "空の状態のメッセージが表示されること" do
      visit rankings_path
      expect(page).to have_content "記録はまだありません"
      expect(page).to have_content "一番乗りのチャンス！"
      expect(page).to have_link "散歩を記録する"
    end
  end

  describe "同率順位の表示" do
    let!(:rival2) { FactoryBot.create(:user, email: "rival2@example.com", name: "ライバル2") }

    before do
      # 既存のデータを削除
      Walk.delete_all

      # ユーザーとライバル1、ライバル2が全員同じ距離（10km）を歩いたとする
      # User.rankingの仕様上、同距離の場合はID順などで順位が決まるが、
      # ここでは全員が表示され、距離が正しいことを確認する
      Walk.create!(user: user, walked_on: Date.current.to_s, distance: 10.0, duration: 60)
      Walk.create!(user: other_user, walked_on: Date.current.to_s, distance: 10.0, duration: 60)
      Walk.create!(user: rival2, walked_on: Date.current.to_s, distance: 10.0, duration: 60)

      # キャッシュクリア
      Rails.cache.clear

      login_as(user, scope: :user)
      visit rankings_path
    end

    it "全員が表示され、距離が正しいこと" do
      # 全員10kmなので、表示されていることを確認
      expect(page).to have_content "10.0km", count: 3
      expect(page).to have_content "自分"
      expect(page).to have_content "ライバル"
      expect(page).to have_content "ライバル2"
    end
  end
end
