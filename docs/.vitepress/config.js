import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'react-native-shield',
  description:
    'All-in-one security suite for React Native — root detection, jailbreak detection, SSL pinning, biometric authentication, secure storage, and Play Integrity attestation.',
  base: '/react-native-shield/',

  head: [
    [
      'meta',
      {
        name: 'og:title',
        content: 'react-native-shield — React Native Security Suite',
      },
    ],
    [
      'meta',
      {
        name: 'og:description',
        content:
          'Root detection, SSL pinning, biometrics, secure storage, and Play Integrity attestation for iOS and Android.',
      },
    ],
    ['meta', { name: 'og:type', content: 'website' }],
  ],

  themeConfig: {
    siteTitle: 'react-native-shield',

    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'API', link: '/api/device-integrity' },
      { text: 'Roadmap', link: '/roadmap' },
      {
        text: 'GitHub',
        link: 'https://github.com/ThinkGrid-Labs/react-native-shield',
      },
      {
        text: 'npm',
        link: 'https://www.npmjs.com/package/@think-grid-labs/react-native-shield',
      },
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting Started', link: '/guide/getting-started' },
          {
            text: 'Device Integrity & Anti-Tampering',
            link: '/guide/device-integrity',
          },
          { text: 'Platform Attestation', link: '/guide/attestation' },
          { text: 'SSL Pinning', link: '/guide/ssl-pinning' },
          { text: 'Biometric Authentication', link: '/guide/biometrics' },
          { text: 'Secure Storage', link: '/guide/secure-storage' },
          { text: 'UI Privacy', link: '/guide/ui-privacy' },
          { text: 'App Environment', link: '/guide/app-environment' },
        ],
      },
      {
        text: 'API Reference',
        items: [
          { text: 'Device Integrity', link: '/api/device-integrity' },
          { text: 'Network & Environment', link: '/api/network' },
          { text: 'Platform Attestation', link: '/api/attestation' },
          { text: 'Biometrics', link: '/api/biometrics' },
          { text: 'SSL Pinning', link: '/api/ssl-pinning' },
          { text: 'Secure Storage', link: '/api/secure-storage' },
          { text: 'UI Privacy', link: '/api/ui-privacy' },
        ],
      },
      {
        text: 'More',
        items: [
          { text: 'Roadmap', link: '/roadmap' },
          { text: 'Contributing', link: '/contributing' },
        ],
      },
    ],

    socialLinks: [
      {
        icon: 'github',
        link: 'https://github.com/ThinkGrid-Labs/react-native-shield',
      },
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © ThinkGrid Labs',
    },

    search: {
      provider: 'local',
    },

    editLink: {
      pattern:
        'https://github.com/ThinkGrid-Labs/react-native-shield/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },
  },
});
