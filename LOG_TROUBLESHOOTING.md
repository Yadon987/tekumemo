# 位置情報ログのトラブルシューティングガイド

## ログ確認コマンド

### 開発環境
```bash
tail -f log/development.log | grep -A 10 "リクエストIP\|Geocoder"
```

### 本番環境（Heroku）
```bash
heroku logs --tail --app your-app-name | grep -A 10 "リクエストIP\|Geocoder"
```

### 本番環境（Render）
```bash
render logs --tail --service your-service-name
```

### Docker環境
```bash
docker-compose logs -f web | grep -A 10 "リクエストIP\|Geocoder"
```

## 期待されるログ出力（正常時）

```
========================================
リクエストIP情報:
  remote_ip: 14.13.18.163
  ip: 14.13.18.163
  X-Forwarded-For: 14.13.18.163
  X-Real-IP: 14.13.18.163
========================================
========================================
Geocoder で位置情報を取得:
  IP: 14.13.18.163
  City: 福山市
  Region: 広島県
  Country: Japan
  Latitude: 34.4859
  Longitude: 133.3623
========================================
```

## 問題パターンと解決策

### パターン1: ローカルIPが取得される

**ログの例:**
```
remote_ip: 172.18.0.1
X-Forwarded-For: 14.13.18.163
```

**原因:** プロキシ/ロードバランサー経由でアクセスしている

**解決策:** `app/controllers/home_controller.rb` を修正

```ruby
# X-Forwarded-For ヘッダーを優先的に使用
user_ip = request.headers['X-Forwarded-For']&.split(',')&.first&.strip || request.remote_ip
```

または `config/application.rb` に追加:
```ruby
config.action_dispatch.trusted_proxies = [
  '127.0.0.1',
  '::1',
  /^172\.(1[6-9]|2[0-9]|3[0-1])\./
]
```

### パターン2: 誤った位置情報が返される

**ログの例:**
```
City: Portland
Region: Oregon
Country: United States
```

**原因:** ip-api.com のデータベースが不正確

**解決策1:** ipinfo.io に切り替え

1. https://ipinfo.io/ でアカウント作成（無料プランあり）
2. APIキーを取得
3. `.env` に追加:
   ```
   IPINFO_IO_API_KEY=your_api_key_here
   ```
4. `config/initializers/geocoder.rb` を修正:
   ```ruby
   Geocoder.configure(
     ip_lookup: :ipinfo_io,
     ipinfo_io: {
       api_key: ENV["IPINFO_IO_API_KEY"]
     }
   )
   ```

**解決策2:** 複数のプロバイダーを試す

```ruby
# config/initializers/geocoder.rb
Geocoder.configure(
  ip_lookup: :freegeoip,  # または :ipstack, :maxmind
  # ...
)
```

### パターン3: タイムアウトエラー

**ログの例:**
```
位置情報の取得に失敗: execution expired (IP: 14.13.18.163)
```

**解決策:** タイムアウト時間を延長

```ruby
# config/initializers/geocoder.rb
Geocoder.configure(
  timeout: 10,  # 5秒 → 10秒に延長
  # ...
)
```

## 各プロバイダーの特徴

| プロバイダー | 精度 | レート制限 | 料金 | APIキー |
|------------|------|-----------|------|---------|
| ipapi.com | 中 | 45/分 | 無料 | 不要 |
| ipinfo.io | 高 | 50,000/月 | 無料プランあり | 必要 |
| ipstack | 高 | 10,000/月 | 無料プランあり | 必要 |
| maxmind | 最高 | 無制限 | 有料 | 必要 |

## デバッグ用コマンド

### 特定IPの位置情報を直接確認

```bash
# ip-api.com
curl "http://ip-api.com/json/14.13.18.163?lang=ja"

# ipinfo.io
curl "https://ipinfo.io/14.13.18.163?token=YOUR_TOKEN"
```

### Railsコンソールで確認

```bash
bin/rails console

# 位置情報を取得
> Geocoder.search("14.13.18.163")

# 詳細情報を確認
> result = Geocoder.search("14.13.18.163").first
> result.city
> result.state
> result.country
> result.latitude
> result.longitude
```

## キャッシュのクリア

位置情報がキャッシュされている場合、古いデータが返される可能性があります。

```bash
# Railsコンソールでキャッシュをクリア
bin/rails console
> Rails.cache.clear

# または特定のキーだけクリア
> Rails.cache.delete("geocoder:14.13.18.163")
```
