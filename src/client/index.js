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

  // Find all autodoc-inline tokens
  const autodocInlines = document.querySelectorAll('.token.autodoc-inline');

  autodocInlines.forEach((inline) => {
    // Check if dark mode is active
    const isDarkMode = document.documentElement.getAttribute('data-theme') === 'dark';

    // Override inline styles using setProperty with 'important' flag
    inline.style.setProperty('color', isDarkMode ? '#79c0ff' : '#0550ae', 'important');
    inline.style.setProperty('font-weight', '600', 'important');
    inline.style.setProperty('font-style', 'normal', 'important');
  });
}

// Run immediately for initial page load
if (typeof document !== 'undefined') {
  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      fixAutodocHighlighting();
      initSearchModal();
    });
  } else {
    // Small delay to ensure Prism has finished tokenizing
    setTimeout(fixAutodocHighlighting, 100);
    // Initialize search modal
    setTimeout(initSearchModal, 200);
  }

  // Also run after a short delay to catch dynamically rendered content
  setTimeout(fixAutodocHighlighting, 500);
}

/**
 * Search Modal Implementation
 *
 * Features:
 * 1. Opens on click or Ctrl+K (not hover)
 * 2. Close button (X) inside the input
 * 3. Closes on backdrop click
 * 4. Closes on Escape key
 * 5. Closes on click outside suggestions
 * 6. Autofocuses input when opened
 */
