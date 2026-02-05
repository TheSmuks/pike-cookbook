/**
 * Client entry point for pike-cookbook
 * Executes client-side code after page load
 */

export function onRouteDidUpdate() {
  // Fix autodoc-tag colors after page navigation
  fixAutodocHighlighting();
  highlightInlineAutodocTags();
  initSearchModal();
  initScrollSpy();
  initToggleButtons();
}

export function onRouteUpdate() {
  // Fix autodoc-tag colors on initial load
  fixAutodocHighlighting();
  highlightInlineAutodocTags();
  initSearchModal();
  initScrollSpy();
  initToggleButtons();
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

/**
 * Search Modal Implementation
 * Handles modal behavior for @easyops-cn/docusaurus-search-local
 */
export function initSearchModal() {
  if (typeof document === 'undefined') return;

  let mouseDownOnSearch = false;
  let lastExternalInteraction = Date.now();
  const GRACE_PERIOD = 300;

  function isSearchElement(element) {
    if (!element) return false;
    return !!element.closest('.navbar__search, [class*="searchBar_"], [class*="dropdownMenu_"]');
  }

  function inGracePeriod() {
    return Date.now() - lastExternalInteraction < GRACE_PERIOD;
  }

  function isDropdownOpen() {
    const dropdown = document.querySelector('[class*="dropdownMenu_"]');
    return dropdown && dropdown.style.display !== 'none';
  }

  function autofocusInput() {
    const searchInput = document.querySelector('.navbar__search-input');
    if (!searchInput) return;

    // Double requestAnimationFrame ensures the element is visible and ready
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        searchInput.focus();
      });
    });
  }

  function updateCloseButtonVisibility() {
    const closeBtn = document.querySelector('.search-modal-close-btn');
    if (!closeBtn) return;

    if (isDropdownOpen()) {
      closeBtn.style.display = 'flex';
      // Ensure body scroll is locked if needed (Docusaurus usually handles this)
    } else {
      closeBtn.style.display = 'none';
    }
  }

  function injectCloseButton() {
    const searchContainer = document.querySelector('[class*="searchBar_"]');
    if (!searchContainer || searchContainer.querySelector('.search-modal-close-btn')) return;

    const closeBtn = document.createElement('button');
    closeBtn.className = 'search-modal-close-btn';
    closeBtn.innerHTML = '×';
    closeBtn.setAttribute('aria-label', 'Close search');
    closeBtn.setAttribute('type', 'button');

    closeBtn.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      const searchInput = document.querySelector('.navbar__search-input');
      if (searchInput) {
        searchInput.value = '';
        searchInput.blur();
        // Force dropdown to close by triggering an input event or similar if needed
        // but blur usually works for the plugin
      }
      const dropdown = document.querySelector('[class*="dropdownMenu_"]');
      if (dropdown) dropdown.style.display = 'none';
      updateCloseButtonVisibility();
    });

    searchContainer.appendChild(closeBtn);
  }

  // Initial setup
  injectCloseButton();

  // Track mousedown to distinguish intentional clicks from accidental focus
  document.addEventListener('mousedown', (e) => {
    if (isSearchElement(e.target)) {
      mouseDownOnSearch = true;
      // Reset after a short delay
      setTimeout(() => { mouseDownOnSearch = false; }, 50);
    } else {
      lastExternalInteraction = Date.now();
      mouseDownOnSearch = false;
    }
  }, { capture: true, passive: true });

  // Prevent opening on accidental hover/focus during grace period
  document.addEventListener('focusin', (e) => {
    const searchInput = document.querySelector('.navbar__search-input');
    if (e.target === searchInput && inGracePeriod() && !mouseDownOnSearch) {
      e.stopImmediatePropagation();
      e.preventDefault();
      searchInput.blur();
    }
  }, { capture: true });

  // Close on Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && isDropdownOpen()) {
      e.preventDefault();
      e.stopPropagation();
      const searchInput = document.querySelector('.navbar__search-input');
      if (searchInput) searchInput.blur();
      const dropdown = document.querySelector('[class*="dropdownMenu_"]');
      if (dropdown) dropdown.style.display = 'none';
      updateCloseButtonVisibility();
    }
  }, { capture: true });

  // Close on backdrop click (click outside search container)
  document.addEventListener('click', (e) => {
    if (isDropdownOpen() && !isSearchElement(e.target)) {
      const searchInput = document.querySelector('.navbar__search-input');
      if (searchInput) searchInput.blur();
      const dropdown = document.querySelector('[class*="dropdownMenu_"]');
      if (dropdown) dropdown.style.display = 'none';
      updateCloseButtonVisibility();
    }
  }, { capture: true });

  // Ctrl+K shortcut
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      const searchInput = document.querySelector('.navbar__search-input');
      if (searchInput) {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        searchInput.focus();
        // The plugin will open the dropdown on focus
      }
    }
  }, { capture: true });

  // Observe the dropdown for visibility changes
  const dropdown = document.querySelector('[class*="dropdownMenu_"]');
  if (dropdown) {
    const observer = new MutationObserver(() => {
      updateCloseButtonVisibility();
      if (isDropdownOpen()) {
        autofocusInput();
      }
    });
    observer.observe(dropdown, {
      attributes: true,
      attributeFilter: ['style']
    });
  }
}

