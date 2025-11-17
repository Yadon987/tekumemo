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
    },
  },
  
  // プラグイン
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
