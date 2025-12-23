import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "image", "loading", "container"]
  static values = {
    retryCount: { type: Number, default: 0 },
    maxRetries: { type: Number, default: 5 }
  }

  connect() {
    // ESCキーで閉じる
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)

    // ページ内の他のOGP画像更新イベントを購読
    this.boundHandleSync = this.handleSync.bind(this)
    document.addEventListener("ogp:refresh", this.boundHandleSync)

    // モーダルオープンイベントを購読
    this.boundHandleOpen = this.handleOpen.bind(this)
    document.addEventListener("ogp:open", this.boundHandleOpen)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    document.removeEventListener("ogp:refresh", this.boundHandleSync)
    document.removeEventListener("ogp:open", this.boundHandleOpen)
  }

  // モーダルを開くイベントハンドラ
  handleOpen() {
    this.open()
  }

  // モーダルを開く
  open(e) {
    if (e) e.preventDefault()
    if (!this.hasModalTarget) return

    this.modalTarget.classList.remove("hidden")

    // フェードイン
    requestAnimationFrame(() => {
      this.modalTarget.style.opacity = "1"
    })

    this.retryCountValue = 0
  }

  // モーダルを閉じる
  close(e) {
    if (e) {
      // モーダルの中身をクリックした場合は閉じない
      if (this.containerTarget.contains(e.target)) return
      e.preventDefault()
    }

    this.modalTarget.style.opacity = "0"
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
    }, 200)
  }

  // キーボードイベント処理
  handleKeydown(e) {
    if (e.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  // 画像をリフレッシュ（同期イベント発火）
  refresh() {
    // 自分の画像を更新
    this.reloadImage()

    // 他のコンポーネントにも更新を通知
    const event = new CustomEvent("ogp:refresh")
    document.dispatchEvent(event)
  }

  // 外部からの更新イベントを受信
  handleSync() {
    // 自分が発火元でない場合のみ更新（無限ループ防止はreloadImage内のロジックで制御してもよいが、ここでは単純にリロード）
    // ただし、モーダルが開いていない場合は無駄なロードを避けるなどの最適化も可能
    // 今回は「同期」が目的なので、開いていなくても裏で更新しておくと次回開いたときに最新になる
    this.reloadImage()
  }

  // 画像再読み込みの実処理
  reloadImage() {
    // ローディング表示
    this.loadingTarget.style.display = "flex"
    this.imageTarget.classList.remove("opacity-100")
    this.imageTarget.classList.add("opacity-0")

    // 現在のsrcを取得し、refreshパラメータを付与
    const currentSrc = new URL(this.imageTarget.src)
    currentSrc.searchParams.set("refresh", "true")
    currentSrc.searchParams.set("v", new Date().getTime()) // キャッシュバスター

    // 画像を再読み込み
    this.imageTarget.src = currentSrc.toString()
  }

  // 画像読み込み成功
  handleLoad() {
    this.loadingTarget.style.display = "none"
    this.imageTarget.classList.remove("opacity-0")
    this.imageTarget.classList.add("opacity-100")
  }

  // 画像読み込み失敗（生成中の可能性）
  handleError() {
    if (this.retryCountValue < this.maxRetriesValue) {
      this.retryCountValue++

      // ローディングメッセージ更新
      const loadingText = this.loadingTarget.querySelector("p.font-bold")
      if (loadingText) {
        loadingText.textContent = `画像を生成中... (${this.retryCountValue}/${this.maxRetriesValue})`
      }

      // 2秒後にリトライ
      setTimeout(() => {
        const currentSrc = new URL(this.imageTarget.src)
        currentSrc.searchParams.set("v", new Date().getTime())
        this.imageTarget.src = currentSrc.toString()
      }, 2000)
    } else {
      // リトライ上限
      this.loadingTarget.innerHTML = `
        <div class="text-center">
          <span class="text-4xl">⚠️</span>
          <p class="mt-4 text-sm font-bold text-slate-600 dark:text-purple-300">画像の読み込みに失敗しました</p>
          <p class="mt-2 text-xs text-slate-500 dark:text-slate-400">ページをリロードしてください</p>
        </div>
      `
    }
  }
}
