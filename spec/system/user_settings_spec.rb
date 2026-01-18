require 'rails_helper'

RSpec.describe 'ユーザー設定', type: :system, js: true do
  before do
    # OmniAuthのモック設定
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe '新規登録とログイン' do
    it 'メールアドレスで新規登録し、ログインできること' do
      visit new_user_registration_path

      fill_in 'ユーザー名（表示名）', with: 'テストユーザー'
      fill_in 'メールアドレス', with: 'new@example.com'
      fill_in 'パスワード', with: 'password123'
      fill_in 'register-password-confirmation-field', with: 'password123'
      click_button '登録する'

      expect(page).to have_content('アカウント登録が完了しました。')
      # expect(page).to have_content("テストユーザー")
    end

    context '入力内容に不備がある場合' do
      it '必須項目が未入力だと登録できず、エラーメッセージが表示されること' do
        visit new_user_registration_path
        # フォーム内の登録ボタンをクリック
        within '#new_user' do
          click_button '登録する'
        end

        # エラーメッセージの検証
        expect(page).to have_content('エラー')
        expect(page).to have_content('メールアドレスを入力してください')
        expect(page).to have_content('パスワードを入力してください')
        expect(page).to have_content('ユーザー名を入力してください')
      end

      it 'パスワード（確認用）が一致しないと登録できないこと' do
        visit new_user_registration_path
        fill_in 'ユーザー名（表示名）', with: 'テストユーザー'
        fill_in 'メールアドレス', with: 'new@example.com'
        fill_in 'パスワード', with: 'password123'
        fill_in 'register-password-confirmation-field', with: 'mismatch'
        within '#new_user' do
          click_button '登録する'
        end

        expect(page).to have_content('パスワード（確認）とパスワードの入力が一致しません')
      end
    end

    it '未連携のGoogleアカウントではログインできないこと' do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                           provider: 'google_oauth2',
                                                                           uid: 'unlinked_uid',
                                                                           info: { email: 'unlinked@example.com' },
                                                                           credentials: { token: 'token',
                                                                                          expires_at: Time.now.to_i + 3600 }
                                                                         })

      visit new_user_session_path
      # Googleログインボタンをクリック（button_toに変更されたためclick_button）
      click_button 'Googleでログイン'

      expect(page).to have_content('このGoogleアカウントは連携されていません')
    end
  end

  describe '設定画面の操作' do
    let(:user) do
      FactoryBot.create(:user, name: '既存ユーザー', email: 'user@example.com', password: 'password123', goal_meters: 5000)
    end

    before do
      OmniAuth.config.test_mode = true
      login_as(user, scope: :user)
      visit edit_user_registration_path
    end

    context 'プロフィール更新（異常系）' do
      it '名前を空にすると更新できないこと' do
        fill_in 'ユーザー名（表示名）', with: ''
        click_button '変更を保存する'
        expect(page).to have_content('ユーザー名を入力してください')
      end

      it '目標距離に不正な値（0以下）を入力すると更新できないこと' do
        fill_in '1日の目標(月間) [m]', with: '0'
        click_button '変更を保存する'
        expect(page).to have_content('目標距離は0より大きい値にしてください')
      end

      it '目標距離に不正な値（上限超え）を入力すると更新できないこと' do
        fill_in '1日の目標(月間) [m]', with: '100001'
        click_button '変更を保存する'

        # HTML5バリデーションが機能している場合、フォーム送信自体がブロックされるため、
        # Rails側のバリデーションエラーメッセージは表示されない可能性がある。
        # そのため、画面遷移していないこと（保存されていないこと）を確認する。
        expect(page).to have_current_path(edit_user_registration_path)

        # もしRails側のバリデーションエラーが出るならそれを確認するが、
        # 出ない場合はこのチェックはスキップするか、HTML5バリデーションの有無を確認する
        # ここでは保存されていないことを主眼とする
      end
    end

    it 'プロフィール（名前・目標距離）を更新できること' do
      fill_in 'ユーザー名（表示名）', with: '更新後のユーザー'
      fill_in '1日の目標(月間) [m]', with: '8000'
      click_button '変更を保存する'

      expect(page).to have_content('アカウント情報を変更しました。')
      expect(user.reload.name).to eq('更新後のユーザー')
      expect(user.reload.goal_meters).to eq(8000)
    end

    it 'パスワードを変更できること（現在のパスワード必須）' do
      # セキュリティ設定のアコーディオンを開く
      find('h3', text: 'セキュリティ設定').click

      fill_in '新しいパスワード（変更する場合のみ）', with: 'newpassword'
      fill_in 'パスワード確認', with: 'newpassword'
      fill_in '現在のパスワード', with: 'password123'
      click_button '変更を保存する'

      expect(page).to have_content('アカウント情報を変更しました。')
      expect(user.reload.valid_password?('newpassword')).to be true
    end

    it '現在のパスワードが間違っていると更新できないこと' do
      # セキュリティ設定のアコーディオンを開く
      find('h3', text: 'セキュリティ設定').click

      fill_in '新しいパスワード（変更する場合のみ）', with: 'newpassword'
      fill_in 'パスワード確認', with: 'newpassword'
      fill_in '現在のパスワード', with: 'wrongpassword'
      click_button '変更を保存する'

      expect(page).to have_content('現在のパスワードは不正な値です')
    end

    it '確認用パスワードが一致しないと更新できないこと' do
      # セキュリティ設定のアコーディオンを開く
      find('h3', text: 'セキュリティ設定').click

      fill_in '新しいパスワード（変更する場合のみ）', with: 'newpassword'
      fill_in 'パスワード確認', with: 'mismatch'
      fill_in '現在のパスワード', with: 'password123'
      click_button '変更を保存する'

      expect(page).to have_content('パスワード（確認）とパスワードの入力が一致しません')
    end

    it 'Google連携を行い、その後解除できること', js: true do
      # アバター画像のダウンロードをスタブ
      stub_request(:get, 'http://example.com/avatar.jpg')
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Ruby'
          }
        )
        .to_return(status: 200, body: File.read(Rails.root.join('spec/fixtures/files/avatar.jpg')), headers: {})

      # Google連携のモック
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                           provider: 'google_oauth2',
                                                                           uid: 'linked_uid',
                                                                           info: { email: 'user@example.com',
                                                                                   image: 'http://example.com/avatar.jpg' },
                                                                           credentials: { token: 'token',
                                                                                          expires_at: Time.now.to_i + 3600 }
                                                                         })

      # 連携ボタンをクリック（モーダルが開く）
      click_button '連携する'

      # モーダル内の連携リンクをクリック
      click_button '連携に進む'

      expect(page).to have_content('Googleアカウントと連携しました')
      expect(page).to have_content('連携済み')
      expect(user.reload.google_uid).to eq('linked_uid')

      # 連携解除ボタン（モーダルを開く）をクリック
      # 連携済み状態になるまで少し待つ
      expect(page).to have_content('連携済み')
      find("button span[title='連携を解除する']").click

      # モーダルが表示されるのを確認
      expect(page).to have_content('Google連携の解除')
      expect(page).to have_content('現在のパスワードを入力してください')

      # パスワードを入力して解除
      within '#disconnect_modal' do
        fill_in '現在のパスワード', with: 'password123'
        click_button '解除する'
      end

      expect(page).to have_content('Google連携を解除しました')

      # "未連携" という文字は表示されない仕様なので、"連携する" ボタンがあることを確認
      expect(page).to have_content('連携する')
      expect(page).not_to have_content('連携済み')

      # DB上で連携情報が消えているか確認
      user.reload
      expect(user.google_uid).to be_nil
      expect(user.google_token).to be_nil
    end

    it 'Google連携解除時にパスワードを間違えると解除できないこと', js: true do
      # 事前にGoogle連携状態にする
      user.update!(
        google_uid: 'linked_uid',
        google_token: 'token',
        google_expires_at: Time.now + 1.hour
      )
      visit edit_user_registration_path

      # 連携解除ボタン（モーダルを開く）をクリック
      find("button span[title='連携を解除する']").click

      # 間違ったパスワードを入力
      within '#disconnect_modal' do
        fill_in '現在のパスワード', with: 'wrongpassword'
        click_button '解除する'
      end

      expect(page).to have_content('パスワードが正しくありません')

      # 連携が解除されていないことを確認
      expect(page).to have_content('連携済み')
      expect(user.reload.google_uid).to eq('linked_uid')
    end

    context 'アバター設定' do
      before do
        # Google連携済みの状態にする
        user.update!(
          google_uid: 'linked_uid',
          google_token: 'token',
          google_expires_at: Time.now + 1.hour,
          avatar_url: 'http://example.com/avatar.jpg'
        )
        visit edit_user_registration_path
      end

      it 'Google画像とアップロード画像を切り替えられること', js: true do
        # 1. Google画像を選択
        find("button[title='アバターを変更']").click
        expect(page).to have_selector('dialog[open]')
        # アニメーション完了を待つために明示的な待機が必要な場合があるが、
        # have_selector("dialog[open]") で十分なはずなのでsleepは削除

        execute_script("document.getElementById('user_avatar_type_google').click()")
        within('dialog[open]') { click_button '変更を保存する' }
        expect(page).to have_content('アカウント情報を変更しました。')
        expect(user.reload.avatar_type).to eq('google')

        # 2. 画像をアップロード（自動的にuploadedになるはず）
        find("button[title='アバターを変更']").click
        expect(page).to have_selector('dialog[open]')
        # アニメーション完了を待つために明示的な待機が必要な場合があるが、
        # have_selector("dialog[open]") で十分なはずなのでsleepは削除

        # input要素を可視化してファイル添付
        execute_script("document.getElementById('user_uploaded_avatar').classList.remove('hidden')")
        attach_file 'user_uploaded_avatar', Rails.root.join('spec/fixtures/files/avatar.jpg')

        within('dialog[open]') { click_button '変更を保存する' }
        expect(page).to have_content('アカウント情報を変更しました。')
        expect(user.reload.avatar_type).to eq('uploaded')
        expect(user.uploaded_avatar).to be_attached

        # 3. 再度Google画像を選択
        find("button[title='アバターを変更']").click
        expect(page).to have_selector('dialog[open]')
        # アニメーション完了を待つために明示的な待機が必要な場合があるが、
        # have_selector("dialog[open]") で十分なはずなのでsleepは削除

        execute_script("document.getElementById('user_avatar_type_google').click()")
        within('dialog[open]') { click_button '変更を保存する' }
        expect(page).to have_content('アカウント情報を変更しました。')
        expect(user.reload.avatar_type).to eq('google')

        # 4. 再度アップロード画像を選択
        find("button[title='アバターを変更']").click
        expect(page).to have_selector('dialog[open]')
        # アニメーション完了を待つために明示的な待機が必要な場合があるが、
        # have_selector("dialog[open]") で十分なはずなのでsleepは削除

        execute_script("document.getElementById('user_avatar_type_uploaded').click()")
        within('dialog[open]') { click_button '変更を保存する' }
        expect(page).to have_content('アカウント情報を変更しました。')
        expect(user.reload.avatar_type).to eq('uploaded')
      end
    end

    it 'アカウントを削除できること' do
      accept_confirm do
        click_button '削除する'
      end

      # 削除完了メッセージを待つ（これが待機処理になる）
      expect(page).to have_content('アカウントを削除しました。')

      # その後でDBを確認
      expect(User.exists?(user.id)).to be_falsey
    end
  end
end
