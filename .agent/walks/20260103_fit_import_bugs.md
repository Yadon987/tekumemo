# Fit一括取込機能のバグ調査報告書

**調査日:** 2026年1月3日  
**調査者:** Antigravity  

---

## 概要

2つの問題が報告されています：

1. **問題1**: ゲストログイン以外の管理ユーザーでも「Fit一括取込」を押すとランダムなデたらめ数値に変更される
2. **問題2**: 連携APIで自動入力された数値とFitアプリの実際の数値が全然違う

---

## 問題1: 管理ユーザーでもランダム数値になるバグ

### 原因分析

**ファイル:** `app/services/google_fit_service.rb` (L26)

```ruby
def fetch_activities(start_date, end_date)
  return { data: fetch_dummy_activities(start_date, end_date) } if @user.admin? || @user.guest?
  # ...
end
```

**問題点:**
- `admin?` または `guest?` のユーザーは、**常にダミーデータ（ランダム生成）** が返される設計になっている
- これはデモ用途として意図されたものだが、実際の管理者がGoogle Fitと連携している場合でも、実データではなくダミーデータが使用されてしまう

**ダミーデータ生成ロジック (L136-163):**
```ruby
def fetch_dummy_activities(start_date, end_date)
  result = {}
  (start_date..end_date).each do |date|
    base_steps = date.saturday? || date.sunday? ? 8000 : 5000
    steps = base_steps + rand(-1000..3000)  # ← ランダム！
    # ...
  end
  result
end
```

### 影響範囲

| ユーザータイプ | 影響 |
|--------------|------|
| 管理者 (admin) | ❌ **実データが取得されない** - 常にダミーデータで上書きされる |
| ゲスト (guest) | ⚠️ 意図通り（デモ用ダミーデータ） |
| 一般ユーザー (general) | ✅ 問題なし - 実APIから取得 |

### これが起こる理由

1. 管理者がGoogle Fitと連携済み (`google_token_valid? = true`)
2. 「Fit一括取込」ボタンを押す
3. `WalksController#import_google_fit` が呼ばれる
4. `GoogleFitService#fetch_activities` が実行
5. **`@user.admin?` が `true` なので、L26でダミーデータが返される**
6. `Walk#merge_google_fit_data` でダミーデータがマージ
7. 既存データよりダミー値が大きい場合、**誤ったランダム値で上書きされる**

---

## 問題2: 連携APIとFitアプリの数値不一致

### 原因分析

**考えられる原因は複数あります：**

#### 原因A: アクティビティタイプのフィルタリング

**ファイル:** `app/services/google_fit_service.rb` (L5-9, L68)

```ruby
ACTIVITY_TYPE_BIKING = 1
ACTIVITY_TYPE_WALKING = 7
ACTIVITY_TYPE_RUNNING = 8
TARGET_ACTIVITY_TYPES = [ACTIVITY_TYPE_BIKING, ACTIVITY_TYPE_WALKING, ACTIVITY_TYPE_RUNNING].freeze

# L68
next unless TARGET_ACTIVITY_TYPES.include?(activity_type)
```

**問題点:**
- Google Fitアプリは**全てのアクティビティ**（階段昇降、エリプティカル、水泳等）を合算して表示
- このサービスは**徒歩(7)、ランニング(8)、サイクリング(1)のみ**を集計
- → Fitアプリより少ない数値になる可能性大

#### 原因B: サイクリングの換算処理

**ファイル:** `app/services/google_fit_service.rb` (L189-206)

```ruby
def apply_activity_conversion(activity_type, steps, distance, duration_min)
  if activity_type == ACTIVITY_TYPE_BIKING
    distance = distance / 4.0  # 距離は1/4に換算
    duration_min = (duration_min / 2.0).round  # 時間は1/2に換算
    steps = ((distance / 1000.0) * 1300).round  # 歩数を距離から逆算
  end
  [steps, distance, duration_min]
end
```

**問題点:**
- サイクリングデータを「早歩き相当」に換算している
- 距離が1/4、時間が1/2になる
- → サイクリングが多いユーザーは大幅に数値が減る

#### 原因C: バケット処理の問題

**ファイル:** `app/services/google_fit_service.rb` (L49-51)

```ruby
bucket_by_activity_segment: Google::Apis::FitnessV1::BucketByActivity.new(
  min_duration_millis: 0
)
```

**問題点:**
- アクティビティセグメントごとにバケット化している
- Google Fitアプリの「1日合計」とは集計方法が異なる可能性
- 特に複数のアクティビティが混在する日は差が大きくなりやすい

#### 原因D: データセットインデックスの固定

**ファイル:** `app/services/google_fit_service.rb` (L171-184)

```ruby
bucket.dataset.each_with_index do |dataset, index|
  dataset.point.each do |point|
    point.value.each do |value|
      case index
      when 0 # 歩数
        steps += value.int_val if value.int_val
      when 1 # 距離
        distance += value.fp_val if value.fp_val
      when 2 # カロリー
        calories += value.fp_val.to_i if value.fp_val
      end
    end
  end
end
```

**問題点:**
- データセットの順序が `aggregate_by` の順序と一致する前提
- Google Fit APIのレスポンス順序が保証されていない可能性
- データ型の不一致（intとfloatの判定）で取りこぼしの可能性

---

## 修正案

### 問題1の修正案（優先度: 高 🔴）

**方針:** 管理者が実際にGoogle連携している場合は実データを使用

#### 修正案A: フラグによる切り替え（推奨）

