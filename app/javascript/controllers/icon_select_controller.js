import { Controller } from "@hotwired/stimulus"

// アイコンボタンによるラジオボタン選択コントローラー
export default class extends Controller {
  static targets = ["input", "button"]
  static classes = ["selected", "unselected"]

  connect() {
    this.updateState()
    // ラジオボタンの変更を監視
    this.inputTargets.forEach(input => {
      input.addEventListener('change', () => this.updateState())
    })
  }

  select(event) {
    // クリックされたボタンに対応するラジオボタンの値を取得
    const value = event.currentTarget.dataset.value

    // 対応するラジオボタンを選択
    const input = this.inputTargets.find(i => i.value === value)
    if (input) {
      input.checked = true
      this.updateState()
    }
  }

  updateState() {
    // 現在選択されている値を取得
    const checkedInput = this.inputTargets.find(i => i.checked)
    const checkedValue = checkedInput ? checkedInput.value : null

    // 各ボタンの見た目を更新
    this.buttonTargets.forEach(button => {
      if (button.dataset.value === checkedValue) {
        button.classList.add(...this.selectedClasses)
        button.classList.remove(...this.unselectedClasses)
      } else {
        button.classList.remove(...this.selectedClasses)
        button.classList.add(...this.unselectedClasses)
      }
    })
  }
}
