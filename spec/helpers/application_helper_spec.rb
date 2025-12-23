require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#user_avatar" do
    let(:user) { create(:user, name: "TestUser") }

    context "Google連携アバターを使用する場合" do
      before do
        user.update(avatar_type: :google, avatar_url: "http://example.com/avatar.jpg")
      end

      it "画像タグが返されること" do
        expect(helper.user_avatar(user)).to match(/<img.*src="http:\/\/example.com\/avatar.jpg".*>/)
      end
    end

    context "Google連携アバターを使用しない場合" do
      before do
        user.update(avatar_type: :default)
      end

      it "イニシャルが表示されること" do
        expect(helper.user_avatar(user)).to include("T")
      end

      it "名前がない場合はゲストが表示されること" do
        user.name = nil
        expect(helper.user_avatar(user)).to include("ゲスト")
      end
    end
  end

  describe "#time_ago_in_words_game_style" do
    it "nilの場合は'未ログイン'を返すこと" do
      expect(helper.time_ago_in_words_game_style(nil)).to eq "未ログイン"
    end

    it "1分未満の場合は'1分未満'を返すこと" do
      expect(helper.time_ago_in_words_game_style(Time.current - 30.seconds)).to eq "1分未満"
    end

    it "1時間未満の場合は'x分前'を返すこと" do
      expect(helper.time_ago_in_words_game_style(Time.current - 30.minutes)).to eq "30分前"
    end

    it "24時間未満の場合は'x時間前'を返すこと" do
      expect(helper.time_ago_in_words_game_style(Time.current - 5.hours)).to eq "5時間前"
    end

    it "30日未満の場合は'x日前'を返すこと" do
      expect(helper.time_ago_in_words_game_style(Time.current - 5.days)).to eq "5日前"
    end

    it "1年未満の場合は'xヶ月前'を返すこと" do
      expect(helper.time_ago_in_words_game_style(Time.current - 3.months)).to eq "3ヶ月前"
    end

    it "1年以上の場合は'x年前'を返すこと" do
      expect(helper.time_ago_in_words_game_style(Time.current - 2.years)).to eq "2年前"
    end
  end
end
