// Google Fit連携のStimulus化のためのコントローラ  by Gemini3
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="google-fit"
export default class extends Controller {
  // 操作したい要素（ターゲット）を定義
  static targets = ["button", "status", "date", "steps", "calories", "distance", "duration"]

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
    this.statusTarget.classList.remove("text-red-500", "text-green-500", "text-orange-500")

    try {
      // 2. サーバーにデータを問い合わせる（30秒のタイムアウト設定）
      const response = await fetch(`/google_fit/daily_data?date=${date}`, {
        headers: {
          'Accept': 'application/json'
        },
        signal: AbortSignal.timeout(30000) // 30秒でタイムアウト
      })

      // レスポンスのJSONを先にパース（エラーレスポンスにも対応）
      const data = await response.json()

      // HTTPステータスコードに応じたエラーハンドリング
      if (!response.ok) {
        if (response.status === 401) {
          // 認証エラー：Googleとの連携が切れている
          this.statusTarget.textContent = "認証が切れました。再度Googleと連携してください。"
          this.statusTarget.classList.add("text-red-500")
          alert("Google認証の有効期限が切れました。\n設定画面で再度Google Fitと連携してください。")
          return
        } else if (response.status === 429) {
          // レート制限：リクエストが多すぎる
          this.statusTarget.textContent = "リクエスト制限中です。しばらく待ってから再試行してください。"
          this.statusTarget.classList.add("text-orange-500")
          alert("一時的にリクエスト制限がかかっています。\n数分待ってから再度お試しください。")
          return
        }
        // その他のHTTPエラー
        throw new Error(data.error || "データの取得に失敗しました")
      }

      // 3. 取得したデータを画面（入力欄）にセットする
      this.dateTarget.value = data.date || ""
      this.stepsTarget.value = data.steps || 0
      this.caloriesTarget.value = data.calories || 0
      this.distanceTarget.value = data.distance || 0
      this.durationTarget.value = data.duration || 0

      // 時間帯の自動選択
      if (data.start_time) {
        const startTime = new Date(data.start_time)
        const hour = startTime.getHours()
        let timeOfDay = "night"

        if (hour >= 4 && hour <= 8) {
          timeOfDay = "early_morning"
        } else if (hour >= 9 && hour <= 15) {
          timeOfDay = "day"
        } else if (hour >= 16 && hour <= 18) {
          timeOfDay = "evening"
        }

        // 対応するラジオボタンを選択
        const radio = this.element.querySelector(`input[name="walk[daypart]"][value="${timeOfDay}"]`)
        if (radio) {
          radio.checked = true
          // changeイベントを発火させてicon-selectコントローラーに通知
          radio.dispatchEvent(new Event("change", { bubbles: true }))
        }
      }

      // 4. 成功メッセージ
      this.statusTarget.textContent = "同期完了！✨"
      this.statusTarget.classList.add("text-green-500")

    } catch (error) {
      // 5. エラー時の処理（種類別に対応）
      console.error("Google Fit fetch error:", error)

      if (error.name === 'TimeoutError' || error.name === 'AbortError') {
        // タイムアウトエラー：通信に時間がかかりすぎた
        this.statusTarget.textContent = "タイムアウトしました。ネットワーク接続を確認してください。"
        this.statusTarget.classList.add("text-orange-500")
        alert("通信がタイムアウトしました。\n電波の良い場所で再度お試しください。")
      } else if (!navigator.onLine) {
        // オフライン：ネットワークに接続されていない
        this.statusTarget.textContent = "オフラインです。ネットワークに接続してください。"
        this.statusTarget.classList.add("text-red-500")
        alert("インターネットに接続されていません。\nWi-Fiやモバイルデータ通信を確認してください。")
      } else {
        // その他のエラー
        this.statusTarget.textContent = "エラーが発生しました。再試行してください。"
        this.statusTarget.classList.add("text-red-500")
        alert("Google Fitからのデータ取得に失敗しました。\nしばらく時間をおいて再度お試しください。")
      }

    } finally {
      // 6. 後始末：ボタンを元に戻す
      this.buttonTarget.disabled = false
      this.buttonTarget.innerHTML = originalContent
    }
  }
}
