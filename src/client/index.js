/**
 * Client entry point for pike-cookbook
 * Executes client-side code after page load
 */

export function onRouteDidUpdate() {
  // Fix autodoc-tag colors after page navigation
  fixAutodocHighlighting();
}

export function onRouteUpdate() {
  // Fix autodoc-tag colors on initial load
  fixAutodocHighlighting();
}

function fixAutodocHighlighting() {
  // Find all autodoc-tag tokens
  const autodocTags = document.querySelectorAll('.token.autodoc-tag');

  autodocTags.forEach((tag) => {
    // Check if dark mode is active
    const isDarkMode = document.documentElement.getAttribute('data-theme') === 'dark';

    // Override inline styles using setProperty with 'important' flag
    tag.style.setProperty('color', isDarkMode ? '#d2a8ff' : '#8250df', 'important');
    tag.style.setProperty('font-weight', '700', 'important');
    tag.style.setProperty('font-style', 'normal', 'important');
  });
}

// Run immediately for initial page load
if (typeof document !== 'undefined') {
  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', fixAutodocHighlighting);
  } else {
    // Small delay to ensure Prism has finished tokenizing
    setTimeout(fixAutodocHighlighting, 100);
  }

  // Also run after a short delay to catch dynamically rendered content
  setTimeout(fixAutodocHighlighting, 500);
}
