/**
 * Client entry point for pike-cookbook
 * Executes client-side code after page load
 */

export function onRouteDidUpdate() {
  // Fix autodoc-tag colors after page navigation
  fixAutodocHighlighting();
  highlightInlineAutodocTags();
}

export function onRouteUpdate() {
  // Fix autodoc-tag colors on initial load
  fixAutodocHighlighting();
  highlightInlineAutodocTags();
}

function escapeHTML(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function fixAutodocHighlighting() {
  const isDarkMode = document.documentElement.getAttribute('data-theme') === 'dark';

  // Colors for autodoc tags
  const tagColor = isDarkMode ? '#d2a8ff' : '#8250df';
  const inlineColor = isDarkMode ? '#79c0ff' : '#0550ae';

  // Regex patterns from prism-include-languages.js
  const tagPattern = /@(?:param|return|returns|throws|throw|seealso|example|note|deprecated|bugs|decl|class|endclass|module|endmodule|type|member|item|index|dl|enddl|mapping|endmapping|array|endarray|namespace|endnamespace|enum|endenum|constant|variable|inherit|typedef|directive|fixme|todo|ol|endol|ul|endul|li|table|endtable|row|col|image|url|expr|code)\b/g;
  const inlinePattern = /@(?:i|b|tt|ref|xml)\{[^@]*@/g;

  // Case 1: Dev mode - existing .token.autodoc-tag elements
  const autodocTags = document.querySelectorAll('.token.autodoc-tag');
  autodocTags.forEach((tag) => {
    tag.style.setProperty('color', tagColor, 'important');
    tag.style.setProperty('font-weight', '700', 'important');
    tag.style.setProperty('font-style', 'normal', 'important');
  });

  const autodocInlines = document.querySelectorAll('.token.autodoc-inline');
  autodocInlines.forEach((inline) => {
    inline.style.setProperty('color', inlineColor, 'important');
    inline.style.setProperty('font-weight', '600', 'important');
    inline.style.setProperty('font-style', 'normal', 'important');
  });

  // Case 2: Production mode - parse .token.comment elements
  // Only process if no autodoc-tag elements exist
  if (autodocTags.length === 0) {
    const comments = document.querySelectorAll('.token.comment');

    comments.forEach((comment) => {
      // TWO-PASS: Update colors for already-processed elements
      if (comment.getAttribute('data-autodoc-processed') === 'true') {
        // Update existing styled spans with current theme colors
        const styledSpans = comment.querySelectorAll('span[style*="color:"]');
        styledSpans.forEach((span) => {
          const currentStyle = span.getAttribute('style');
          // Check if this is a tag span (font-weight: 700) or inline span (font-weight: 600)
          if (currentStyle.includes('font-weight: 700')) {
            span.style.setProperty('color', tagColor, 'important');
          } else if (currentStyle.includes('font-weight: 600')) {
            span.style.setProperty('color', inlineColor, 'important');
          }
        });
        return;
      }

      // Check if comment has autodoc-tag or autodoc-inline children
      if (comment.querySelector('.token.autodoc-tag, .token.autodoc-inline')) return;

      // Get text content
      const text = comment.textContent;
      if (!text) return;

      // Check if text contains any autodoc patterns
      const hasTag = tagPattern.test(text);
      const hasInline = inlinePattern.test(text);

      if (!hasTag && !hasInline) return;

      // Reset regex lastIndex
      tagPattern.lastIndex = 0;
      inlinePattern.lastIndex = 0;

      // Escape HTML entities to prevent injection
      let escapedText = escapeHTML(text);

      // Build new HTML with wrapped tags
      let newHTML = escapedText;

      // Replace autodoc tags
      newHTML = newHTML.replace(tagPattern, (match) => {
        return `<span style="color: ${tagColor} !important; font-weight: 700 !important; font-style: normal !important;">${match}</span>`;
      });

      // Replace autodoc inline
      newHTML = newHTML.replace(inlinePattern, (match) => {
        return `<span style="color: ${inlineColor} !important; font-weight: 600 !important; font-style: normal !important;">${match}</span>`;
      });

      // Only update if we actually made changes
      if (newHTML !== escapedText) {
        comment.innerHTML = newHTML;
        comment.setAttribute('data-autodoc-processed', 'true');
      }
    });
  }
}

function highlightInlineAutodocTags() {
  const isDarkMode = document.documentElement.getAttribute('data-theme') === 'dark';
  const tagColor = isDarkMode ? '#d2a8ff' : '#8250df';

  // Pattern for autodoc tags
  const tagPattern = /@(?:param|return|returns|throws|throw|seealso|example|note|deprecated|bugs|decl|class|endclass|module|endmodule|type|member|item|index|dl|enddl|mapping|endmapping|array|endarray|namespace|endnamespace|enum|endenum|constant|variable|inherit|typedef|directive|fixme|todo|ol|endol|ul|endul|li|table|endtable|row|col|image|url|expr|code)\b/g;

  // Find all inline code elements (not inside pre)
  const inlineCodes = document.querySelectorAll('code:not(pre code)');

  inlineCodes.forEach((code) => {
    // TWO-PASS: Update colors for already-processed elements
    if (code.getAttribute('data-autodoc-processed') === 'true') {
      // Update existing styled spans with current theme colors
      const styledSpans = code.querySelectorAll('span[style*="color:"]');
      styledSpans.forEach((span) => {
        span.style.setProperty('color', tagColor, 'important');
      });
      return;
    }

    const text = code.textContent;
    if (!text) return;

    // Check if contains autodoc tags
    if (!tagPattern.test(text)) return;

    // Reset regex
    tagPattern.lastIndex = 0;

    // Escape HTML entities to prevent injection
    const escapedText = escapeHTML(text);

    // Replace tags with styled spans
    const newHTML = escapedText.replace(tagPattern, (match) => {
      return `<span style="color: ${tagColor} !important; font-weight: 700 !important; font-style: normal !important;">${match}</span>`;
    });

    if (newHTML !== escapedText) {
      code.innerHTML = newHTML;
      code.setAttribute('data-autodoc-processed', 'true');
    }
  });
}

// Run immediately for initial page load
if (typeof document !== 'undefined') {
  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      fixAutodocHighlighting();
      highlightInlineAutodocTags();
      initSearchModal();
    });
  } else {
    // Small delay to ensure Prism has finished tokenizing
    setTimeout(() => {
      fixAutodocHighlighting();
      highlightInlineAutodocTags();
    }, 100);
    // Initialize search modal
    setTimeout(initSearchModal, 200);
  }

  // Also run after a short delay to catch dynamically rendered content
  setTimeout(() => {
    fixAutodocHighlighting();
    highlightInlineAutodocTags();
  }, 500);

  // Watch for theme changes and reapply autodoc highlighting
  const themeObserver = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.attributeName === 'data-theme') {
        fixAutodocHighlighting();
        highlightInlineAutodocTags();
      }
    });
  });

  themeObserver.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['data-theme']
  });
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
