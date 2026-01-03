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

    # === 共通の値オブジェクト ===
    let(:step_val_obj) { double(int_val: 1000) }
    let(:distance_val_obj) { double(fp_val: 1500.0) } # 1500m
    let(:calorie_val_obj) { double(fp_val: 500.0) }

    # === 1. 日次歩数リクエスト用のモック ===
    let(:daily_step_point) { double(value: [ step_val_obj ]) }
    let(:daily_step_dataset) { double(point: [ daily_step_point ]) }
    let(:daily_bucket) { double(
      start_time_millis: start_date.beginning_of_day.to_i * 1000,
      end_time_millis: start_date.end_of_day.to_i * 1000,
      dataset: [ daily_step_dataset ]
    )}
    let(:daily_steps_response) { double(bucket: [ daily_bucket ]) }

    # === 2. アクティビティセグメントリクエスト用のモック ===
    # データセットの順序: Distance, Calories
    let(:act_distance_point) { double(value: [ distance_val_obj ]) }
    let(:act_calorie_point) { double(value: [ calorie_val_obj ]) }
    
    let(:act_distance_dataset) { double(point: [ act_distance_point ]) }
    let(:act_calorie_dataset) { double(point: [ act_calorie_point ]) }

    let(:activity_bucket) { double(
      start_time_millis: start_date.beginning_of_day.to_i * 1000,
      end_time_millis: start_date.beginning_of_day.to_i * 1000 + 3600000, # 1時間
      activity: 7, # Walking
      dataset: [ act_distance_dataset, act_calorie_dataset ]
    )}
    let(:activity_segments_response) { double(bucket: [ activity_bucket ]) }

    before do
      # 1回目は日次歩数、2回目はアクティビティデータを返す
      allow(fitness_service).to receive(:aggregate_dataset).and_return(daily_steps_response, activity_segments_response)
    end

    it "正しくデータを取得して整形すること" do
      result = service.fetch_activities(start_date, end_date)
      data = result[:data][start_date]

      # 歩数: 日次データから (1000)
      # 距離: アクティビティデータから (1500m -> 1.5km)
      # カロリー: アクティビティデータから (500)
      # 時間: 歩数(1000) / 100 = 10分 + アクティビティ時間(サイクリングなら加算だが今回はWalkingなので加算なし)
      
      expect(data[:steps]).to eq 1000
      expect(data[:distance]).to eq 1.5 
      expect(data[:calories]).to eq 500
      expect(data[:duration]).to eq 10 # 1000歩 ÷ 100歩/分
    end

    context "APIエラーが発生した場合" do
      before do
        allow(fitness_service).to receive(:aggregate_dataset).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "エラーハッシュを返すこと" do
        result = service.fetch_activities(start_date, end_date)
        expect(result).to include(error: :api_error)
      end
    end
  end
end
