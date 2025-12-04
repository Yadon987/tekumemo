---
description: テストの実行方法
---

# テスト実行ガイド

## 全テスト（システムテスト除外）

メモリ不足を避けるため、通常はシステムテストを除外して実行します。

```bash
docker compose exec web bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"
```

## モデル・コントローラーテストのみ

```bash
docker compose exec web bundle exec rspec spec/models spec/requests
```

## システムテストを個別に実行

メモリ不足を避けるため、システムテストは 1 ファイルずつ実行します。

### ホーム画面

```bash
docker compose exec web bundle exec rspec spec/system/home_spec.rb
```

### 投稿機能

```bash
docker compose exec web bundle exec rspec spec/system/posts_spec.rb
```

### ランキング

```bash
docker compose exec web bundle exec rspec spec/system/rankings_spec.rb
```

### 散歩記録

```bash
docker compose exec web bundle exec rspec spec/system/walks_spec.rb
```

### ユーザー認証

```bash
docker compose exec web bundle exec rspec spec/system/user_auth_spec.rb
```

### ユーザー設定

```bash
docker compose exec web bundle exec rspec spec/system/user_settings_spec.rb
```

### カルーセル

```bash
docker compose exec web bundle exec rspec spec/system/carousel_spec.rb
```

### ログインスタンプ

```bash
docker compose exec web bundle exec rspec spec/system/login_stamps_spec.rb
```

### SNS 機能

```bash
docker compose exec web bundle exec rspec spec/system/sns_spec.rb
```

## CI/CD での実行

GitHub Actions などでは、システムテストを並列実行するか、メモリを増やして実行してください。
