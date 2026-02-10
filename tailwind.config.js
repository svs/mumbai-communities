module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      fontFamily: {
        'sans': ['Inter', '-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'Roboto', 'sans-serif'],
        'display': ['Barlow', 'Inter', '-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'Roboto', 'sans-serif'],
      },
    },
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        mcgm: {
          "primary": "#3b82f6",        // blue-500
          "primary-content": "#ffffff",
          "secondary": "#6b7280",      // gray-500
          "secondary-content": "#ffffff",
          "accent": "#22c55e",         // green-500
          "accent-content": "#ffffff",
          "neutral": "#374151",        // gray-700
          "neutral-content": "#ffffff",
          "base-100": "#ffffff",       // white
          "base-200": "#f9fafb",       // gray-50
          "base-300": "#f3f4f6",       // gray-100
          "base-content": "#111827",   // gray-900
          "info": "#0ea5e9",           // sky-500
          "info-content": "#ffffff",
          "success": "#22c55e",        // green-500
          "success-content": "#ffffff",
          "warning": "#eab308",        // yellow-500
          "warning-content": "#000000",
          "error": "#dc2626",          // red-600
          "error-content": "#ffffff",

          // Custom additions for Mumbai theme
          "--rounded-box": "0.5rem",
          "--rounded-btn": "0.375rem",
          "--rounded-badge": "9999px",
          "--animation-btn": "0.25s",
          "--animation-input": "0.2s",
          "--btn-text-case": "uppercase",
          "--navbar-padding": "0.5rem",
          "--border-btn": "1px",
        }
      }
    ],
    base: true,
    styled: true,
    utils: true,
    prefix: "",
    logs: true,
    themeRoot: ":root",
  }
}