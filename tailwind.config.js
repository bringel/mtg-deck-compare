/** @type {import('tailwindcss').Config} */
const colors = require('tailwindcss/colors')

module.exports = {
  content: ['./web/index.html', './web/src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: colors.sky,
        secondary: colors.purple,
        background: colors.zinc,
        common: '#1a1718',
        uncommon: '#707883',
        rare: '#a58e4a',
        mythic: '#bf4427',
        timeshifted: '#652978'
      }
    }
  },
  plugins: [require('@tailwindcss/forms'), require('@tailwindcss/line-clamp')]
}
