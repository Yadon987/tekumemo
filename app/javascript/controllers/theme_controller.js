import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sunIcon", "moonIcon", "toggleButton"]

  connect() {
    console.log("🌙 Theme controller connected!")
    this.initializeTheme()
    this.updateIcons()
  }

  disconnect() {
    console.log("🌙 Theme controller disconnected")
  }

  initializeTheme() {
    // 保存されたテーマまたはシステム設定を読み込み
    const savedTheme = localStorage.getItem('theme')
    const systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    
    console.log("💾 Saved theme:", savedTheme)
    console.log("🖥️ System prefers dark:", systemDark)
    
    if (savedTheme === 'dark' || (!savedTheme && systemDark)) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }

toggle() {
  console.log("🔄 Theme toggle clicked!")
  const html = document.documentElement
  const isDark = html.classList.toggle('dark')
  
  localStorage.setItem('theme', isDark ? 'dark' : 'light')
  console.log("💾 Theme saved:", isDark ? 'dark' : 'light')
  
  this.updateIcons()
}

  updateIcons() {
    const isDark = document.documentElement.classList.contains('dark')
    
    if (this.hasSunIconTarget && this.hasMoonIconTarget) {
      if (isDark) {
        // ダークモード時：太陽アイコン表示（ライトに戻すため）
        this.sunIconTarget.classList.remove('hidden')
        this.moonIconTarget.classList.add('hidden')
        console.log("☀️ Showing sun icon (dark mode active)")
      } else {
        // ライトモード時：月アイコン表示（ダークにするため）
        this.sunIconTarget.classList.add('hidden')
        this.moonIconTarget.classList.remove('hidden')
        console.log("🌙 Showing moon icon (light mode active)")
      }
    } else {
      console.warn("⚠️ Icon targets not found:", {
        hasSunIcon: this.hasSunIconTarget,
        hasMoonIcon: this.hasMoonIconTarget
      })
    }
  }
}
