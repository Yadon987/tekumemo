import { Controller } from "@hotwired/stimulus"

// 文字数カウンターコントローラー
export default class extends Controller {
  static targets = ["input", "counter"]
  static values = { max: Number }

  connect() {
    console.log("Character counter connected!")
    this.update()
  }

  update() {
    const length = this.inputTarget.value.length
    const remaining = this.maxValue - length

    this.counterTarget.textContent = `${length} / ${this.maxValue}`

    if (remaining < 0) {
      // 超過時: 赤字にする
      this.counterTarget.classList.add("text-red-500", "dark:text-red-400", "font-bold")
      this.counterTarget.classList.remove("text-gray-400", "dark:text-purple-300/70")
    } else {
      // 通常時: グレー/紫に戻す
      this.counterTarget.classList.remove("text-red-500", "dark:text-red-400", "font-bold")
      this.counterTarget.classList.add("text-gray-400", "dark:text-purple-300/70")
    }
  }
}
