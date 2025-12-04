require 'rails_helper'

RSpec.describe "Rankings", type: :system do
  let(:user) { FactoryBot.create(:user, name: "自分", email: "me@example.com") }
  let!(:other_user) { FactoryBot.create(:user, name: "ライバル", email: "rival@example.com") }

  before do
    driven_by(:rack_test)

    # データを準備
    # 自分: 今日 5km
    FactoryBot.create(:walk, user: user, walked_on: Date.today, distance: 5.0)
    # ライバル: 今日 10km
    FactoryBot.create(:walk, user: other_user, walked_on: Date.today, distance: 10.0)

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
end
