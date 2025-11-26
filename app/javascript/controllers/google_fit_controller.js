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

    // 1. ローディング開始：ボタンを押せなくして、テキストを変える
    this.buttonTarget.disabled = true
    const originalContent = this.buttonTarget.innerHTML
    this.buttonTarget.textContent = "データ取得中..."
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
