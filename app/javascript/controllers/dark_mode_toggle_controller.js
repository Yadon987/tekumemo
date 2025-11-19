import { Controller } from "@hotwired/stimulus"

// =====================================
// ダークモード切り替えトグルスイッチ
// =====================================
// iOS風のトグルスイッチでダークモードとライトモードを切り替えます
// アニメーション付きで見た目も楽しいUIになっています

export default class extends Controller {
  // Stimulusが管理する要素（targets）を定義
  static targets = ["toggle", "slider", "icon"]

  // コントローラーが読み込まれた時に実行される
  connect() {
    // ページ読み込み時に、現在のテーマ設定を反映
    this.updateUI()
  }

  // トグルスイッチがクリックされた時の処理
  toggle() {
    // 現在のテーマ状態を取得
    const currentTheme = localStorage.getItem('theme') || 'light'

    // テーマを切り替える
    if (currentTheme === 'dark') {
      // ダークモード → ライトモード
      this.setLightMode()
    } else {
      // ライトモード → ダークモード
      this.setDarkMode()
    }
  }

  // ライトモードに設定
  setLightMode() {
    // htmlタグからdarkクラスを削除
    document.documentElement.classList.remove('dark')
    // localStorageに保存
    localStorage.setItem('theme', 'light')
    // UIを更新
    this.updateUI()
  }

  // ダークモードに設定
  setDarkMode() {
    // htmlタグにdarkクラスを追加
    document.documentElement.classList.add('dark')
    // localStorageに保存
    localStorage.setItem('theme', 'dark')
    // UIを更新
    this.updateUI()
  }

  // UIの表示を現在のテーマに合わせて更新
  updateUI() {
    // 現在のテーマ状態を取得
    const currentTheme = localStorage.getItem('theme') || 'light'
    const isDark = currentTheme === 'dark'

    // トグルボタンの背景色を変更
    if (isDark) {
      // ダークモード時：青いグラデーション背景
      this.toggleTarget.classList.remove('bg-gray-300')
      this.toggleTarget.classList.add('bg-gradient-to-r', 'from-blue-500', 'to-sky-400')
    } else {
      // ライトモード時：グレー背景
      this.toggleTarget.classList.remove('bg-gradient-to-r', 'from-blue-500', 'to-sky-400')
      this.toggleTarget.classList.add('bg-gray-300')
    }

    // スライダー（丸いつまみ）の位置を変更
    if (isDark) {
      // ダークモード時：右側に移動
      this.sliderTarget.style.transform = 'translateX(28px)'
    } else {
      // ライトモード時：左側に移動
      this.sliderTarget.style.transform = 'translateX(0)'
    }

    // アイコンの表示/非表示を切り替え
    this.iconTargets.forEach((icon) => {
      const iconType = icon.dataset.icon

      if (isDark && iconType === 'sun') {
        // ダークモード時は太陽アイコンを表示
        icon.classList.remove('opacity-0', 'scale-0')
        icon.classList.add('opacity-100', 'scale-100')
      } else if (!isDark && iconType === 'moon') {
        // ライトモード時は月アイコンを表示
        icon.classList.remove('opacity-0', 'scale-0')
        icon.classList.add('opacity-100', 'scale-100')
      } else {
        // それ以外は非表示
        icon.classList.remove('opacity-100', 'scale-100')
        icon.classList.add('opacity-0', 'scale-0')
      }
    })
  }
}
