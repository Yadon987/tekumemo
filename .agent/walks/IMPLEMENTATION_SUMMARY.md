# Google Fit一括取込バグ修正 - 実装完了

## 修正ファイル

- `app/services/google_fit_service.rb`

## 主要な変更点

### 1. 問題1の修正: 管理者のダミーデータ使用を廃止

**変更箇所:**
- L13: `return if user.guest?` （`admin?` 判定を削除）
- L26: `if @user.guest?` （`admin?` 判定を削除）

### 2. 問題2の修正: ハイブリッドデータ取得方式の導入

**新規メソッド:**
- `fetch_daily_steps()` - 日次バケットで全歩数を取得
- `fetch_activity_segment_data()` - アクティビティセグメントで距離・カロリー取得
- `extract_distance_and_calories_from_bucket()` - 距離とカロリーのみを抽出

**削除メソッド:**
- `extract_data_from_bucket()` - 歩数・距離・カロリーを一度に取得（不要）
- `apply_activity_conversion()` - 換算処理は新メソッド内に統合

### 3. 時間計算ロジックの変更

```ruby
# 歩行時間（歩数÷100歩/分）
walk_duration = (steps / 100.0).round

# サイクリング時間（1/2換算後）を加算
total_duration = walk_duration + activity[:cycling_duration_min]
```

## テスト実行

Dockerコンテナが起動していないため、手動で以下を実行してください：

```bash
# Dockerコンテナを起動
docker compose up -d

# テスト実行
docker compose exec app bundle exec rspec spec/services/google_fit_service_spec.rb
docker compose exec app bundle exec rspec spec/system/guest_google_fit_spec.rb
docker compose exec app bundle exec rspec spec/requests/google_fit_spec.rb

# または全テスト
bin/test_all.sh
```

## 期待される動作

1. **管理ユーザー**: 実際のGoogle Fitデータが取得される
2. **一般ユーザー**: 歩数が正確に（8725歩など）取得される
3. **ゲストユーザー**: 引き続きダミーデータを使用

## 次のステップ

- [ ] Dockerコンテナを起動
- [ ] テストを実行して動作確認
- [ ] 実際のGoogle Fitデータで検証
- [ ] コミット & プッシュ