```ruby
# app/services/google_fit_service.rb

def initialize(user)
  @user = user
  @use_dummy_data = user.guest? || (user.admin? && !user.has_real_google_connection?)
  
  return if @use_dummy_data

  @client = Google::Apis::FitnessV1::FitnessService.new
  auth = Signet::OAuth2::Client.new(access_token: user.google_token)
  @client.authorization = auth
end

def fetch_activities(start_date, end_date)
  return { data: fetch_dummy_activities(start_date, end_date) } if @use_dummy_data
  # 以下、実API呼び出し...
end
```

**Userモデルに追加:**
```ruby
# app/models/user.rb

def has_real_google_connection?
  google_token.present? && google_refresh_token.present? && google_expires_at.present?
end
```

#### 修正案B: ゲストのみダミーデータ（シンプル）

```ruby
# app/services/google_fit_service.rb L26

# 変更前
return { data: fetch_dummy_activities(start_date, end_date) } if @user.admin? || @user.guest?

# 変更後
return { data: fetch_dummy_activities(start_date, end_date) } if @user.guest?
```

⚠️ **注意:** この場合、管理者もGoogle連携が必須になる

#### 修正案C: 環境変数による制御

```ruby
# app/services/google_fit_service.rb L26

return { data: fetch_dummy_activities(start_date, end_date) } if @user.guest?
return { data: fetch_dummy_activities(start_date, end_date) } if @user.admin? && ENV['ADMIN_USE_DUMMY_FIT_DATA'] == 'true'
```

### 問題2の修正案（優先度: 中 🟡）

#### 修正案A: アクティビティタイプの拡張

```ruby
# app/services/google_fit_service.rb

# 追加のアクティビティタイプ
ACTIVITY_TYPE_STILL = 3
ACTIVITY_TYPE_TILTING = 5
ACTIVITY_TYPE_IN_VEHICLE = 0
ACTIVITY_TYPE_UNKNOWN = 4

# より広範囲を対象に（ただし計算方法の調整が必要）
EXTENDED_ACTIVITY_TYPES = [
  ACTIVITY_TYPE_BIKING,
  ACTIVITY_TYPE_WALKING,
  ACTIVITY_TYPE_RUNNING,
  # 必要に応じて追加
].freeze
```

#### 修正案B: バケット戦略の変更（日次集計）

```ruby
# アクティビティセグメントではなく、日ごとにバケット化
bucket_by_time: Google::Apis::FitnessV1::BucketByTime.new(
  duration_millis: 86400000  # 24時間
)
```

これによりGoogle Fitアプリと同じ「1日合計」に近づく可能性

#### 修正案C: データ型名での判定（堅牢性向上）

```ruby
def extract_data_from_bucket(bucket)
  steps = 0
  distance = 0.0
  calories = 0

  bucket.dataset.each do |dataset|
    # インデックスではなく、データタイプ名で判定
    data_type_name = dataset.data_source_id&.split(':')&.last
    
    dataset.point.each do |point|
      point.value.each do |value|
        case data_type_name
        when /step_count/
          steps += value.int_val.to_i
        when /distance/
          distance += value.fp_val.to_f
        when /calories/
          calories += value.fp_val.to_i
        end
      end
    end
  end

  [steps, distance, calories]
end
```

#### 修正案D: ログ強化とデバッグ情報

```ruby
# app/services/google_fit_service.rb

def fetch_activities(start_date, end_date)
  # ...
  
  Rails.logger.info "GoogleFit API Request: #{start_date} to #{end_date}"
  
  response.bucket.each do |bucket|
    activity_type = bucket.activity
    Rails.logger.debug "Bucket: activity=#{activity_type}, start=#{bucket.start_time_millis}"
    
    # スキップするアクティビティもログ
    unless TARGET_ACTIVITY_TYPES.include?(activity_type)
      Rails.logger.debug "Skipping activity type: #{activity_type}"
      next
    end
    # ...
  end
  
  Rails.logger.info "GoogleFit Result: #{result.transform_values { |v| v.except(:start_time) }}"
  # ...
end
```

---

## 一般ユーザーへの影響評価

### 問題1について

| 観点 | 影響 |
|-----|------|
| 一般ユーザーのデータ | ✅ **影響なし** - `admin?` も `guest?` も `false` なのでダミーデータは使われない |
| データ整合性 | ✅ 問題なし |

### 問題2について

| 観点 | 影響 |
|-----|------|
| 一般ユーザーのデータ | ⚠️ **影響あり** - 全ユーザーに同じ集計ロジックが適用される |
| 数値の乖離 | ⚠️ サイクリング利用者、複数アクティビティ利用者で乖離が大きい |
| ユーザー体験 | ⚠️ 「Fitアプリと違う」という混乱を招く可能性 |

---

## 推奨対応順序

1. **即座に対応（問題1）**: 修正案Bまたは修正案Aを適用
   - 管理者のデータが破損するリスクを排除
   
2. **調査継続（問題2）**: ログ強化を実装し、実際のズレのパターンを確認
   - まずは修正案Dでデータ収集
   
3. **改善（問題2）**: データ分析後に適切な対策を選定
   - ユーザーへの説明文言の追加も検討

---

## テスト対象

修正後に以下のテストを実行すべき：

```bash
bin/rails test test/services/google_fit_service_test.rb
bundle exec rspec spec/services/google_fit_service_spec.rb
bundle exec rspec spec/system/guest_google_fit_spec.rb
bundle exec rspec spec/requests/google_fit_spec.rb
```
