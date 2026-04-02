import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: 'de-DE',
  title: "HAML Docs",
  description: "Hardware-Accelerated Machine Learning",

  base: '/haml/',

  lastUpdated: true,
  cleanUrls: true,

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Startseite', link: '/' },
      { text: 'About', link: '/about' },
    ],

    sidebar: [

    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/IP-TeamC/haml' }
    ],

    footer: {
      message: 'Veröffentlicht unter der ISC Lizenz.',
      copyright: 'Copyright © 2026 Marcel Anker, Lennart Heinrich, Piet Ostendorp'
    },

    lastUpdated: {
      text: 'Letzte Änderung'
    },

    docFooter: {
      prev: 'Vorherige Seite',
      next: 'Nächste Seite'
    },

    editLink: {
      pattern: 'https://github.com/IP-TeamC/haml/edit/main/docs/:path',
      text: 'Diese Seite auf GitHub bearbeiten'
    },

    lightModeSwitchTitle: 'Wechsel zu hellem Modus',
    darkModeSwitchTitle: 'Wechsel zu dunklem Modus',
    sidebarMenuLabel: 'Menü',
    returnToTopLabel: 'Nach oben',
    langMenuLabel : 'Sprachauswahl',
    skipToContentLabel: 'Zum Inhalt springen',

    outline: { level: [2, 3], label: 'Auf dieser Seite' }
  }
})