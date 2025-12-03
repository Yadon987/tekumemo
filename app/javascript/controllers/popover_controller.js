import { Controller } from "@hotwired/stimulus"

// ポップオーバー（吹き出し）制御用コントローラー
export default class extends Controller {
  static targets = ["content"]

  connect() {
    // 外側クリックで閉じるイベントを登録
    this.clickOutsideHandler = this.clickOutside.bind(this)
  }

  toggle(event) {
    event.stopPropagation() // 親要素への伝播を防ぐ

    if (this.contentTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.contentTarget.classList.remove("hidden")
    // 少し遅延させてイベントリスナーを登録（即座に閉じてしまうのを防ぐ）
    setTimeout(() => {
      document.addEventListener("click", this.clickOutsideHandler)
    }, 0)
  }

  close() {
    this.contentTarget.classList.add("hidden")
    document.removeEventListener("click", this.clickOutsideHandler)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
  }
}
