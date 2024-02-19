const defaultTheme = require("tailwindcss/defaultTheme");
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
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
      };
      addUtilities(newUtilities, ["responsive", "hover"]);
    },
  ],
}
