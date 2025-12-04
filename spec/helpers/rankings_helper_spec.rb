require 'rails_helper'

RSpec.describe RankingsHelper, type: :helper do
  describe "#ordinal_suffix" do
    it "1には'st'を返す" do
      expect(helper.ordinal_suffix(1)).to eq "st"
    end

    it "2には'nd'を返す" do
      expect(helper.ordinal_suffix(2)).to eq "nd"
    end

    it "3には'rd'を返す" do
      expect(helper.ordinal_suffix(3)).to eq "rd"
    end

    it "4には'th'を返す" do
      expect(helper.ordinal_suffix(4)).to eq "th"
    end

    it "11には'th'を返す（例外ケース）" do
      expect(helper.ordinal_suffix(11)).to eq "th"
    end

    it "12には'th'を返す（例外ケース）" do
      expect(helper.ordinal_suffix(12)).to eq "th"
      expect(helper.ordinal_suffix(13)).to eq "th"
      expect(helper.ordinal_suffix(111)).to eq "th"
    end

    it "21には'st'を返す" do
      expect(helper.ordinal_suffix(21)).to eq "st"
    end

    it "22には'nd'を返す" do
      expect(helper.ordinal_suffix(22)).to eq "nd"
    end

    it "23には'rd'を返す" do
      expect(helper.ordinal_suffix(23)).to eq "rd"
    end
  end

  describe "#rank_color_class" do
    it "1位の場合は金色のクラスを返すこと" do
      expect(helper.rank_color_class(1)).to include("from-yellow-300")
    end

    it "2位の場合は銀色のクラスを返すこと" do
      expect(helper.rank_color_class(2)).to include("from-slate-300")
    end

    it "3位の場合は銅色のクラスを返すこと" do
      expect(helper.rank_color_class(3)).to include("from-orange-300")
    end

    it "4位以下の場合はデフォルトのクラスを返すこと" do
      expect(helper.rank_color_class(4)).to include("bg-slate-100")
    end
  end

  describe "#period_label_ja" do
    it "dailyの場合は'今日'を返すこと" do
      expect(helper.period_label_ja("daily")).to eq "今日"
    end

    it "monthlyの場合は'今月'を返すこと" do
      expect(helper.period_label_ja("monthly")).to eq "今月"
    end

    it "yearlyの場合は'今年'を返すこと" do
      expect(helper.period_label_ja("yearly")).to eq "今年"
    end

    it "不正な値の場合はデフォルトで'今日'を返すこと" do
      expect(helper.period_label_ja("invalid")).to eq "今日"
    end
  end
end
