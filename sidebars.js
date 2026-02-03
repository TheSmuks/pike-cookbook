module.exports = {
  tutorialSidebar: [
    {
      type: 'doc',
      id: 'intro',
      label: 'Introduction',
    },
    {
      type: 'category',
      label: 'Documentation',
      collapsible: true,
      collapsed: false,
      items: [
        'autodoc-format',
      ],
    },
    {
      type: 'category',
      label: 'Basic Recipes',
      collapsible: true,
      collapsed: false,
      items: [
        'basics/strings',
        'basics/numbers',
        'basics/arrays',
        'basics/hashes',
        'basics/dates',
        'basics/pattern-matching',
        'basics/subroutines',
      ],
    },
    {
      type: 'category',
      label: 'File Operations',
      collapsible: true,
      collapsed: false,
      items: [
        'files/file-access',
        'files/file-contents',
        'files/directories',
        'files/database-access',
      ],
    },
    {
      type: 'category',
      label: 'Network & Web',
      collapsible: true,
      collapsed: false,
      items: [
        'network/cgi-programming',
        'network/sockets',
        'network/web-automation',
        'network/internet-services',
      ],
    },
    {
      type: 'category',
      label: 'Advanced Topics',
      collapsible: true,
      collapsed: false,
      items: [
        'advanced/classes',
        'advanced/references',
        'advanced/modules',
        'advanced/processes',
        'advanced/user-interfaces',
      ],
    },
  ],
};
