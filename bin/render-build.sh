#!/usr/bin/env bash
# bin/render-build.sh

set -o errexit

echo "🚀 アプリのビルド開始！"

# Bundlerのインストール
echo "📦 Ruby Gemsをインストール中..."
bundle install

# Node.jsの依存関係（package.jsonがある場合のみ）
if [ -f "package.json" ]; then
  echo "📦 Node.jsの依存関係をインストール中..."
  npm install
fi

# アセットのプリコンパイル
echo "🎨 アセットをコンパイル中..."
bundle exec rails assets:precompile

# データベースマイグレーション
echo "🗄️ データベースを更新中..."
bundle exec rails db:migrate

echo "✅ ビルド完了！アプリの準備ができました！"
