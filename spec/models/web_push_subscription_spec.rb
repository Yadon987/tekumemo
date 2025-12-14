require 'rails_helper'

RSpec.describe WebPushSubscription, type: :model do
  describe "バリデーション" do
    let(:subscription) { build(:web_push_subscription) }

    it "有効なファクトリを持つこと" do
      expect(subscription).to be_valid
    end

    it "endpointが必須であること" do
      subscription.endpoint = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:endpoint]).to include("を入力してください")
    end

    it "p256dhが必須であること" do
      subscription.p256dh = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:p256dh]).to include("を入力してください")
    end

    it "auth_keyが必須であること" do
      subscription.auth_key = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:auth_key]).to include("を入力してください")
    end

    it "endpointが一意であること" do
      create(:web_push_subscription, endpoint: "https://example.com/duplicate")
      duplicate_subscription = build(:web_push_subscription, endpoint: "https://example.com/duplicate")
      expect(duplicate_subscription).not_to be_valid
      expect(duplicate_subscription.errors[:endpoint]).to include("はすでに存在します")
    end
  end
end
