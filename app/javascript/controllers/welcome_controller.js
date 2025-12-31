import { Controller } from "@hotwired/stimulus"

// 初回ウェルカムモーダル用コントローラー
export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // 既に見たことがあるかチェック
    const hasSeenWelcome = localStorage.getItem('hasSeenWelcomeModal')

    if (!hasSeenWelcome) {
      // 少し遅延させて表示（ページ描画完了待ち）
      setTimeout(() => {
        this.open()
      }, 800)
    }
  }

  open() {
    this.modalTarget.classList.remove('hidden')
    // アニメーション用クラス追加（少し待ってから）
    setTimeout(() => {
      this.modalTarget.classList.remove('opacity-0')
      this.modalTarget.querySelector('.modal-content').classList.remove('scale-90', 'opacity-0')
    }, 10)
  }

  close() {
    // アニメーション用（フェードアウト）
    this.modalTarget.classList.add('opacity-0')
    this.modalTarget.querySelector('.modal-content').classList.add('scale-90', 'opacity-0')

    setTimeout(() => {
      this.modalTarget.classList.add('hidden')
    }, 300)

    // 見たことを記録
    localStorage.setItem('hasSeenWelcomeModal', 'true')
  }
}
