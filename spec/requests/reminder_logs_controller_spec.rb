require 'rails_helper'

RSpec.describe 'ReminderLogs', type: :request do
  let(:user) { create(:user) }
  let!(:reminder_log) { create(:reminder_log, user: user, read_at: nil, category: :inactive_reminder, message: 'テストメッセージ') }

  before do
    sign_in user
  end

  describe 'GET /notifications' do
    it '通知一覧が表示されること' do
      # リマインダータブを表示
      get reminder_logs_path(tab: 'reminders')
      expect(response).to have_http_status(:success)
      expect(response.body).to include(reminder_log.body)
    end
  end

  describe 'PATCH /notifications/:id/mark_as_read' do
    around do |example|
      # テスト環境でCSRF保護を無効化（明示的に設定）し、テスト後に設定を戻す
      original_value = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = false
      example.run
      ActionController::Base.allow_forgery_protection = original_value
    end

    it '未読通知が既読になること' do
      patch mark_as_read_reminder_log_path(reminder_log)
      expect(reminder_log.reload.read_at).not_to be_nil
      expect(response).to redirect_to(reminder_logs_path)
    end
  end
end
