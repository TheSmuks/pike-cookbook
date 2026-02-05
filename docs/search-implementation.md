# Search Implementation

The Pike Cookbook uses the `@easyops-cn/docusaurus-search-local` plugin for client-side search functionality. We have enhanced the default dropdown behavior to create a full-screen modal experience on desktop and mobile.

## Architecture

### Plugin Configuration
The plugin is configured in `docusaurus.config.js` with:
- `hashed: true`: For cache busting
- `highlightSearchTermsOnTargetPage: true`: To highlight terms when navigating
- `explicitSearchResultPath: true`: To show breadcrumbs

### Client-Side Enhancements
We use a custom client module at `src/client/index.js` to manage the modal behavior. This script:
1.  **Injects a Close Button**: Adds a visual "X" button to the search container.
2.  **Manages Focus**: Handles `Ctrl+K` to open search and `Escape` to close it.
3.  **Handles Backdrop**: Detects clicks outside the search container to close the modal.
4.  **Stabilizes Selectors**: Uses attribute selectors (e.g., `[class*="searchBar_"]`) to target plugin elements even if CSS module hashes change.

### Styling
The styling is located in `src/css/custom.css`. We use the CSS `:has()` selector to transform the standard search bar into a modal when the dropdown is open.

```css
/* Example of the modal transformation */
[class*="searchBar_"]:has([class*="dropdownMenu_"]:not([style*="display: none"])) {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  /* ... backdrop styles ... */
}
```

## Maintenance
If the search plugin updates and changes its class naming convention significantly, you may need to update the attribute selectors in `src/client/index.js` and `src/css/custom.css`.
