import { Controller } from "@hotwired/stimulus";

// フラッシュメッセージを高度に制御するコントローラー
// - 自動消滅 (標準5秒)
// - ドロップダウンアニメーション (Dynamic Island風)
// - クリックで即時削除
export default class extends Controller {
  connect() {
    // 表示初期状態: 上に隠して少し小さくしておく
    // transition-all duration-500 cubic-bezier(0.34, 1.56, 0.64, 1) <- 弾むような動き
    this.element.classList.add(
      "transition-all",
      "duration-500",
      "ease-out", // またはカスタムcubic-bezierで弾ませるのもあり
      "transform",
      "-translate-y-full",
      "scale-90",
      "opacity-0"
    );

    // ビューのレンダリング後にアニメーション開始（降りてくる）
    requestAnimationFrame(() => {
      this.element.classList.remove("-translate-y-full", "scale-90", "opacity-0");
    });

    // 5秒後に自動消滅開始
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, 5000);
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  // メッセージを閉じるアクション
  dismiss() {
    if (this.element.dataset.dismissing) return;
    this.element.dataset.dismissing = "true";

    // 上へ退場
    this.element.classList.add("-translate-y-full", "scale-90", "opacity-0");

    // アニメーション完了後にDOMから削除
    setTimeout(() => {
      this.element.remove();
    }, 500);
  }
}
