require 'rails_helper'

RSpec.describe InactiveReminderService, type: :service do
  describe '.send_reminders' do
    let(:threshold) { 3 }
    let(:user) { create(:user, is_inactive_reminder: true, inactive_days: threshold) }

    before do
      allow(WebPushService).to receive(:send_notification)
      travel_to Time.zone.parse('2025-01-10 10:00:00')
    end

    context '最終散歩日から指定日数が経過した場合' do
      let!(:user) { create(:user, is_inactive_reminder: true, inactive_days: threshold) }

      before do
        create(:walk, user: user, walked_on: threshold.days.ago.to_date)
      end

      it 'リマインダーを送信すること' do
        described_class.send_reminders

        expect(WebPushService).to have_received(:send_notification).with(
          user,
          title: 'お久しぶりです！',
          body: include("#{threshold}日間、散歩の記録がありません"),
          url: '/walks/new'
        )
      end

      it '通知ボックスに通知を作成すること' do
        expect do
          described_class.send_reminders
        end.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.user).to eq(user)
        expect(notification.category).to eq('inactive_reminder')
      end
    end

    context '散歩記録がなく、登録日から指定日数が経過した場合' do
      # created_atを指定して作成（travel_toの影響を受けるため、days.agoで計算）
      let!(:user) do
        create(:user, is_inactive_reminder: true, inactive_days: threshold, created_at: threshold.days.ago)
      end

      it 'リマインダーを送信すること' do
        described_class.send_reminders

        expect(WebPushService).to have_received(:send_notification).with(
          user,
          title: 'お久しぶりです！',
          body: include("#{threshold}日間、散歩の記録がありません"),
          url: '/walks/new'
        )
      end
    end

    context '指定日数が経過していない場合' do
      before do
        create(:walk, user: user, walked_on: (threshold - 1).days.ago.to_date)
      end

      it 'リマインダーを送信しないこと' do
        described_class.send_reminders
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end

    context '指定日数を過ぎている場合（当日に送った後は送らない）' do
      before do
        create(:walk, user: user, walked_on: (threshold + 1).days.ago.to_date)
      end

      it 'リマインダーを送信しないこと' do
        described_class.send_reminders
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end

    context 'リマインダー設定が無効な場合' do
      before do
        user.update!(is_inactive_reminder: false)
        create(:walk, user: user, walked_on: threshold.days.ago.to_date)
      end

      it 'リマインダーを送信しないこと' do
        described_class.send_reminders
        expect(WebPushService).not_to have_received(:send_notification)
      end
    end
  end
end
