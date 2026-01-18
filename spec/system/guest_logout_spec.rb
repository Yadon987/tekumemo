require 'rails_helper'

RSpec.describe 'Guest User Logout', type: :system do
  let!(:guest_user) do
    User.create!(email: "guest_#{Time.current.to_i}@example.com", password: 'password', role: :guest,
                 name: 'Guest User')
  end

  before do
    driven_by(:rack_test)
    sign_in guest_user
  end

  it 'allows guest user to logout from settings page' do
    visit edit_user_registration_path

    # ストロングパラメータやViewの変更により、設定画面が正しく表示されていることを確認
    expect(page).to have_content('ゲストモード中です')
    expect(page).to have_content('ログアウトして正式登録する')

    # ログアウトボタンをクリック
    click_button 'ログアウトして正式登録する'

    # ログアウト後の期待される挙動を確認（例: トップページへリダイレクト、フラッシュメッセージなど）
    expect(current_path).to eq(new_user_session_path)
    expect(page).to have_content('ログアウトしました。')
  end
end
