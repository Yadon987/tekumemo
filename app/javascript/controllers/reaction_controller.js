import { Controller } from "@hotwired/stimulus"

// リアクションボタン制御用コントローラー
export default class extends Controller {
  static values = {
    url: String,
    kind: String,
    count: Number,
    reacted: Boolean
  }
  static targets = ["button", "count", "emoji"]

  toggle(event) {
    event.preventDefault()

    // 1. Optimistic UI: サーバー応答を待たずにUIを即座に更新
    this.reactedValue = !this.reactedValue
    if (this.reactedValue) {
      this.countValue++
    } else {
      this.countValue--
    }
    this.updateUI()

    // 2. サーバーへリクエスト
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ reaction: { kind: this.kindValue } })
    })
    .then(response => {
      if (!response.ok) throw new Error("Network response was not ok")
      return response.json()
    })
    .then(data => {
      // 3. サーバーからの正確な値で同期
      this.reactedValue = data.reacted
      this.countValue = data.count
      this.updateUI()
    })
    .catch(error => {
      console.error("Error:", error)
      // エラー時は元に戻す
      this.reactedValue = !this.reactedValue
      if (this.reactedValue) {
        this.countValue++
      } else {
        this.countValue--
      }
      this.updateUI()
      alert("通信エラーが発生しました")
    })
  }

  updateUI() {
    const btn = this.buttonTarget

    if (this.reactedValue) {
      // Active state
      btn.classList.add("bg-blue-100", "text-blue-600", "border-blue-300")
      btn.classList.remove("bg-gray-100", "text-gray-600", "border-gray-300")
    } else {
      // Inactive state
      btn.classList.remove("bg-blue-100", "text-blue-600", "border-blue-300")
      btn.classList.add("bg-gray-100", "text-gray-600", "border-gray-300")
    }

    // カウント表示の更新
    this.countTarget.textContent = this.countValue

    // ボタン全体の表示/非表示制御
    if (this.countValue > 0 || this.reactedValue) {
      btn.classList.remove("hidden")
      this.countTarget.classList.remove("hidden")
    } else {
      btn.classList.add("hidden")
    }

    // アニメーション効果
    this.emojiTarget.classList.remove("scale-125")
    void this.emojiTarget.offsetWidth // Trigger reflow
    this.emojiTarget.classList.add("scale-125")
    setTimeout(() => {
      this.emojiTarget.classList.remove("scale-125")
    }, 200)

    // ピッカー内のボタンの状態も同期
    const pickerBtnId = this.buttonTarget.id.replace("reaction-btn-", "picker-btn-")
    const pickerBtn = document.getElementById(pickerBtnId)
    if (pickerBtn) {
      if (this.reactedValue) {
        pickerBtn.classList.add("bg-blue-50", "dark:bg-blue-900/20")
      } else {
        pickerBtn.classList.remove("bg-blue-50", "dark:bg-blue-900/20")
      }
    }
  }
}
