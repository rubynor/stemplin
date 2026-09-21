// For importing tailwind styles from phlex_ui/phlex_ui_pro gem

const defaultTheme = require("tailwindcss/defaultTheme");
module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,haml,html,slim,rb}',
    './app/views/components/**/*.{erb,haml,html,slim,rb}'
  ],
  extend: {
    screens: {
      print: { raw: "print" },
    },
  },
  safelist: [
      ...[...Array(100)].flatMap((item, index) => [`pl-[${index +1}px]`]),
    {
      pattern: /bg-slate-([0-9]+)/,
    }
  ],
  theme: {
    extend: {
      colors: {
        tastyWhite: "#F4EDE3",
        tastyWhiteLite: "#F9F6F1",
        cream: "#F0E7DB",
        seaGreen: "#319895",
        seaGreenDark: "#285E61",
        seaGreenDarker: "#193c3e",
        dangerRed: "#ff0000",
      //   phlex ui colors
        border: "rgb(var(--border) / <alpha-value>)",
        canvas: "rgb(var(--canvas) / <alpha-value>)",
        "surface-muted": "rgb(var(--surface-muted) / <alpha-value>)",
        input: "rgb(var(--input) / <alpha-value>)",
        ring: "rgb(var(--ring) / <alpha-value>)",
        background: "rgb(var(--background) / <alpha-value>)",
        foreground: "rgb(var(--foreground) / <alpha-value>)",
        primary: {
          DEFAULT: "rgb(var(--primary) / <alpha-value>)",
          foreground: "rgb(var(--primary-foreground) / <alpha-value>)",
          50: "rgb(var(--primary-50) / <alpha-value>)",
          100: "rgb(var(--primary-100) / <alpha-value>)",
          200: "rgb(var(--primary-200) / <alpha-value>)",
          300: "rgb(var(--primary-300) / <alpha-value>)",
          400: "rgb(var(--primary-400) / <alpha-value>)",
          500: "rgb(var(--primary-500) / <alpha-value>)",
          600: "rgb(var(--primary-600) / <alpha-value>)",
          700: "rgb(var(--primary-700) / <alpha-value>)",
          800: "rgb(var(--primary-800) / <alpha-value>)",
          900: "rgb(var(--primary-900) / <alpha-value>)",
        },
        secondary: {
          DEFAULT: "rgb(var(--secondary) / <alpha-value>)",
          foreground: "rgb(var(--secondary-foreground) / <alpha-value>)",
        },
        destructive: {
          DEFAULT: "rgb(var(--destructive) / <alpha-value>)",
          foreground: "rgb(var(--destructive-foreground) / <alpha-value>)",
        },
        warning: {
          DEFAULT: "rgb(var(--warning) / <alpha-value>)",
          foreground: "rgb(var(--warning-foreground) / <alpha-value>)",
        },
        success: {
          DEFAULT: "rgb(var(--success) / <alpha-value>)",
          foreground: "rgb(var(--success-foreground) / <alpha-value>)",
        },
        muted: {
          DEFAULT: "rgb(var(--muted) / <alpha-value>)",
          foreground: "rgb(var(--muted-foreground) / <alpha-value>)",
        },
        accent: {
          DEFAULT: "rgb(var(--accent) / <alpha-value>)",
          foreground: "rgb(var(--accent-foreground) / <alpha-value>)",
        },
        "brown": "rgb(var(--brown) / <alpha-value>)",
        "brand": "rgb(var(--brand) / <alpha-value>)",
        "primary-text": "rgb(var(--primary-text) / <alpha-value>)",
        "secondary-text": "rgb(var(--secondary-text) / <alpha-value>)",
      },
      fontFamily: {
        sans: ["Inter", ...defaultTheme.fontFamily.sans],
        montserrat: ["Inter", ...defaultTheme.fontFamily.sans],
      },
      borderRadius: {
        xl: `calc(var(--radius) + 6px)`,
        lg: `var(--radius)`,
        md: `calc(var(--radius) - 2px)`,
        sm: "calc(var(--radius) - 4px)",
      },
      boxShadow: {
        xs: "0 1px 2px rgba(16, 17, 26, 0.05)",
        sm: "0 1px 2px rgba(16, 17, 26, 0.06)",
        card: "0 1px 3px rgba(16, 17, 26, 0.06), 0 8px 24px -12px rgba(16, 17, 26, 0.14)",
        pop: "0 2px 4px rgba(16, 17, 26, 0.06), 0 12px 32px -8px rgba(16, 17, 26, 0.18)",
      },
      minWidth: {
        6: "6em",
        custom60: "60rem",
        custom50: "50rem",
        custom45: "45rem",
        custom35: "35rem",
        custom25: "25rem",
        custom24: "24rem",
      },
      width: {
        custom20: "20rem",
        custom15: "15rem",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    function ({ addUtilities }) {
      const newUtilities = {
        ".border-2-black": {
          "border-width": "2px",
          "border-color": "#000",
        },
        ".seaGreen-text-white": {
        backgroundColor: "#319895",
        color: "#fff",
        },
        ".bg-opacity\\/10": { "--tw-bg-opacity": "0.1" },
        ".bg-opacity\\/20": { "--tw-bg-opacity": "0.2" },
        ".bg-opacity\\/30": { "--tw-bg-opacity": "0.3" },
        ".bg-opacity\\/40": { "--tw-bg-opacity": "0.4" },
        ".bg-opacity\\/50": { "--tw-bg-opacity": "0.5" },
        ".bg-opacity\\/60": { "--tw-bg-opacity": "0.6" },
        ".bg-opacity\\/70": { "--tw-bg-opacity": "0.7" },
        ".bg-opacity\\/80": { "--tw-bg-opacity": "0.8" },
        ".bg-opacity\\/90": { "--tw-bg-opacity": "0.9" },
        ".bg-opacity\\/100": { "--tw-bg-opacity": "1" },
      };
      addUtilities(newUtilities, ["responsive", "hover"]);
    },
  ],
}
