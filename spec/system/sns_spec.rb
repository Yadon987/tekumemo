require 'rails_helper'

RSpec.describe 'SNS機能', type: :system, js: true do
  let(:user) { create(:user) }
  let!(:other_post) { create(:post, body: '他人の投稿です') }

  before do
    login_as(user, scope: :user)
  end

  describe '新規投稿' do
    context '正常系' do
      it 'モーダルから投稿を作成できること' do
        visit posts_path
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
        visit posts_path
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
      visit posts_path
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

  describe '投稿の削除' do
    let!(:my_post) { create(:post, user: user, body: '削除する投稿') }

    it '自分の投稿は削除できること' do
      visit posts_path
      # 削除ボタンをクリック
      accept_confirm do
        # 自分の投稿内の削除ボタンを探す
        # 投稿の特定が難しい場合、bodyテキストを含む要素の親を辿るなどの工夫が必要だが、
        # ここではシンプルに削除ボタンを探す（自分の投稿にしか出ないはずなので）
        find("a[title='投稿を削除']").click
      end

      expect(page).to have_content '投稿を削除しました'
      expect(page).not_to have_content '削除する投稿'
    end

    it '他人の投稿には削除ボタンが表示されないこと' do
      visit posts_path
      # 他人の投稿（other_post）が表示されていることを確認
      expect(page).to have_content '他人の投稿です'

      # 他人の投稿の要素内には削除ボタンがないことを確認
      # 自分の投稿（my_post）も表示されているので、削除ボタン自体はページに存在する可能性がある
      # そのため、他人の投稿のスコープ内で削除ボタンがないことを確認する

      # 他人の投稿要素を特定（bodyテキストで検索）
      other_post_element = find('p', text: '他人の投稿です').find(:xpath, '../../..') # 構造に合わせて親要素へ

      within other_post_element do
        expect(page).not_to have_selector "a[data-turbo-method='delete']"
      end
    end
  end
end
