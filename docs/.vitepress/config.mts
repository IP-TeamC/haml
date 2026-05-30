import { defineConfig, type DefaultTheme } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: "de-DE",
  title: "HAML Docs",
  description: "Hardware-Accelerated Machine Learning",

  head: [["link", { rel: "icon", href: "favicon.ico" }]],

  base: "/haml/",

  lastUpdated: true,
  cleanUrls: true,

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Startseite", link: "/" },
      { text: "Team C", link: "/about" },
    ],

    sidebar: {
      "/": { base: "/", items: sidebar() },
    },

    socialLinks: [{ icon: "github", link: "https://github.com/IP-TeamC/haml" }],

    footer: {
      message: "Veröffentlicht unter der ISC Lizenz.",
      copyright:
        "Copyright © 2026 Marcel Anker, Lennart Heinrich, Piet Ostendorp",
    },

    lastUpdated: {
      text: "Letzte Änderung",
    },

    docFooter: {
      prev: "Vorherige Seite",
      next: "Nächste Seite",
    },

    editLink: {
      pattern: "https://github.com/IP-TeamC/haml/edit/main/docs/:path",
      text: "Diese Seite auf GitHub bearbeiten",
    },

    lightModeSwitchTitle: "Wechsel zu hellem Modus",
    darkModeSwitchTitle: "Wechsel zu dunklem Modus",
    sidebarMenuLabel: "Menü",
    returnToTopLabel: "Nach oben",
    langMenuLabel: "Sprachauswahl",
    skipToContentLabel: "Zum Inhalt springen",

    outline: { level: [2, 3], label: "Auf dieser Seite" },

    logo: { src: "/haml-icon.svg", width: 24, height: 24 },
  },
});

function sidebar(): DefaultTheme.SidebarItem[] {
  return [
    {
      text: "Einführung",
      collapsed: false,
      items: [
        { text: "Getting Started", link: "/getting-started" },
        { text: "Voraussetzungen", link: "/konzepte/basis-ideen" },
        { text: "Algorithmen-Auswahl", link: "/konzepte/auswahl" },
      ],
    },
    {
      text: "k-Nearest-Neighbors",
      collapsed: false,
      items: [
        { text: "Funktionsweise", base: "/algorithmen/knnc/", link: "/" },
        { text: "Verwendung", base: "/algorithmen/knnc/", link: "use" },
      ],
    },
    {
      text: "Lineare Regression",
      collapsed: false,
      items: [
        { text: "Funktionsweise", base: "/algorithmen/ga_linreg/", link: "/" },
        { text: "Verwendung", base: "/algorithmen/ga_linreg/", link: "use" },
      ],
    },
    {
      text: "Sudoku Solver",
      collapsed: false,
      items: [
        { text: "Funktionsweise", base: "/algorithmen/ga_sudoku/", link: "/" },
        { text: "Verwendung", base: "/algorithmen/ga_sudoku/", link: "use" },
        {
          text: "Live-Sudoku-UI",
          base: "/algorithmen/ga_sudoku/",
          link: "live-sudoku-ui",
        },
      ],
    },

    // { text: 'Config & API Reference', base: '/reference/', link: 'site-config' }
  ];
}
