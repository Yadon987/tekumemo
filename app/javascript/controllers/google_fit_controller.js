// Google Fit連携のStimulus化のためのコントローラ  by Gemini3
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="google-fit"
export default class extends Controller {
  // 操作したい要素（ターゲット）を定義
  static targets = [ "button", "status", "date", "steps", "calories", "distance", "duration" ]

  connect() {
    // 接続確認用（ブラウザのコンソールに表示されます）
    console.log("Google Fit Controller Connected! 🚀")
  }

  // ボタンがクリックされたら実行されるアクション
  async fetch(event) {
    event.preventDefault() // フォーム送信などを防ぐ

// 日付が選択されているかチェック
    const date = this.dateTarget.value
    if (!date) {
      alert("日付を選択してください")
      return
    }

    // 1. ローディング開始：ボタンを押せなくして、スピナーを表示する
    this.buttonTarget.disabled = true
    const originalContent = this.buttonTarget.innerHTML

    // ローディングスピナーのHTML
    const spinnerHtml = `
      <div class="flex items-center justify-center w-full py-1">
        <svg class="animate-spin -ml-1 mr-3 h-6 w-6 text-blue-500 dark:text-cyan-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="font-bold text-blue-600 dark:text-cyan-400">データ取得中...</span>
      </div>
    `
    this.buttonTarget.innerHTML = spinnerHtml
    this.statusTarget.textContent = "同期を開始しました..."
    this.statusTarget.classList.remove("text-red-500", "text-green-500")

    try {
      // 2. サーバーにデータを問い合わせる
      const response = await fetch(`/google_fit/daily_data?date=${date}`, {
        headers: {
          'Accept': 'application/json'
        }
      })

      if (!response.ok) throw new Error("データの取得に失敗しました")

      const data = await response.json()

      // 3. 取得したデータを画面（入力欄）にセットする
      this.dateTarget.value     = data.date || ""
      this.stepsTarget.value    = data.steps || 0
      this.caloriesTarget.value = data.calories || 0
      this.distanceTarget.value = data.distance || 0
      this.durationTarget.value = data.duration || 0

      // 4. 成功メッセージ
      this.statusTarget.textContent = "同期完了！✨"
      this.statusTarget.classList.add("text-green-500")

    } catch (error) {
      // 5. エラー時の処理
      console.error(error)
      this.statusTarget.textContent = "エラーが発生しました。再試行してください。"
      this.statusTarget.classList.add("text-red-500")
      alert("Google Fitからのデータ取得に失敗しました。ログイン状態などを確認してください。")

    } finally {
      // 6. 後始末：ボタンを元に戻す
      this.buttonTarget.disabled = false
      this.buttonTarget.innerHTML = originalContent
    }
  }
}
