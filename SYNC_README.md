# 同期スクリプトの使い方

## complete_sync.sh

Claude Codeで追加したGemやパッケージをローカル環境（Docker）に同期するためのスクリプトです。

### 使い方

#### 基本的な使い方

```bash
./complete_sync.sh
```

#### Docker環境で実行する場合

```bash
docker-compose exec web ./complete_sync.sh
```

または

```bash
docker exec -it <container_name> ./complete_sync.sh
```

### このスクリプトが実行する処理

1. **Bundlerのバージョン確認**
   - Gemfile.lockに記載されているBundlerのバージョンを確認
   - 必要に応じてBundlerをインストール

2. **bundle install**
   - Gemfile.lockに基づいてGemをインストール

3. **yarn install**
   - package.jsonが存在する場合、Node.jsパッケージをインストール

4. **データベースマイグレーション**
   - 未実行のマイグレーションがあれば実行

5. **アセットのプリコンパイル（本番環境のみ）**
   - RAILS_ENV=production の場合のみ実行

6. **JavaScriptのビルド**
   - yarn build または npm run build を実行

### よくあるケース

#### Claude Codeで新しいGemを追加した後

```bash
# ローカル環境で実行
./complete_sync.sh
```

これにより、Gemfile.lockが更新され、新しいGemがインストールされます。

#### マイグレーションファイルが追加された後

```bash
# ローカル環境で実行
./complete_sync.sh
```

データベースマイグレーションが自動的に実行されます。

#### package.jsonが更新された後

```bash
# ローカル環境で実行
./complete_sync.sh
```

yarn installとJavaScriptのビルドが実行されます。

### トラブルシューティング

#### bundle installが失敗する場合

```bash
# Bundlerのバージョンを確認
bundle -v

# Gemfile.lockに記載されているバージョンと一致しない場合
gem install bundler -v <バージョン>
```

#### データベースエラーが発生する場合

```bash
# データベースをリセット（開発環境のみ）
bin/rails db:reset

# または
bin/rails db:drop db:create db:migrate db:seed
```

#### Railsサーバーが起動しない場合

```bash
# Railsサーバーを再起動
docker-compose restart web

# または
bin/rails restart
```

### 注意事項

- このスクリプトは開発環境での使用を想定しています
- 本番環境で実行する場合は、RAILS_ENV=production を設定してください
- データベースのマイグレーションは慎重に行ってください
