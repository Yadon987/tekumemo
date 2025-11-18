import { Controller } from "@hotwired/stimulus"

// Expandable FAB（展開可能なFloating Action Button）の制御
export default class extends Controller {
  // Stimulusが管理する要素（targets）を定義
  static targets = ["overlay", "mainButton", "actionButton"]

  // 初期化時に実行
  connect() {
    // 開閉状態を管理する変数
    this.isOpen = false

    // オーバーレイクリック時にメニューを閉じる
    this.closeHandler = this.close.bind(this)
  }

  // FABの開閉を切り替える
  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  // FABを開く
  open() {
    this.isOpen = true

    // メインボタンを45度回転（✕マークのように見せる）
    this.mainButtonTarget.style.transform = "rotate(45deg)"

    // オーバーレイを表示
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("opacity-50")

    // アクションボタンを順番に表示（下から上へ）
    this.actionButtonTargets.forEach((button, index) => {
      setTimeout(() => {
        // hiddenクラスを削除して表示
        button.classList.remove("hidden")
        // 透明度を0から1に変更
        button.classList.remove("opacity-0")
        button.classList.add("opacity-100")
        // 下から上へ移動（transformを使用）
        button.style.transform = "translateY(0)"
      }, index * 50) // 50msずつ遅延させてアニメーション
    })
  }

  // FABを閉じる
  close() {
    this.isOpen = false

    // メインボタンの回転を元に戻す
    this.mainButtonTarget.style.transform = "rotate(0deg)"

    // オーバーレイを非表示
    this.overlayTarget.classList.remove("opacity-50")
    this.overlayTarget.classList.add("opacity-0")
    setTimeout(() => {
      this.overlayTarget.classList.add("hidden")
    }, 200)

    // アクションボタンを順番に非表示（上から下へ）
    this.actionButtonTargets.forEach((button, index) => {
      setTimeout(() => {
        // 透明度を1から0に変更
        button.classList.remove("opacity-100")
        button.classList.add("opacity-0")
        // 下方向へ移動
        button.style.transform = "translateY(20px)"

        // アニメーション完了後にhiddenクラスを追加
        setTimeout(() => {
          button.classList.add("hidden")
        }, 200)
      }, index * 30) // 30msずつ遅延させてアニメーション
    })
  }

  // コントローラーが切断されたときに実行
  disconnect() {
    // クリーンアップ処理（特に必要なし）
  }
}