/**
 * Scroll Spy Implementation
 * Highlights the current TOC section as user scrolls
 * Auto-scrolls TOC to show the active item
 * Only highlights ONE section at a time
 */
let scrollSpyCleanup = null;

export function initScrollSpy() {
  if (typeof document === 'undefined') return;

  // Clean up previous instance
  if (scrollSpyCleanup) {
    scrollSpyCleanup();
    scrollSpyCleanup = null;
  }

  // Find TOC container
  const tocContainer = document.querySelector('.table-of-contents, [class*="tableOfContents"]');
  if (!tocContainer) return;

  const tocLinks = tocContainer.querySelectorAll('a[href^="#"]');
  if (tocLinks.length === 0) return;

  // Get all heading sections with their level (h2, h3, h4, etc.)
  const sections = Array.from(tocLinks).map((link) => {
    const id = link.getAttribute('href').slice(1);
    const heading = document.getElementById(id);
    if (!heading) return null;

    // Determine heading level from tag name (h2=2, h3=3, etc.)
    const level = parseInt(heading.tagName.substring(1));

    return {
      id,
      element: heading,
      link,
      level,
      top: heading.offsetTop,
      bottom: heading.offsetTop + heading.offsetHeight,
    };
  }).filter(Boolean);

  if (sections.length === 0) return;

  const navbarHeight = 80; // Approximate navbar height with margin
  let ticking = false;
  let lastActiveLink = null;

  // Unique marker class that only we use
  const OUR_ACTIVE_CLASS = 'pike-toc-active';

  function updateActiveSection() {
    const scrollY = window.scrollY;
    const viewportCenter = scrollY + (window.innerHeight / 3); // Use upper third of viewport

    // Find the section whose heading is closest to viewport center
    // but only sections that have started (are above or at viewport center)
    let activeSection = null;
    let closestDistance = Infinity;

    for (const section of sections) {
      // Only consider sections that have content visible in viewport
      // Section starts if its top is at or above viewport center
      if (section.top <= viewportCenter + navbarHeight) {
        const distance = Math.abs(viewportCenter - section.top);
        if (distance < closestDistance) {
          closestDistance = distance;
          activeSection = section;
        }
      }
    }

    // Default to first section if none found
    if (!activeSection && sections.length > 0) {
      activeSection = sections[0];
    }

    // Only update if active section changed
    if (activeSection && activeSection.link !== lastActiveLink) {
      // Clear ALL active states - both ours and Docusaurus's
      tocLinks.forEach((link) => {
        link.classList.remove(OUR_ACTIVE_CLASS, 'active', 'table-of-contents__link--active', 'active-nested');
        link.removeAttribute('aria-current');
        link.removeAttribute('data-level');
      });

      // Set active state on the single most relevant section
      activeSection.link.classList.add(OUR_ACTIVE_CLASS);
      activeSection.link.setAttribute('aria-current', 'location');
      activeSection.link.setAttribute('data-level', activeSection.level);
      lastActiveLink = activeSection.link;

      // Auto-scroll TOC to show the active item
      scrollTocToActive(activeSection.link, tocContainer);
    }

    ticking = false;
  }

  function scrollTocToActive(activeLink, container) {
    const containerRect = container.getBoundingClientRect();
    const linkRect = activeLink.getBoundingClientRect();

    // Calculate relative position within container
    const relativeTop = linkRect.top - containerRect.top;
    const containerHeight = containerRect.height;
    const linkHeight = linkRect.height;

    // Scroll to center the active link in the TOC viewport
    const scrollTop = container.scrollTop + relativeTop - (containerHeight / 2) + (linkHeight / 2);
    container.scrollTo({
      top: Math.max(0, scrollTop),
      behavior: 'smooth'
    });
  }

  // Throttled scroll handler
  function onScroll() {
    if (!ticking) {
      requestAnimationFrame(updateActiveSection);
      ticking = true;
    }
  }

  // Add scroll listener
  window.addEventListener('scroll', onScroll, { passive: true });

  // Initial update
  setTimeout(updateActiveSection, 100);

  // Update on hash change (user clicks TOC link)
  const onHashChange = () => {
    setTimeout(updateActiveSection, 100);
  };
  window.addEventListener('hashchange', onHashChange);

  // Cleanup function
  scrollSpyCleanup = () => {
    window.removeEventListener('scroll', onScroll);
    window.removeEventListener('hashchange', onHashChange);
  };
}

