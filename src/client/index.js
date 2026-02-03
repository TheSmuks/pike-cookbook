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
    document.addEventListener('DOMContentLoaded', () => {
      fixAutodocHighlighting();
      initSearchCloseButton();
    });
  } else {
    // Small delay to ensure Prism has finished tokenizing
    setTimeout(fixAutodocHighlighting, 100);
    // Initialize search close button
    setTimeout(initSearchCloseButton, 200);
  }

  // Also run after a short delay to catch dynamically rendered content
  setTimeout(fixAutodocHighlighting, 500);
}

// Search close button functionality
function initSearchCloseButton() {
  // Function to inject close button
  function injectCloseButton() {
    const modal = document.querySelector('.searchBar_RVTs');
    if (!modal) return;

    // Check if close button already exists
    if (modal.querySelector('.search-modal-close-btn')) return;

    // Create close button
    const closeBtn = document.createElement('button');
    closeBtn.className = 'search-modal-close-btn';
    closeBtn.setAttribute('aria-label', 'Close search');
    closeBtn.innerHTML = '×';
    closeBtn.setAttribute('type', 'button');

    // Add click handler to close the modal
    closeBtn.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();

      // Find the search input and blur it to close the dropdown
      const searchInput = document.querySelector('.navbar__search-input');
      if (searchInput) {
        searchInput.blur();
        searchInput.value = '';
        searchInput.setAttribute('aria-expanded', 'false');
      }

      // Hide the modal
      modal.style.display = 'none';
    });

    // Append button to modal
    modal.appendChild(closeBtn);
  }

  // Function to observe search modal opening
  function observeSearchModal() {
    const searchInput = document.querySelector('.navbar__search-input');
    if (!searchInput) return;

    // Use MutationObserver to watch for modal opening
    const observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.type === 'attributes' && mutation.attributeName === 'aria-expanded') {
          const isExpanded = searchInput.getAttribute('aria-expanded') === 'true';
          if (isExpanded) {
            // Show modal if it's hidden
            const modal = document.querySelector('.searchBar_RVTs');
            if (modal) {
              modal.style.display = '';
              setTimeout(injectCloseButton, 50);
            }
          }
        }
      });
    });

    observer.observe(searchInput, { attributes: true });

    // Also observe modal being added to DOM
    const modalObserver = new MutationObserver(function() {
      const modal = document.querySelector('.searchBar_RVTs');
      if (modal && modal.style.display !== 'none') {
        setTimeout(injectCloseButton, 50);
      }
    });

    modalObserver.observe(document.body, { childList: true, subtree: true });
  }

  observeSearchModal();
}
