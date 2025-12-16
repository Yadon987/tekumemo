require "rails_helper"

RSpec.describe GeolocationService, type: :service do
  describe ".extract_ip" do
    let(:request) { instance_double(ActionDispatch::Request) }

    it "X-Forwarded-Forヘッダーがある場合はその最初のIPを返すこと" do
      allow(request).to receive(:headers).and_return({ "X-Forwarded-For" => "203.0.113.1, 198.51.100.1" })
      expect(described_class.extract_ip(request)).to eq("203.0.113.1")
    end

    it "X-Forwarded-Forヘッダーがない場合はremote_ipを返すこと" do
      allow(request).to receive(:headers).and_return({})
      allow(request).to receive(:remote_ip).and_return("192.0.2.1")
      expect(described_class.extract_ip(request)).to eq("192.0.2.1")
    end
  end

  describe ".get_location" do
    let(:default_location) do
      {
        latitude: 35.6762,
        longitude: 139.6503,
        city: "東京",
        region: "東京都",
        country: "日本"
      }
    end

    context "ローカルIPまたはプライベートIPの場合" do
      it "localhostの場合はデフォルト位置情報を返すこと" do
        expect(described_class.get_location("127.0.0.1")).to eq(default_location)
      end

      it "プライベートIPの場合はデフォルト位置情報を返すこと" do
        expect(described_class.get_location("192.168.1.1")).to eq(default_location)
      end

      it "nilの場合はデフォルト位置情報を返すこと" do
        expect(described_class.get_location(nil)).to eq(default_location)
      end
    end

    context "パブリックIPの場合" do
      let(:ip_address) { "203.0.113.1" }
      let(:geocoder_result) do
        double("GeocoderResult",
          latitude: 34.6937,
          longitude: 135.5023,
          city: "大阪市",
          state: "大阪府",
          country: "日本"
        )
      end

      it "Geocoderで取得できた場合はその位置情報を返すこと" do
        allow(Geocoder).to receive(:search).with(ip_address).and_return([ geocoder_result ])

        result = described_class.get_location(ip_address)

        expect(result[:latitude]).to eq(34.6937)
        expect(result[:longitude]).to eq(135.5023)
        expect(result[:city]).to eq("大阪市")
        expect(result[:region]).to eq("大阪府")
        expect(result[:country]).to eq("日本")
      end

      it "Geocoderで取得できなかった場合はデフォルト位置情報を返すこと" do
        allow(Geocoder).to receive(:search).with(ip_address).and_return([])

        expect(described_class.get_location(ip_address)).to eq(default_location)
      end

      it "例外が発生した場合はデフォルト位置情報を返すこと" do
        allow(Geocoder).to receive(:search).and_raise(StandardError.new("Geocoder error"))

        expect(described_class.get_location(ip_address)).to eq(default_location)
      end
    end
  end
end
