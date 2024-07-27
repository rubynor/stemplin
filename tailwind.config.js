// For importing tailwind styles from phlex_ui/phlex_ui_pro gem
const execSync = require('child_process').execSync;

// Import phlex_ui gem path (To make sure Tailwind loads classes used by phlex_ui gem)
const outputPhlexUI = execSync('bundle show phlex_ui', { encoding: 'utf-8' });
const phlexUIPath = outputPhlexUI.trim() + '/**/*.rb';

const defaultTheme = require("tailwindcss/defaultTheme");
module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,haml,html,slim,rb}',
    './app/views/components/**/*.{erb,haml,html,slim,rb}',
    phlexUIPath
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
        border: "var(--border)",
        input: "var(--input)",
        ring: "var(--ring)",
        background: "var(--background)",
        foreground: "var(--foreground)",
        primary: {
          DEFAULT: "var(--primary)",
          foreground: "var(--primary-foreground)",
        },
        secondary: {
          DEFAULT: "var(--secondary)",
          foreground: "var(--secondary-foreground)",
        },
        destructive: {
          DEFAULT: "var(--destructive)",
          foreground: "var(--destructive-foreground)",
        },
        warning: {
          DEFAULT: "var(--warning)",
          foreground: "var(--warning-foreground)",
        },
        success: {
          DEFAULT: "var(--success)",
          foreground: "var(--success-foreground)",
        },
        muted: {
          DEFAULT: "var(--muted)",
          foreground: "var(--muted-foreground)",
        },
        accent: {
          DEFAULT: "var(--accent)",
          foreground: "var(--accent-foreground)",
        },
        "new-primary": "var(--new-primary)",
        "new-secondary": "var(--new-secondary)",
        "new-primary-text": "var(--new-primary-text)",
        "new-secondary-text": "var(--new-secondary-text)",
      },
      fontFamily: {
        montserrat: ["Montserrat", ...defaultTheme.fontFamily.sans],
      },
      borderRadius: {
        lg: `var(--radius)`,
        md: `calc(var(--radius) - 2px)`,
        sm: "calc(var(--radius) - 4px)",
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
      };
      addUtilities(newUtilities, ["responsive", "hover"]);
    },
  ],
}
