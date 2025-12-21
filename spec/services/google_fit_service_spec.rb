require 'rails_helper'
require 'google/apis/fitness_v1'

RSpec.describe GoogleFitService, type: :service do
  let(:user) { create(:user, google_token: "token", google_refresh_token: "refresh_token", google_expires_at: 1.hour.from_now) }
  let(:service) { described_class.new(user) }
  let(:fitness_service) { instance_double(Google::Apis::FitnessV1::FitnessService) }
  let(:auth_client) { instance_double(Signet::OAuth2::Client) }

  before do
    allow(Google::Apis::FitnessV1::FitnessService).to receive(:new).and_return(fitness_service)
    allow(fitness_service).to receive(:authorization=)
    allow(user).to receive(:google_token_valid?).and_return(true)

    # Signet::OAuth2::Client のモック
    allow(Signet::OAuth2::Client).to receive(:new).and_return(auth_client)
    allow(auth_client).to receive(:refresh!)
    allow(auth_client).to receive(:access_token).and_return("new_token")
    allow(auth_client).to receive(:expires_at).and_return(Time.now + 3600)
  end

  describe "#fetch_activities" do
    let(:start_date) { Date.current }
    let(:end_date) { Date.current }

    # モックの作成
    let(:step_value) { double(int_val: 1000) }
    let(:distance_value) { double(fp_val: 1500.0) } # 1500m
    let(:calorie_value) { double(fp_val: 500.0) }

    let(:step_point) { double(value: [ step_value ]) }
    let(:distance_point) { double(value: [ distance_value ]) }
    let(:calorie_point) { double(value: [ calorie_value ]) }

    let(:step_dataset) { double(point: [ step_point ]) }
    let(:distance_dataset) { double(point: [ distance_point ]) }
    let(:calorie_dataset) { double(point: [ calorie_point ]) }

    let(:bucket) { double(
      start_time_millis: start_date.beginning_of_day.to_i * 1000,
      dataset: [ step_dataset, distance_dataset, calorie_dataset ]
    )}
    let(:response) { double(bucket: [ bucket ]) }

    before do
      allow(fitness_service).to receive(:aggregate_dataset).and_return(response)
    end

    it "正しくデータを取得して整形すること" do
      result = service.fetch_activities(start_date, end_date)
      data = result[start_date]

      expect(data[:steps]).to eq 1000
      expect(data[:distance]).to eq 1.5 # 1500m -> 1.5km
      expect(data[:calories]).to eq 500
    end

    context "APIエラーが発生した場合" do
      before do
        allow(fitness_service).to receive(:aggregate_dataset).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "空のハッシュを返すこと" do
        result = service.fetch_activities(start_date, end_date)
        expect(result).to eq({})
      end
    end
  end
end
