// For importing tailwind styles from phlex_ui/phlex_ui_pro gem
const execSync = require('child_process').execSync;

// Import phlex_ui gem path (To make sure Tailwind loads classes used by phlex_ui gem)
const outputPhlexUI = execSync('bundle show phlex_ui', { encoding: 'utf-8' });
const phlex_ui_path = outputPhlexUI.trim() + '/**/*.rb';

const defaultTheme = require("tailwindcss/defaultTheme");
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,haml,html,slim,rb}',
    phlex_ui_path
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
      },
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
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
