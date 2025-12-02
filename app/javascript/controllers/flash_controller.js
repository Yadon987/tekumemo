import { Controller } from "@hotwired/stimulus";

// フラッシュメッセージを一定時間後に自動的に消去するコントローラー
export default class extends Controller {
  connect() {
    // 5秒後にフェードアウトを開始
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, 5000);
  }

  disconnect() {
    // コントローラーが外れたらタイマーをクリア
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  dismiss() {
    // フェードアウトのアニメーションクラスを追加
    this.element.classList.add(
      "transition-opacity",
      "duration-1000",
      "opacity-0"
    );

    // アニメーション完了後（1秒後）に要素をDOMから削除
    setTimeout(() => {
      this.element.remove();
    }, 1000);
  }
}
