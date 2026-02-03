// @ts-check
/** @type {import('@docusaurus/types').Config} */

const config = {
  title: 'Pike Cookbook',
  onBrokenLinks: 'ignore',
  tagline: 'Complete Pike 8.0 Cookbook',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://TheSmuks.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  baseUrl: '/pike-cookbook/',

  // GitHub Pages deployment configuration
  organizationName: 'TheSmuks',
  projectName: 'pike-cookbook',
  deploymentBranch: 'gh-pages',

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/TheSmuks/pike-cookbook/tree/main/',
          sidebarCollapsible: false,
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/docusaurus-social-card.jpg',
      navbar: {
        title: 'Pike Cookbook',
        logo: {
          alt: 'Pike Logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Cookbook',
          },
          {
            href: 'https://github.com/TheSmuks/pike-cookbook',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Cookbook',
                to: '/docs/intro',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/TheSmuks/pike-cookbook',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'Pike Homepage',
                href: 'https://pike.lysator.liu.se/',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Built with Docusaurus.`,
      },
      prism: {
        additionalLanguages: ['bash', 'css', 'javascript', 'typescript'],
        defaultLanguage: 'javascript',
      },
    }),
};

export default config;