function initSearchModal() {
  let handlersSetup = false;
  let containerObserver = null;
  let dropdownObserver = null;

  // Track intentional vs accidental interactions
  let mouseDownOnSearch = false;
  let lastExternalInteraction = Date.now();
  const GRACE_PERIOD = 300; // ms

  // Close button element reference
  let closeBtn = null;

  // Check if element is within search container
  function isSearchElement(element) {
    if (!element) return false;
    const searchContainer = element.closest('.navbar__search, .searchBar_RVTs');
    return searchContainer !== null;
  }

  // Check if we're in the grace period after an external click
  function inGracePeriod() {
    return Date.now() - lastExternalInteraction < GRACE_PERIOD;
  }

  // Check if dropdown is open
  function isDropdownOpen() {
    const dropdown = document.querySelector('.dropdownMenu_qbY6');
    return dropdown && dropdown.style.display !== 'none';
  }

  // Close the search modal
  function closeModal() {
    const searchInput = document.querySelector('.navbar__search-input');
    searchInput?.blur();
  }

  // Inject close button into the search input container
  function injectCloseButton() {
    // Check if button already exists
    if (document.querySelector('.search-modal-close-btn')) {
      return true;
    }

    const searchContainer = document.querySelector('.searchBar_RVTs');
    if (!searchContainer) return false;

    // Make sure container has position relative for absolute positioning
    const currentPos = window.getComputedStyle(searchContainer).position;
    if (currentPos !== 'relative' && currentPos !== 'absolute') {
      searchContainer.style.position = 'relative';
    }

    // Create close button
    closeBtn = document.createElement('button');
    closeBtn.className = 'search-modal-close-btn';
    closeBtn.innerHTML = '×';
    closeBtn.setAttribute('aria-label', 'Close search');
    closeBtn.setAttribute('type', 'button');
    closeBtn.style.cssText = `
      display: none;
      position: absolute;
      top: 50%;
      right: 8px;
      transform: translateY(-50%);
      width: 32px;
      height: 32px;
      margin: 0;
      background: var(--ifm-color-emphasis-100);
      border: none;
      border-radius: 8px;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      color: var(--ifm-color-emphasis-700);
      font-size: 20px;
      line-height: 1;
      z-index: 1002;
      transition: all 0.2s ease;
      padding: 0;
    `;

    // Click handler
    closeBtn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      closeModal();
    });

    // Append to search container
    searchContainer.appendChild(closeBtn);
    return true;
  }

  // Show/hide close button based on modal state
  function updateCloseButtonVisibility() {
    // Try to inject if not exists
    if (!closeBtn) {
      if (!injectCloseButton()) return;
    }

    if (isDropdownOpen()) {
      closeBtn.style.display = 'flex';
    } else {
      closeBtn.style.display = 'none';
    }
  }

  // Autofocus search input with double RAF for timing
  function autofocusInput() {
    const searchInput = document.querySelector('.navbar__search-input');
    if (!searchInput) return;

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        searchInput.focus();
      });
    });
  }

  // Monitor dropdown visibility for close button and autofocus
  function observeDropdown() {
    if (dropdownObserver) return;

    const dropdown = document.querySelector('.dropdownMenu_qbY6');
    if (!dropdown) return;

    // Use MutationObserver to detect style changes
    dropdownObserver = new MutationObserver(() => {
      updateCloseButtonVisibility();

      // Autofocus when modal opens
      if (isDropdownOpen()) {
        autofocusInput();
      }
    });

    dropdownObserver.observe(dropdown, {
      attributes: true,
      attributeFilter: ['style', 'class']
    });
  }

  // Wait for search container to be created by the plugin
  function waitForSearchContainer() {
    if (containerObserver) return;

    containerObserver = new MutationObserver((mutations) => {
      // Check if search container was added
      if (document.querySelector('.searchBar_RVTs')) {
        // Container exists, inject close button
        injectCloseButton();
        observeDropdown();
      }
    });

    // Observe the navbar for changes
    const navbar = document.querySelector('.navbar__search');
    if (navbar) {
      containerObserver.observe(navbar, {
        childList: true,
        subtree: true
      });
    }
  }

  // Function to set up event handlers
  function setupHandlers() {
    if (handlersSetup) return;
    handlersSetup = true;

    // Try to inject close button immediately
    injectCloseButton();

    // Start observing for search container creation
    waitForSearchContainer();

    // Start observing dropdown for visibility changes
    observeDropdown();

    // Track mousedown to detect intentional search interactions
    document.addEventListener('mousedown', (e) => {
      if (isSearchElement(e.target)) {
        // User intentionally clicked on search
        mouseDownOnSearch = true;
        setTimeout(() => { mouseDownOnSearch = false; }, 50);
      } else {
        // User clicked elsewhere - start grace period
        lastExternalInteraction = Date.now();
        mouseDownOnSearch = false;
      }
    }, { capture: true, passive: true });

    // Prevent focus-based opening when in grace period (accidental hover)
    document.addEventListener('focusin', (e) => {
      const searchInput = document.querySelector('.navbar__search-input');
      if (e.target === searchInput && inGracePeriod() && !mouseDownOnSearch) {
        // This focus is accidental - prevent modal from opening
        e.stopImmediatePropagation();
        e.preventDefault();
        searchInput.blur();
      }
    }, { capture: true });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        if (isDropdownOpen()) {
          e.preventDefault();
          e.stopPropagation();
          closeModal();
        }
      }
    }, { capture: true });

    // Close on backdrop click (click outside search container)
    document.addEventListener('click', (e) => {
      const searchContainer = document.querySelector('.navbar__search, .searchBar_RVTs');

      if (isDropdownOpen() && !searchContainer?.contains(e.target)) {
        closeModal();
      }
    }, { capture: true });

    // Handle Ctrl+K shortcut
    document.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        const searchInput = document.querySelector('.navbar__search-input');
        if (searchInput) {
          searchInput.focus();
        }
      }
    }, { capture: true });

    // Handle click on search input to open modal
    document.addEventListener('click', (e) => {
      const searchInput = document.querySelector('.navbar__search-input');
      if (e.target === searchInput && !isDropdownOpen()) {
        // Input was clicked - let plugin handle opening
        // The observer will handle autofocus after dropdown opens
      }
    }, { capture: true });
  }

  // Set up handlers immediately
  setupHandlers();

  // Re-run setup after a delay in case DOM isn't ready
  setTimeout(setupHandlers, 500);
}
