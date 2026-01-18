module LoginSupport
  def sign_in_as(user)
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'login-password-field', with: 'password123'
    within '#new_user' do
      click_button 'ログインする'
    end
    expect(page).to have_content 'ログインしました'
  end
end

RSpec.configure do |config|
  config.include LoginSupport
end
