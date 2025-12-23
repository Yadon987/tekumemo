const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
    "./app/assets/stylesheets/**/*.css",
  ],
  // ダークモード設定: classベース
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        // プライマリカラー
        primary: "#1976D2",
        // 背景色
        "background-light": "#F7F8FC",
        "background-dark": "#121212",
        // Claymorphism Colors
        clay: {
          bg: "#fdf5e6", // Warm peachy beige (health app style)
          card: "#ffffff", // Pure White
          primary: "#60a5fa", // blue-400
          accent: "#fb923c", // orange-400
        },
      },
      fontFamily: {
        // 日本語フォント設定
        display: ["Noto Sans JP", ...defaultTheme.fontFamily.sans],
        sans: ["Noto Sans JP", ...defaultTheme.fontFamily.sans],
      },
      borderRadius: {
        DEFAULT: "1rem",
        clay: "2.5rem", // 40px
      },
      boxShadow: {
        // Claymorphism Shadows (TEST: Darker color + Higher opacity)
        // カード用: 仮説5+6検証 - 影の色を暗く、不透明度を大幅UP
        "clay-card":
          "0 20px 40px -5px rgba(59, 130, 246, 0.15), 0 10px 20px -5px rgba(59, 130, 246, 0.1)",
        // 右上ボタン用
        "clay-floating":
          "0 6px 16px rgba(50, 60, 70, 0.4), 0 3px 8px rgba(50, 60, 70, 0.2)",
        // アイコン用（凸）: 不要になったので削除可能
        "clay-icon":
          "8px 8px 20px rgba(192, 197, 208, 0.3), -6px -6px 12px rgba(255, 255, 255, 0.5)",
        // ボタン用: 色付きの影（Glow）
        "clay-btn-blue":
          "0 10px 25px -5px rgba(59, 130, 246, 0.6), 0 8px 10px -6px rgba(59, 130, 246, 0.2)",
        "clay-btn-orange":
          "0 10px 25px -5px rgba(249, 115, 22, 0.6), 0 8px 10px -6px rgba(249, 115, 22, 0.2)",
        // 凹み（アイコン背景など）- 必要なら残す
        "clay-inner":
          "inset 6px 6px 10px #cbd5e1, inset -6px -6px 10px #ffffff",
        // Dark Mode Glow
        "neon-blue":
          "0 0 15px rgba(59, 130, 246, 0.6), 0 0 30px rgba(59, 130, 246, 0.3)",
        "neon-purple":
          "0 0 15px rgba(168, 85, 247, 0.6), 0 0 30px rgba(168, 85, 247, 0.3)",
      },
      // グラデーション関連のユーティリティを有効化
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "clay-gradient": "linear-gradient(145deg, #ffffff, #e6e6e6)",
        // ボタン用グラデーション
        "btn-blue-grad": "linear-gradient(to bottom, #60a5fa, #3b82f6)",
        "btn-orange-grad": "linear-gradient(to bottom, #fb923c, #f97316)",
      },
      // カスタムアニメーション
      animation: {
        "bounce-slow": "bounce 3s ease-in-out infinite",
        "fade-in": "fadeIn 0.8s ease-out",
        "slide-up": "slideUp 0.6s ease-out",
        "pulse-fast": "pulseDeep 3s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        "pulse-slow": "pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite", // God Mode: Breathing Glow
        shimmer: "shimmer 2s linear infinite", // God Mode: Shining Effect
        sparkle: "sparkle 4.5s ease-in-out infinite",
        "sparkle-scale": "sparkleScale 4.5s ease-in-out infinite",
        float: "float 6s ease-in-out infinite",
        "gradient-xy": "gradient-xy 15s ease infinite",
        // LPミニチュアUI用アニメーション
        dash: "dash 1.5s ease-out forwards",
        "grow-h-12": "growH12 1s ease-out forwards",
        "grow-h-16": "growH16 1s ease-out forwards",
        "grow-h-24": "growH24 1s ease-out forwards",
        "pop-in": "pop-in 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) both",
        "float-up": "float-up 2s ease-out infinite both",
      },
      keyframes: {
        shimmer: {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(100%)" },
        },
        sparkle: {
          "0%, 85%, 100%": {
            filter:
              "drop-shadow(0 2px 2px rgba(0,0,0,0.8)) drop-shadow(0 0 15px rgba(250,204,21,0.5))",
            transform: "scale(1)",
          },
          "92.5%": {
            filter:
              "drop-shadow(0 2px 2px rgba(0,0,0,0.8)) drop-shadow(0 0 60px rgba(250,204,21,0.8)) drop-shadow(0 0 25px rgba(255,255,255,0.6))",
            transform: "scale(1.15)",
          },
        },
        sparkleScale: {
          "0%, 85%, 100%": { transform: "scale(1)" },
          "92.5%": { transform: "scale(1.05)" },
        },
        pulseDeep: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.3" },
        },
        fadeIn: {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        slideUp: {
          "0%": { transform: "translateY(30px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-10px)" },
        },
        "gradient-xy": {
          "0%, 100%": {
            "background-size": "400% 400%",
            "background-position": "0% 0%",
          },
          "50%": {
            "background-size": "400% 400%",
            "background-position": "100% 100%",
          },
        },
        // LPミニチュアUI用キーフレーム
        dash: {
          "0%": { "stroke-dashoffset": "283" },
          "100%": { "stroke-dashoffset": "70" }, // 75%くらいの位置
        },
        growH12: {
          "0%": { height: "0" },
          "100%": { height: "3rem" }, // h-12
        },
        growH16: {
          "0%": { height: "0" },
          "100%": { height: "4rem" }, // h-16
        },
        growH24: {
          "0%": { height: "0" },
          "100%": { height: "6rem" }, // h-24
        },
        "pop-in": {
          "0%": { opacity: "0", transform: "translate(-50%, 20px) scale(0.5)" },
          "100%": { opacity: "1", transform: "translate(-50%, 0) scale(1)" },
        },
        "float-up": {
          "0%": { opacity: "0", transform: "translateY(10px) scale(0.5)" },
          "20%": { opacity: "1", transform: "translateY(0) scale(1)" },
          "80%": { opacity: "1", transform: "translateY(-20px) scale(1)" },
          "100%": { opacity: "0", transform: "translateY(-30px) scale(0.5)" },
        },
      },
    },
  },
  // プラグイン設定
  plugins: [require("@tailwindcss/forms"), require("@tailwindcss/typography")],
  // 重要: JITモードでのsafelist設定（必要に応じて）
  safelist: [
    // グラデーション関連
    "bg-gradient-to-r",
    "bg-gradient-to-br",
    "from-sky-400",
    "from-sky-500",
    "from-sky-600",
    "from-sky-800",
    "via-blue-700",
    "via-blue-900",
    "to-blue-500",
    "to-blue-600",
    "to-indigo-800",
    "to-indigo-950",
    "bg-clip-text",
    "text-transparent",
    // お知らせバッジ用の背景色
    "bg-red-500",
    "bg-orange-500",
    "bg-yellow-500",
    "bg-yellow-600",
    "bg-blue-500",
    // Claymorphism
    "shadow-clay-card",
    "shadow-clay-floating",
    "shadow-clay-btn-blue",
    "shadow-clay-btn-orange",
    "shadow-clay-icon",
    "shadow-clay-inner",
  ],
};
