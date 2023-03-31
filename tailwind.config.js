/** @type {import('tailwindcss').Config} */

const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: ['./web/index.html', './web/src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: defaultTheme.colors.sky,
        secondary: defaultTheme.colors.purple,
        background: defaultTheme.colors.zinc,
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
