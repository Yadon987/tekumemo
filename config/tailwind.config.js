const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: '#1976D2',
        'background-light': '#F7F8FC',
        'background-dark': '#121212',
      },
      fontFamily: {
        display: ['Noto Sans JP', ...defaultTheme.fontFamily.sans],
        sans: ['Noto Sans JP', ...defaultTheme.fontFamily.sans],
      },
      borderRadius: {
        DEFAULT: '1rem',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
