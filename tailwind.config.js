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
      },
      keyframes: {
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
  ],
}
