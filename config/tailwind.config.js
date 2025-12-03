const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  // コンテンツパスの設定
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/assets/stylesheets/**/*.css'
  ],

  // ダークモード設定
  darkMode: 'class',

  theme: {
    extend: {
      // カスタムカラー
      colors: {
        primary: '#1976D2',
        'background-light': '#F7F8FC',
        'background-dark': '#121212',
      },

      // フォント設定
      fontFamily: {
        display: ['Noto Sans JP', ...defaultTheme.fontFamily.sans],
        sans: ['Noto Sans JP', ...defaultTheme.fontFamily.sans],
      },

      // 角丸設定
      borderRadius: {
        DEFAULT: '1rem',
      },
      // アニメーション設定
      animation: {
        'zoom-in': 'zoomIn 0.3s ease-out',
        'fade-in-up': 'fadeInUp 0.2s ease-out forwards',
      },
      keyframes: {
        zoomIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(10px) scale(0.95)' },
          '100%': { opacity: '1', transform: 'translateY(0) scale(1)' },
        },
      },
    },
  },

  // プラグイン
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
