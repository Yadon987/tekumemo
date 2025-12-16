require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let!(:notification) { create(:notification, user: user, read_at: nil, notification_type: :inactive_reminder, message: "テストメッセージ") }

  before do
    sign_in user
  end

  describe "GET /notifications" do
    it "通知一覧が表示されること" do
      # リマインダータブを表示
      get notifications_path(tab: "reminders")
      expect(response).to have_http_status(:success)
      expect(response.body).to include(notification.body)
    end
  end

  describe "PATCH /notifications/:id/mark_as_read" do
    it "未読通知が既読になること" do
      expect {
        patch mark_as_read_notification_path(notification)
      }.to change { notification.reload.read_at }.from(nil)
      expect(response).to redirect_to(notifications_path)
    end
  end
end