/**
 * Toggle functionality for sidebar and TOC
 */
let toggleButtonsCleanup = null;

export function initToggleButtons() {
  if (typeof document === 'undefined') return;

  // Clean up previous instance
  if (toggleButtonsCleanup) {
    toggleButtonsCleanup();
    toggleButtonsCleanup = null;
  }

  // Create sidebar toggle button
  const sidebarToggle = document.createElement('button');
  sidebarToggle.className = 'sidebar-toggle-btn';
  sidebarToggle.innerHTML = '◀'; // Left arrow to hide
  sidebarToggle.setAttribute('aria-label', 'Toggle sidebar');
  sidebarToggle.setAttribute('type', 'button');

  // Create TOC toggle button
  const tocToggle = document.createElement('button');
  tocToggle.className = 'toc-toggle-btn';
  tocToggle.innerHTML = '▶'; // Right arrow to hide
  tocToggle.setAttribute('aria-label', 'Toggle table of contents');
  tocToggle.setAttribute('type', 'button');

  let sidebarVisible = true;
  let tocVisible = true;

  // Sidebar toggle handler
  sidebarToggle.addEventListener('click', () => {
    const sidebar = document.querySelector('.sidebar, [class*="sidebar"]');
    const mainContent = document.querySelector('main[class*="docMainContainer"]');

    if (sidebarVisible) {
      if (sidebar) sidebar.classList.add('sidebar-hidden');
      if (mainContent) mainContent.style.marginLeft = '0';
      sidebarToggle.innerHTML = '▶';
    } else {
      if (sidebar) sidebar.classList.remove('sidebar-hidden');
      if (mainContent) mainContent.style.marginLeft = '';
      sidebarToggle.innerHTML = '◀';
    }
    sidebarVisible = !sidebarVisible;
  });

  // TOC toggle handler
  tocToggle.addEventListener('click', () => {
    const tocContainer = document.querySelector('.theme-doc-toc-desktop, [class*="tableOfContents"]');

    if (tocVisible) {
      if (tocContainer) tocContainer.classList.add('toc-hidden');
      tocToggle.innerHTML = '◀';
    } else {
      if (tocContainer) tocContainer.classList.remove('toc-hidden');
      tocToggle.innerHTML = '▶';
    }
    tocVisible = !tocVisible;
  });

  // Add buttons to page
  document.body.appendChild(sidebarToggle);
  document.body.appendChild(tocToggle);

  // Hide TOC toggle on pages without TOC
  setTimeout(() => {
    const tocContainer = document.querySelector('.theme-doc-toc-desktop, [class*="tableOfContents"]');
    if (!tocContainer || tocContainer.children.length === 0) {
      tocToggle.style.display = 'none';
    }
  }, 100);

  // Cleanup function
  toggleButtonsCleanup = () => {
    sidebarToggle.remove();
    tocToggle.remove();
  };
}

// Run immediately for initial page load
if (typeof document !== 'undefined') {
  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      fixAutodocHighlighting();
      highlightInlineAutodocTags();
      initSearchModal();
      initScrollSpy();
      initToggleButtons();
    });
  } else {
    // Small delay to ensure Prism has finished tokenizing
    setTimeout(() => {
      fixAutodocHighlighting();
      highlightInlineAutodocTags();
      initSearchModal();
      initScrollSpy();
      initToggleButtons();
    }, 100);
  }

  // Also run after a short delay to catch dynamically rendered content
  setTimeout(() => {
    fixAutodocHighlighting();
    highlightInlineAutodocTags();
    initSearchModal();
    initScrollSpy();
    initToggleButtons();
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
