import React, { useState, useEffect, useCallback, useRef } from 'react';
import clsx from 'clsx';
import styles from './SearchBar.module.css';

export interface SearchBarProps {
  onSearch?: (query: string) => void;
  placeholder?: string;
  autoFocus?: boolean;
  className?: string;
  maxHistoryItems?: number;
}

export interface SearchMatch {
  text: string;
  indices: number[][];
}

const HISTORY_KEY = 'pike-cookbook-search-history';

export function SearchBar({
  onSearch,
  placeholder = 'Search documentation...',
  autoFocus = false,
  className,
  maxHistoryItems = 8,
}: SearchBarProps) {
  const [query, setQuery] = useState('');
  const [matchCount, setMatchCount] = useState(0);
  const [showHistory, setShowHistory] = useState(false);
  const [history, setHistory] = useState<string[]>([]);
  const [focusedIndex, setFocusedIndex] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const debouncedSearchRef = useRef<NodeJS.Timeout>();

  // Load search history from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem(HISTORY_KEY);
      if (saved) {
        setHistory(JSON.parse(saved));
      }
    } catch (error) {
      console.warn('Failed to load search history:', error);
    }
  }, []);

  // Save to history when search is performed
  const saveToHistory = useCallback(
    (searchQuery: string) => {
      if (!searchQuery.trim()) return;

      setHistory((prev) => {
        const filtered = prev.filter((item) => item !== searchQuery);
        const updated = [searchQuery, ...filtered].slice(0, maxHistoryItems);

        try {
          localStorage.setItem(HISTORY_KEY, JSON.stringify(updated));
        } catch (error) {
          console.warn('Failed to save search history:', error);
        }

        return updated;
      });
    },
    [maxHistoryItems]
  );

  // Handle keyboard shortcut (Ctrl/Cmd + F) and Escape
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
        e.preventDefault();
        inputRef.current?.focus();
        setShowHistory(true);
      }

      if (e.key === 'Escape') {
        setShowHistory(false);
        setFocusedIndex(-1);
        inputRef.current?.blur();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Auto-focus on mount if requested
  useEffect(() => {
    if (autoFocus && inputRef.current) {
      inputRef.current.focus();
    }
  }, [autoFocus]);

  // Close history dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target as Node)
      ) {
        setShowHistory(false);
        setFocusedIndex(-1);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Debounced search handler
  const handleInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const newQuery = e.target.value;
      setQuery(newQuery);
      setShowHistory(true);

      debouncedSearchRef.current && clearTimeout(debouncedSearchRef.current);

      debouncedSearchRef.current = setTimeout(() => {
        if (onSearch) {
          onSearch(newQuery);
          if (newQuery.trim()) {
            saveToHistory(newQuery);
          }
        }
      }, 300);
    },
    [onSearch, saveToHistory]
  );

  const handleClear = useCallback(() => {
    setQuery('');
    setMatchCount(0);
    if (onSearch) {
      onSearch('');
    }
    inputRef.current?.focus();
  }, [onSearch]);

  const handleHistoryClick = useCallback(
    (item: string) => {
      setQuery(item);
      setShowHistory(false);
      if (onSearch) {
        onSearch(item);
      }
      inputRef.current?.focus();
    },
    [onSearch]
  );

  const handleHistoryKeyDown = useCallback(
    (e: React.KeyboardEvent, item: string) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        handleHistoryClick(item);
      }
    },
    [handleHistoryClick]
  );

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (showHistory && history.length > 0) {
        if (e.key === 'ArrowDown') {
          e.preventDefault();
          setFocusedIndex((prev) =>
            prev < history.length - 1 ? prev + 1 : prev
          );
        } else if (e.key === 'ArrowUp') {
          e.preventDefault();
          setFocusedIndex((prev) => (prev > 0 ? prev - 1 : -1));
        } else if (e.key === 'Enter' && focusedIndex >= 0) {
          e.preventDefault();
          handleHistoryClick(history[focusedIndex]);
        }
      }
    },
    [showHistory, history, focusedIndex, handleHistoryClick]
  );

  // Clear all history
  const clearHistory = useCallback(() => {
    setHistory([]);
    try {
      localStorage.removeItem(HISTORY_KEY);
    } catch (error) {
      console.warn('Failed to clear search history:', error);
    }
  }, []);

  // Clean up timeout on unmount
  useEffect(() => {
    return () => {
      if (debouncedSearchRef.current) {
        clearTimeout(debouncedSearchRef.current);
      }
    };
  }, []);

  // Function to update match count (can be called by parent component)
  useEffect(() => {
    if (query.trim() === '') {
      setMatchCount(0);
      return;
    }

    // Count matches in the current document content
    const content = document.querySelector('.markdown')?.textContent || '';
    const regex = new RegExp(
      query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      'gi'
    );
    const matches = content.match(regex);
    setMatchCount(matches ? matches.length : 0);
  }, [query]);

  const filteredHistory = history.filter(
    (item) =>
      item.toLowerCase().includes(query.toLowerCase()) && item !== query
  );

  return (
    <div className={clsx(styles.searchContainer, className)} ref={containerRef}>
      <div className={styles.searchWrapper}>
        <svg
          className={styles.searchIcon}
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          aria-hidden="true"
          focusable="false"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
        <input
          ref={inputRef}
          type="text"
          value={query}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          onFocus={() => setShowHistory(true)}
          placeholder={placeholder}
          className={styles.searchInput}
          aria-label="Search documentation"
          aria-autocomplete="list"
          aria-controls="search-history-list"
          aria-expanded={showHistory && filteredHistory.length > 0}
          role="combobox"
        />
        {query && (
          <>
            <span className={styles.matchCount} aria-live="polite">
              {matchCount} {matchCount === 1 ? 'match' : 'matches'}
            </span>
            <button
              onClick={handleClear}
              className={styles.clearButton}
              aria-label="Clear search"
              type="button"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                aria-hidden="true"
                focusable="false"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </>
        )}
      </div>

      {showHistory && filteredHistory.length > 0 && (
        <ul
          id="search-history-list"
          className={styles.historyDropdown}
          role="listbox"
        >
          {filteredHistory.map((item, index) => (
            <li
              key={item}
              className={clsx(
                styles.historyItem,
                index === focusedIndex && styles.historyItemFocused
              )}
              onClick={() => handleHistoryClick(item)}
              onKeyDown={(e) => handleHistoryKeyDown(e, item)}
              role="option"
              aria-selected={index === focusedIndex}
              tabIndex={0}
            >
              <svg
                className={styles.historyIcon}
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span className={styles.historyText}>{item}</span>
            </li>
          ))}
          {history.length > 0 && (
            <li className={styles.historyFooter}>
              <button
                onClick={clearHistory}
                className={styles.clearHistoryButton}
                type="button"
              >
                Clear all history
              </button>
            </li>
          )}
        </ul>
      )}

      <div className={styles.keyboardHint} aria-hidden="true">
        Press <kbd>Ctrl</kbd> + <kbd>F</kbd> to focus
      </div>
    </div>
  );
}

// Utility function to highlight text matches
export function highlightMatches(
  text: string,
  query: string
): React.ReactNode {
  if (!query.trim()) {
    return text;
  }

  try {
    const regex = new RegExp(
      `(${query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`,
      'gi'
    );
    const parts = text.split(regex);

    return parts.map((part, index) => {
      if (regex.test(part)) {
        return (
          <mark key={index} className={styles.highlight}>
            {part}
          </mark>
        );
      }
      return part;
    });
  } catch {
    return text;
  }
}

export default SearchBar;
