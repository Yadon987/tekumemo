import { Controller } from "@hotwired/stimulus"

// フローティングメニューの開閉を制御するコントローラー
export default class extends Controller {
  // Stimulusが管理する要素（targets）を定義
  static targets = ["menu"]

  // メニューの開閉状態を切り替える
  toggle() {
    // メニュー要素のhiddenクラスをトグル（追加/削除）
    this.menuTarget.classList.toggle("hidden")
  }

  // メニュー外をクリックしたときにメニューを閉じる
  closeIfOutside(event) {
    // クリックされた要素がこのコントローラーの範囲外の場合
    if (!this.element.contains(event.target)) {
      // メニューを閉じる
      this.menuTarget.classList.add("hidden")
    }
  }

  // コントローラーが接続されたときに実行
  connect() {
    // ドキュメント全体のクリックイベントを監視
    // メニュー外をクリックしたときにメニューを閉じるため
    this.closeHandler = this.closeIfOutside.bind(this)
    document.addEventListener("click", this.closeHandler)
  }

  // コントローラーが切断されたときに実行
  disconnect() {
    // イベントリスナーを削除（メモリリーク防止）
    document.removeEventListener("click", this.closeHandler)
  }
}
