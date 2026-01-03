# Fit一括取込バグ修正完了報告書

**修正日:** 2026年1月3日  
**修正内容:** Google Fit APIデータ取得ロジックの再設計

---

## 修正した問題

### 問題1: 管理ユーザーでもランダム数値に変更される ✅ 修正完了

**原因:**
- `@user.admin?` の判定により、管理者は常にダミーデータを使用していた

**修正内容:**
```ruby
# 修正前
return if user.admin? || user.guest?
return { data: fetch_dummy_activities(...) } if @user.admin? || @user.guest?

# 修正後
return if user.guest?
return { data: fetch_dummy_activities(...) } if @user.guest?
```

---

### 問題2: 連携APIとFitアプリの数値不一致 ✅ 修正完了

**原因:**
- アクティビティセグメントバケット方式で取得すると、短い歩行が検出されない
- 例: 8725歩のうち1377歩（約16%）しか取得できていない

**修正内容:**
ハイブリッド方式を採用：

| データ | 取得方法 | 理由 |
|-------|---------|------|
| **歩数** | 日次バケット (`bucket_by_time`) | 全歩数を漏れなく取得 |
| **距離** | アクティビティセグメント (`bucket_by_activity_segment`) | 電車・車の移動を除外 |
| **カロリー** | アクティビティセグメント | 電車・車の移動を除外 |
| **時間** | 歩数÷100 + サイクリング時間÷2 | 厚労省データに基づく推定 |

---

## 修正後のロジック

### 1. 歩数取得（新規実装）

```ruby
def fetch_daily_steps(start_time_millis, end_time_millis)
  request = Google::Apis::FitnessV1::AggregateRequest.new(
    aggregate_by: [
      Google::Apis::FitnessV1::AggregateBy.new(
        data_type_name: "com.google.step_count.delta"
      )
    ],
    bucket_by_time: Google::Apis::FitnessV1::BucketByTime.new(
      duration_millis: 86400000  # 24時間
    )
  )
  # 日付ごとに全歩数を集計
end
```

### 2. 距離・カロリー取得（既存ロジックを流用）

```ruby
def fetch_activity_segment_data(start_time_millis, end_time_millis)
  # アクティビティセグメントでwalking/running/bikingのみ取得
  # サイクリングは距離1/4、時間1/2に換算
end
```

### 3. データ統合

```ruby
all_dates = (steps_by_date.keys + activity_data_by_date.keys).uniq

all_dates.each do |date|
  steps = steps_by_date[date] || 0
  activity = activity_data_by_date[date] || { distance_m: 0.0, calories: 0, ... }
  
  # 時間計算
  walk_duration = (steps / 100.0).round           # 歩行時間
  total_duration = walk_duration + cycling_time   # サイクリング時間を加算
end
```

---

## 科学的根拠

### 歩行時間の推定

| ソース | データ |
|-------|--------|
| 厚生労働省 | 1,000歩 ≒ 10分 → **100歩/分** |
| 成人男性歩幅 | 63〜78cm (平均70cm) |
| 歩行速度 | 4.0〜5.0 km/h |

**計算:** 70cm × 100歩/分 = 70m/分 = 4.2km/h ✅

### サイクリング換算

| 活動 | METs | 速度 |
|-----|------|------|
| 普通歩行 | 3.0 | 4.0 km/h |
| 通勤自転車 | 5.8 | 15.0 km/h |

**速度比:** 15km/h ÷ 4km/h ≈ 3.75倍 → **距離1/4換算** ✅  
**METs比:** 5.8 ÷ 3.0 ≈ 1.9倍 → **時間1/2換算（控えめ）** ✅

---

## 期待される効果

### Before（修正前）
```
Google Fit: 8725歩
てくメモ:   1377歩  ← 84%のデータ損失！
```

### After（修正後）
```
Google Fit: 8725歩
てくメモ:   8725歩  ← 100%取得！
```

---

## テスト対象

修正が正しく動作するか確認が必要：

```bash
# サービスのテスト
bundle exec rspec spec/services/google_fit_service_spec.rb

# システムテスト
bundle exec rspec spec/system/guest_google_fit_spec.rb

# リクエストテスト
bundle exec rspec spec/requests/google_fit_spec.rb
```

---

## 影響範囲

| ユーザータイプ | 影響 |
|--------------|------|
| 管理者 | ✅ 実データが正しく取得されるようになる |
| ゲスト | 変更なし（引き続きダミーデータ） |
| 一般ユーザー | ✅ 歩数が大幅に増加（正確な値になる） |

---

## 注意事項

1. **歩数と距離の不整合**
   - 歩数は全活動、距離はアクティビティセグメントのみ
   - 「家の中の歩行は歩数のみカウントされる」という正しい状態

2. **既存データへの影響**
   - 過去データは変更されない
   - 次回「Fit一括取込」実行時から新ロジックが適用される

3. **API呼び出し回数**
   - 2回のリクエストが必要（歩数+アクティビティセグメント）
   - Google Fit APIの制限内で問題なし
