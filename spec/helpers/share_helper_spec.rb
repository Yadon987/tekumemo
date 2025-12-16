require 'rails_helper'

RSpec.describe ShareHelper, type: :helper do
  describe "#twitter_share_url" do
    it "Twitterシェア用のURLを生成すること" do
      url = helper.twitter_share_url(text: "Hello", url: "http://example.com", hashtags: [ "test", "rails" ])
      expect(url).to include("https://twitter.com/intent/tweet")
      expect(url).to include("text=Hello")
      expect(url).to include("url=http%3A%2F%2Fexample.com")
      expect(url).to include("hashtags=test%2Crails")
    end
  end

  describe "#share_post_on_twitter_url" do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user, body: "散歩したよ") }

    before do
      # 今日の散歩データを作成 (5km = 5000m)
      create(:walk, user: user, walked_on: Date.current, distance: 5000)
    end

    it "投稿シェア用のURLを生成すること" do
      url = helper.share_post_on_twitter_url(post)
      expect(url).to include("https://twitter.com/intent/tweet")
      # URLエンコードされているため、デコードしてチェックするか、部分一致で確認
      decoded_url = URI.decode_www_form_component(url)
      expect(decoded_url).to include("5.0km")
      expect(decoded_url).to include("散歩したよ")
    end
  end

  describe "#share_ranking_on_twitter_url" do
    let(:user) { create(:user) }

    it "ランキングシェア用のURLを生成すること" do
      # distanceはメートル単位で渡す
      url = helper.share_ranking_on_twitter_url(user: user, rank: 1, distance: 10000)
      expect(url).to include("https://twitter.com/intent/tweet")

      decoded_url = URI.decode_www_form_component(url)
      expect(decoded_url).to include("1th")
      expect(decoded_url).to include("10.0km")
    end
  end
end
