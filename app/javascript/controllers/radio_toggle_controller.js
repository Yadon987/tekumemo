import { Controller } from "@hotwired/stimulus"

// ラジオボタンの選択解除を可能にするコントローラー
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // 初期状態を保存
    this.lastChecked = null
    this.inputTargets.forEach(input => {
      if (input.checked) {
        this.lastChecked = input
      }
    })
  }

  toggle(event) {
    const input = event.currentTarget

    if (input === this.lastChecked) {
      // 既に選択されているものを再度クリックした場合、選択解除
      input.checked = false
      this.lastChecked = null

      // changeイベントを発火させて、他のリスナー（もしあれば）に通知
      input.dispatchEvent(new Event("change", { bubbles: true }))
    } else {
      // 新しく選択された場合
      this.lastChecked = input
    }
  }
}
