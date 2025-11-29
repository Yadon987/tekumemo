import { Controller } from "@hotwired/stimulus"

// 数値をカウントアップさせるアニメーションコントローラー
export default class extends Controller {
  static values = {
    target: Number, // 目標値（最終的な数値）
    duration: { type: Number, default: 1500 }, // アニメーション時間（ミリ秒）
    delimiter: { type: Boolean, default: true } // 3桁区切りをするかどうか
  }

  connect() {
    this.animate()
  }

  animate() {
    const start = 0
    const end = this.targetValue
    const duration = this.durationValue
    const startTime = performance.now()

    const update = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)

      // イージング関数（easeOutExpo）で自然な減速を実現
      const easeOut = (x) => x === 1 ? 1 : 1 - Math.pow(2, -10 * x)

      const current = start + (end - start) * easeOut(progress)

      // 小数点以下の桁数を判定（元の数値が小数の場合）
      const decimals = end.toString().includes('.') ? end.toString().split('.')[1].length : 0

      let formattedNumber = current.toFixed(decimals)

      if (this.delimiterValue) {
        // 整数部分と小数部分を分けて3桁区切り
        const parts = formattedNumber.split('.')
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        formattedNumber = parts.join('.')
      }

      this.element.textContent = formattedNumber

      if (progress < 1) {
        requestAnimationFrame(update)
      } else {
        // 最終的な値を正確にセット
        let finalNumber = end.toFixed(decimals)
        if (this.delimiterValue) {
            const parts = finalNumber.split('.')
            parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
            finalNumber = parts.join('.')
        }
        this.element.textContent = finalNumber
      }
    }

    requestAnimationFrame(update)
  }
}
