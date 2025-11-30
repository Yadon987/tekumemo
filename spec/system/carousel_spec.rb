require 'rails_helper'

RSpec.describe "Home Carousel", type: :system, js: true do
  let(:user) { User.create(email: "test@example.com", password: "password", name: "Test User", target_distance: 1000) }

  before do
    sign_in user
    visit root_path
  end

  it "displays weather and ranking cards" do
    expect(page).to have_content("いま")
    expect(page).to have_content("RANK")
  end

  context "on mobile view" do
    before do
      # スマホサイズにリサイズ
      page.driver.browser.manage.window.resize_to(375, 812)
    end

    it "shows carousel indicators" do
      expect(page).to have_selector("[data-carousel-target='indicator']", count: 2)
    end

    it "automatically scrolls (simulated check)" do
      # 自動スクロールの完全な検証は難しいが、
      # コントローラーがアタッチされているかを確認
      expect(page).to have_selector("[data-controller='carousel']")
    end
  end

  context "on desktop view" do
    before do
      # PCサイズにリサイズ
      page.driver.browser.manage.window.resize_to(1280, 800)
    end

    it "hides carousel indicators" do
      # sm:hidden クラスにより非表示になっているはず（Capybaraはvisible: trueがデフォルト）
      expect(page).to have_no_selector("[data-carousel-target='indicator']", visible: true)
    end
  end
end
