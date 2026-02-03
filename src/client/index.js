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
  // Function to inject close button and wrapper
  function injectCloseButton() {
    const modal = document.querySelector('.searchBar_RVTs');
    if (!modal) return;

    // Find the search input
    const searchInput = modal.querySelector('.navbar__search-input');
    if (!searchInput) return;

    // Check if wrapper already exists, if not create it
    let wrapper = modal.querySelector('.search-input-wrapper');
    if (!wrapper) {
      wrapper = document.createElement('div');
      wrapper.className = 'search-input-wrapper';

      // Insert wrapper before input, then move input into wrapper
      searchInput.parentNode.insertBefore(wrapper, searchInput);
      wrapper.appendChild(searchInput);
    }

    // Check if close button already exists in wrapper
    if (wrapper.querySelector('.search-modal-close-btn')) return;

    // Create close button
    const closeBtn = document.createElement('button');
    closeBtn.className = 'search-modal-close-btn';
    closeBtn.setAttribute('aria-label', 'Close search');
    closeBtn.innerHTML = '×';
    closeBtn.setAttribute('type', 'button');

    // Helper to close modal
    const closeModal = () => {
      searchInput.blur();
      searchInput.value = '';
      searchInput.setAttribute('aria-expanded', 'false');
      modal.style.display = 'none';

      // Small delay to allow blur to propagate
      setTimeout(() => {
        const body = document.querySelector('body');
        if (body) body.classList.remove('search-modal-open');
      }, 10);
    };

    // Add click handler to close button
    closeBtn.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      closeModal();
    });

    // Close on backdrop click
    modal.addEventListener('click', function(e) {
      // Only close if the click was exactly on the modal backdrop, not its children
      if (e.target === modal) {
        closeModal();
      }
    });

    // Close on Escape key
    const handleEsc = (e) => {
      if (e.key === 'Escape' && modal.style.display !== 'none') {
        closeModal();
      }
    };
    document.addEventListener('keydown', handleEsc);

    // Append button to wrapper so it's positioned relative to the input
    wrapper.appendChild(closeBtn);
  }

  // Function to observe search modal opening
  function observeSearchModal() {
    // Initial check
    const modal = document.querySelector('.searchBar_RVTs');
    if (modal && modal.style.display !== 'none') {
      injectCloseButton();
    }

    // Observe changes to the search input state
    const searchInput = document.querySelector('.navbar__search-input');
    if (searchInput) {
      const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          if (mutation.type === 'attributes' && mutation.attributeName === 'aria-expanded') {
            const isExpanded = searchInput.getAttribute('aria-expanded') === 'true';
            if (isExpanded) {
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
    }

    // Also observe the body for when the search modal is added/removed from DOM
    const bodyObserver = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.addedNodes.length) {
          const hasModal = Array.from(mutation.addedNodes).some(node =>
            node.classList && node.classList.contains('searchBar_RVTs')
          );
          if (hasModal) {
            setTimeout(injectCloseButton, 50);
          }
        }
      });
    });

    bodyObserver.observe(document.body, { childList: true, subtree: false });
  }

  observeSearchModal();
}
