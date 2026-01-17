require 'rails_helper'

RSpec.describe 'UI Components', type: :system, js: true do
  let(:user) { create(:user, name: 'Test User', goal_meters: 5000) }

  before do
    login_as(user, scope: :user)
  end

  describe '共通背景アニメーション' do
    it 'ホーム画面に背景アニメーション要素が表示されること' do
      visit root_path
      # オーブ要素の確認 (クラス名で検索)
      # _animated_background.html.erb 内の要素
      expect(page).to have_selector('.animate-pulse-slow')
    end

    it 'ログイン画面に背景アニメーション要素が表示されること' do
      logout(:user)
      visit new_user_session_path
      expect(page).to have_selector('.animate-pulse-slow')
    end
  end

  describe '物理演算カルーセル (ホーム画面)' do
    before do
      visit root_path
    end

    it 'カルーセルコントローラーが適用されていること' do
      expect(page).to have_selector('[data-controller="carousel"]')
    end

    it 'スライド要素が表示されていること' do
      # カルーセルの中身があることを確認
      expect(page).to have_selector('[data-carousel-target="slide"]')
    end
  end

  describe 'ドラッグスクロール (統計ページ)' do
    before do
      # 統計データを作成 (称号を表示させるため)
      create(:walk, user: user, walked_on: Date.current, kilometers: 5.0)
      visit stats_path
    end

    it 'ドラッグスクロールコントローラーが適用されていること' do
      # アコーディオンを開く必要があるかもしれないが、コントローラー自体はDOMに存在するはず
      # アコーディオンの中にあるため、まずはアコーディオンを開く
      find('button[data-action="click->accordion#toggle"]').click

      # アニメーション待ち
      expect(page).to have_selector('[data-controller="scroll-drag"]', visible: true)
    end

    it '称号リストが表示されていること' do
      find('button[data-action="click->accordion#toggle"]').click
      expect(page).to have_content('冒険の始まり') # 最初の散歩で獲得できる称号
    end
  end

  describe 'Crystal Claymorphism デザイン適用確認' do
    it 'ホーム画面のカードにデザインクラスが適用されていること' do
      visit root_path
      # rounded-[3.75rem] を持つ要素があるか確認 (Crystal Claymorphismの特徴)
      expect(page).to have_selector('.rounded-\\[3\\.75rem\\]')
    end

    it '統計ページのカードにデザインクラスが適用されていること' do
      visit stats_path
      expect(page).to have_selector('.crystal-card')
    end

    it '設定画面のカードにデザインクラスが適用されていること' do
      visit edit_user_registration_path
      # rounded-[2.5rem] の代わりに backdrop-blur-2xl (すりガラス効果) を確認
      expect(page).to have_css('.backdrop-blur-2xl')
    end
  end
end
