/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js'
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        primary: "#1976D2",
        "background-light": "#F7F8FC",
        "background-dark": "#121212",
      },
      fontFamily: {
        display: ["Noto Sans JP", "sans-serif"],
      },
      borderRadius: {
        DEFAULT: "1rem",
      },
    },
  },
  plugins: [],
}
