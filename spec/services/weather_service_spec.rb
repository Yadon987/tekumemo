require 'rails_helper'

RSpec.describe WeatherService, type: :service do
  describe '.get_forecast' do
    context 'APIキーが設定されていない場合' do
      before do
        allow(ENV).to receive(:[]).with('OPENWEATHER_API_KEY').and_return(nil)
      end

      it 'ダミーデータを返すこと' do
        # ダミーデータを返すことを検証
        result = described_class.get_forecast

        expect(result).to have_key(:today)
        expect(result).to have_key(:tomorrow)
        expect(result[:today][:temp]).to eq(22)
        expect(result[:today][:description]).to eq('晴れ')
        expect(result[:today][:icon]).to eq('sunny')
      end
    end

    context 'APIキーが設定されている場合' do
      let(:api_key) { 'test_api_key' }
      let(:mock_response_body) do
        {
          list: [
            {
              dt: Time.current.to_i,
              main: { temp: 25.5 },
              weather: [{ main: 'Clear', description: '快晴' }]
            },
            {
              dt: (Time.current + 1.day).to_i,
              main: { temp: 20.3 },
              weather: [{ main: 'Clouds', description: '曇り' }]
            }
          ]
        }.to_json
      end

      before do
        allow(ENV).to receive(:[]).with('OPENWEATHER_API_KEY').and_return(api_key)
      end

      it 'APIから天気情報を取得して整形すること' do
        # Net::HTTPのモックを作成
        stub_request(:get, /api.openweathermap.org/)
          .to_return(status: 200, body: mock_response_body, headers: { 'Content-Type' => 'application/json' })

        result = described_class.get_forecast(lat: 35.6762, lon: 139.6503)

        # 取得した情報が正しく整形されているか検証
        expect(result).to have_key(:today)
        expect(result).to have_key(:tomorrow)
        expect(result[:today][:temp]).to eq(26) # 25.5を四捨五入
        expect(result[:today][:icon]).to eq('sunny')
      end

      it 'API呼び出しに失敗した場合はダミーデータを返すこと' do
        # APIリクエストが失敗した場合をシミュレート
        stub_request(:get, /api.openweathermap.org/)
          .to_return(status: 500, body: '', headers: {})

        result = described_class.get_forecast

        # ダミーデータが返ることを検証
        expect(result[:today][:temp]).to eq(22)
        expect(result[:today][:description]).to eq('晴れ')
      end

      it '例外が発生した場合はダミーデータを返すこと' do
        # Net::HTTPで例外が発生する場合をシミュレート
        allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('Network error'))

        result = described_class.get_forecast

        # ダミーデータが返ることを検証
        expect(result[:today][:temp]).to eq(22)
        expect(result[:today][:description]).to eq('晴れ')
      end
    end
  end

  describe '.weather_icon' do
    it 'Clearの場合はsunnyアイコンを返すこと' do
      expect(described_class.weather_icon('Clear')).to eq('sunny')
    end

    it 'Cloudsの場合はcloudアイコンを返すこと' do
      expect(described_class.weather_icon('Clouds')).to eq('cloud')
    end

    it 'Rainの場合はrainyアイコンを返すこと' do
      expect(described_class.weather_icon('Rain')).to eq('rainy')
    end

    it 'Drizzleの場合はrainyアイコンを返すこと' do
      expect(described_class.weather_icon('Drizzle')).to eq('rainy')
    end

    it 'Thunderstormの場合はthunderstormアイコンを返すこと' do
      expect(described_class.weather_icon('Thunderstorm')).to eq('thunderstorm')
    end

    it 'Snowの場合はac_unitアイコンを返すこと' do
      expect(described_class.weather_icon('Snow')).to eq('ac_unit')
    end

    it 'Mistの場合はmistアイコンを返すこと' do
      expect(described_class.weather_icon('Mist')).to eq('mist')
    end

    it '未知の天気の場合はwb_cloudyアイコンを返すこと' do
      expect(described_class.weather_icon('Unknown')).to eq('wb_cloudy')
    end
  end

  describe '.dummy_data' do
    it '正しい構造のダミーデータを返すこと' do
      # ダミーデータの構造を検証
      data = described_class.dummy_data

      expect(data).to be_a(Hash)
      expect(data).to have_key(:today)
      expect(data).to have_key(:tomorrow)
      expect(data[:today]).to have_key(:temp)
      expect(data[:today]).to have_key(:description)
      expect(data[:today]).to have_key(:icon)
    end
  end
end
