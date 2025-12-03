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
    console.log("Update called")
    const length = this.inputTarget.value.length
    const remaining = this.maxValue - length

    this.counterTarget.textContent = `${length} / ${this.maxValue}`

    if (remaining < 0) {
      this.counterTarget.classList.add("text-red-500", "font-bold")
      this.counterTarget.classList.remove("text-gray-400")
    } else {
      this.counterTarget.classList.remove("text-red-500", "font-bold")
      this.counterTarget.classList.add("text-gray-400")
    }
  }
}
