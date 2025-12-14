require 'rails_helper'

RSpec.describe 'SNS機能', type: :system, js: true do
  let(:user) { create(:user) }
  let!(:other_post) { create(:post, body: '他人の投稿です') }

  before do
    login_as(user, scope: :user)
    visit posts_path
  end

  describe '新規投稿' do
    context '正常系' do
      it 'モーダルから投稿を作成できること' do
        # モーダルを開く
        find('[data-action="click->modal#open"]').click
        # モーダルが開くのを待つ
        modal = find('dialog#new_post_modal[open]')

        within modal do
          # フォーム入力
          # 天気を選択（sunny）
          find('label', text: '晴れ', visible: true).click
          # 気分を選択（great）
          find('label', text: '最高', visible: true).click
          # 本文を入力
          fill_in 'post[body]', with: 'テスト投稿です！'

          # 送信
          click_button '投稿する'
        end

        # モーダルが閉じ、投稿が一覧に追加されていることを確認
        expect(page).to have_content 'テスト投稿です！'
        expect(page).to have_content '投稿しました'
      end
    end

    context '異常系' do
      it '入力不備がある場合、エラーメッセージが表示されること' do
        find('[data-action="click->modal#open"]').click

        # 何も入力せずに送信
        # HTML5バリデーションを無効化して送信（サーバーサイドのバリデーションをテストするため）
        execute_script("document.querySelector('form').noValidate = true")
        click_button '投稿する'

        # エラーメッセージの確認
        expect(page).to have_content '本文、天気、気分、散歩記録のいずれか1つは入力してください'

        # モーダルが開いたままであること
        expect(page).to have_selector 'dialog#new_post_modal[open]'
      end
    end
  end

  describe 'リアクション機能' do
    it '投稿に「いいね」できること' do
      # 投稿内のリアクションエリアを特定
      within first('.group.relative') do
        # 「＋」ボタン（リアクション追加）をクリックしてポップオーバーを開く
        find('button[title="リアクションを追加"]').click

        # ポップオーバー内の「いいね」ボタンをクリック
        # ポップオーバーは絶対配置でbody直下などに出る可能性があるが、
        # 実装では .relative の中にあるので within の中で探せるはず
        # もし見つからない場合は page.find で探す

        # ポップオーバーが表示されるのを待つ
        expect(page).to have_selector('[data-popover-target="content"]', visible: true)

        # 「いいね」ボタン（thumbs_up）をクリック
        # id="picker-btn-{post.id}-thumbs_up" だが、post.idが不明なので部分一致などで探す
        # または絵文字で探す
        find('button', text: '👍').click

        # カウントが1になることを確認
        expect(page).to have_content '1'
      end
    end
  end
end
