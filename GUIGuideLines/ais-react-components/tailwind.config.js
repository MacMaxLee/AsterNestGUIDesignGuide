/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // AIS Semantic Action Colors
        'ais-primary': 'var(--ais-action-primary)',
        'ais-confirm': 'var(--ais-action-confirm)',
        'ais-destructive': 'var(--ais-action-destructive)',
        'ais-caution': 'var(--ais-action-caution)',
        'ais-neutral': 'var(--ais-action-neutral)',
        'ais-secondary': 'var(--ais-action-secondary)',

        // AIS Semantic State Colors
        'ais-info': 'var(--ais-state-info)',
        'ais-warning': 'var(--ais-state-warning)',
        'ais-error': 'var(--ais-state-error)',
        'ais-unavailable': 'var(--ais-state-unavailable)',

        // AIS Surface Colors
        'ais-surface': 'var(--ais-surface)',
        'ais-surface-secondary': 'var(--ais-surface-secondary)',
        'ais-on-surface': 'var(--ais-on-surface)',
        'ais-on-surface-secondary': 'var(--ais-on-surface-secondary)',
      },
      spacing: {
        'ais-xs': 'var(--ais-spacing-xs)',
        'ais-sm': 'var(--ais-spacing-sm)',
        'ais-md': 'var(--ais-spacing-md)',
        'ais-lg': 'var(--ais-spacing-lg)',
        'ais-xl': 'var(--ais-spacing-xl)',
        'ais-xxl': 'var(--ais-spacing-xxl)',
      },
      borderRadius: {
        'ais-sm': 'var(--ais-radius-sm)',
        'ais-md': 'var(--ais-radius-md)',
        'ais-lg': 'var(--ais-radius-lg)',
        'ais-xl': 'var(--ais-radius-xl)',
        'ais-full': 'var(--ais-radius-full)',
      },
    },
  },
  plugins: [],
}
