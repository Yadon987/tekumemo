const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/assets/stylesheets/**/*.css'
  ],
  // ダークモード設定: classベース
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // プライマリカラー
        primary: '#1976D2',
        // 背景色
        'background-light': '#F7F8FC',
        'background-dark': '#121212',
      },
      fontFamily: {
        // 日本語フォント設定
        display: ['Noto Sans JP', ...defaultTheme.fontFamily.sans],
        sans: ['Noto Sans JP', ...defaultTheme.fontFamily.sans],
      },
      borderRadius: {
        DEFAULT: '1rem',
      },
      // グラデーション関連のユーティリティを有効化
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
      },
      // カスタムアニメーション
      animation: {
        'bounce-slow': 'bounce 3s ease-in-out infinite',
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.4s ease-out',
        'pulse-fast': 'pulseDeep 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'sparkle': 'sparkle 4.5s ease-in-out infinite',
        'sparkle-scale': 'sparkleScale 4.5s ease-in-out infinite',
      },
      keyframes: {
        sparkle: {
          '0%, 85%, 100%': {
            filter: 'drop-shadow(0 2px 2px rgba(0,0,0,0.8)) drop-shadow(0 0 15px rgba(250,204,21,0.5))',
            transform: 'scale(1)'
          },
          '92.5%': {
            filter: 'drop-shadow(0 2px 2px rgba(0,0,0,0.8)) drop-shadow(0 0 60px rgba(250,204,21,0.8)) drop-shadow(0 0 25px rgba(255,255,255,0.6))',
            transform: 'scale(1.15)'
          },
        },
        sparkleScale: {
          '0%, 85%, 100%': { transform: 'scale(1)' },
          '92.5%': { transform: 'scale(1.05)' },
        },
        pulseDeep: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.3' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  // プラグイン設定
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
  // 重要: JITモードでのsafelist設定（必要に応じて）
  safelist: [
    // グラデーション関連
    'bg-gradient-to-r',
    'bg-gradient-to-br',
    'from-sky-400',
    'from-sky-500',
    'from-sky-600',
    'from-sky-800',
    'via-blue-700',
    'via-blue-900',
    'to-blue-500',
    'to-blue-600',
    'to-indigo-800',
    'to-indigo-950',
    'bg-clip-text',
    'text-transparent',
    // お知らせバッジ用の背景色
    'bg-red-500',
    'bg-orange-500',
    'bg-yellow-500',
    'bg-yellow-600',
    'bg-blue-500',
  ],
}
