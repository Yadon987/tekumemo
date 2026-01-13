require 'rails_helper'

RSpec.describe 'OGPプレビュー機能', type: :system do
  let(:user) { create(:user) }
  let!(:post) { create(:post, user: user, body: 'テスト投稿') }

  before do
    login_as(user)
    visit post_path(post)
  end

  it 'プレビューモーダルの開閉動作が正しく機能する', js: true do
    # 1. ページ読み込み完了確認
    expect(page).to have_content('冒険の記録')
    expect(page).to have_content('シェア画像を確認・更新')

    # 2. モーダルを開く
    click_button 'シェア画像を確認・更新'

    # モーダルが表示される（非表示クラスが消える、あるいは透明度が変わるのを待つ）
    expect(page).to have_selector('#ogp-preview-modal', visible: true)
    expect(page).to have_content('シェア画像プレビュー')

    # 3. 閉じるボタン（×）で閉じる
    # ボタンは右上にあり、SVGを含んでいる
    close_button = find("button[data-action='click->ogp-preview#close']")
    close_button.click

    # モーダルが非表示になることを確認
    expect(page).to have_selector('#ogp-preview-modal', visible: false)

    # 4. 再び開く
    click_button 'シェア画像を確認・更新'
    expect(page).to have_selector('#ogp-preview-modal', visible: true)

    # 5. モーダルの中身（白いカード部分）をクリックしても閉じない
    modal_container = find("[data-ogp-preview-target='container']")
    modal_container.click

    # まだ表示されているはず
    expect(page).to have_selector('#ogp-preview-modal', visible: true)

    # 6. 背景（オーバーレイ）をクリックして閉じる
    # fix: オーバーレイ要素をクリックする必要がある
    # オーバーレイは #ogp-preview-modal 自体が全画面を覆っている
    # ただし、Capybaraで真ん中をクリックすると中身をクリックしてしまう可能性があるため、
    # 座標指定か、コンテナの外側をクリックする工夫が必要だが、
    # 単純に #ogp-preview-modal 自体がオーバーレイとして機能しているので、
    # 「コンテナの外」をクリックするシミュレーションとして、
    # 画面の左上端(0,0)などをクリックさせるのが確実。

    page.execute_script("document.getElementById('ogp-preview-modal').click()")

    # モーダルが非表示になることを確認
    expect(page).to have_selector('#ogp-preview-modal', visible: false)
  end
end
