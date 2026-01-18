require 'rails_helper'

RSpec.describe 'Home Carousel', type: :system, js: true do
  let(:user) { User.create(email: 'test@example.com', password: 'password', name: 'Test User', goal_meters: 1000) }

  context 'on desktop view' do
    before do
      login_as(user, scope: :user)
      visit root_path
      # PCサイズにリサイズ
      page.current_window.resize_to(1280, 800)
    end

    it 'hides carousel indicators' do
      visit root_path
      expect(page).to have_no_selector('.carousel-indicators')
    end
  end
end
