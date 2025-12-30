#!/bin/bash

# complete_sync.sh
# Claude Codeで追加したGemやパッケージをローカル環境（Docker）に同期するスクリプト

set -e  # エラーが発生したら終了

echo "========================================="
echo "🔄 Gemとパッケージの同期を開始します"
echo "========================================="

# プロジェクトルートに移動
cd "$(dirname "$0")"

# 色付き出力用の関数
success() {
    echo "✅ $1"
}

info() {
    echo "ℹ️  $1"
}

error() {
    echo "❌ $1"
}

# Rubyのバージョンを確認
info "Rubyバージョン: $(ruby -v)"

# 1. Bundlerのバージョンを確認
if [ -f "Gemfile.lock" ]; then
    BUNDLED_WITH=$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1 | tr -d ' ')
    if [ -n "$BUNDLED_WITH" ]; then
        info "必要なBundlerバージョン: $BUNDLED_WITH"
        CURRENT_BUNDLER=$(bundle -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        if [ "$CURRENT_BUNDLER" != "$BUNDLED_WITH" ]; then
            info "Bundler $BUNDLED_WITH をインストール中..."
            gem install bundler -v "$BUNDLED_WITH"
        fi
    fi
fi

# 2. bundle install を実行
info "bundle install を実行中..."
if bundle install; then
    success "bundle install が完了しました"
else
    error "bundle install が失敗しました"
    exit 1
fi

# 3. yarn install を実行（package.jsonが存在する場合）
if [ -f "package.json" ]; then
    info "yarn install を実行中..."
    if yarn install; then
        success "yarn install が完了しました"
    else
        error "yarn install が失敗しました"
        exit 1
    fi
else
    info "package.json が見つかりません。スキップします。"
fi

# 4. データベースのマイグレーション状態を確認
info "データベースのマイグレーション状態を確認中..."
if bin/rails db:migrate:status 2>/dev/null | grep -q "down"; then
    info "未実行のマイグレーションがあります。実行中..."
    if bin/rails db:migrate; then
        success "データベースマイグレーションが完了しました"
    else
        error "データベースマイグレーションが失敗しました"
        # マイグレーションの失敗は致命的ではないので続行
    fi
else
    success "データベースは最新の状態です"
fi

# 5. アセットのプリコンパイル（本番環境用、開発環境ではスキップ可能）
if [ "$RAILS_ENV" = "production" ] || [ "$PRECOMPILE_ASSETS" = "true" ]; then
    info "アセットをプリコンパイル中..."
    if bin/rails assets:precompile; then
        success "アセットのプリコンパイルが完了しました"
    else
        error "アセットのプリコンパイルが失敗しました"
        exit 1
    fi
else
    info "アセットのプリコンパイルはスキップします（開発環境）"
fi

# 6. JavaScriptのビルド（開発環境用）
if [ -f "package.json" ]; then
    info "JavaScriptをビルド中..."
    if yarn build 2>/dev/null || npm run build 2>/dev/null; then
        success "JavaScriptのビルドが完了しました"
    else
        info "JavaScriptのビルドスクリプトが見つかりません。スキップします。"
    fi
fi

# 7. Railsサーバーが起動しているか確認
if lsof -i:3000 >/dev/null 2>&1; then
    info "Railsサーバーが起動中です。再起動を推奨します。"
    echo ""
    echo "以下のコマンドでサーバーを再起動してください："
    echo "  docker-compose restart web"
    echo "  または"
    echo "  bin/rails restart"
fi

echo ""
echo "========================================="
success "同期が完了しました！"
echo "========================================="
echo ""
echo "次のステップ："
echo "  1. Railsサーバーを再起動してください"
echo "  2. ブラウザで http://localhost:3000 にアクセスして動作確認してください"
echo ""
