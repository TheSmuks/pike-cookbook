import React, { useEffect, useState, useMemo } from 'react';
import useIsBrowser from '@docusaurus/useIsBrowser';
import SearchBar, { highlightMatches } from './SearchBar';
import AutoDocHighlighter from './AutoDocHighlighter';
import styles from './DocPageWithSearch.module.css';

interface DocPageWithSearchProps {
  children: React.ReactNode;
}

export default function DocPageWithSearch({ children }: DocPageWithSearchProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredContent, setFilteredContent] = useState<React.ReactNode[]>([]);
  const isBrowser = useIsBrowser();

  // Apply AutoDoc highlighting to content when not searching
  const enhancedContent = useMemo(() => {
    if (searchQuery.trim()) {
      // When searching, let the search effect handle it
      return children;
    }

    const processNode = (node: React.ReactNode): React.ReactNode => {
      if (typeof node === 'string') {
        return <AutoDocHighlighter content={node} />;
      }

      if (React.isValidElement(node)) {
        const children = React.Children.toArray(node.props.children);
        const processedChildren = children.map(processNode);

        return React.cloneElement(node, {
          ...node.props,
          children: processedChildren,
        });
      }

      return node;
    };

    const childrenArray = React.Children.toArray(children);
    return childrenArray.map(processNode);
  }, [children, searchQuery]);

  // Process content and apply filtering/highlighting
  useEffect(() => {
    if (!isBrowser || !searchQuery.trim()) {
      // No search, show original content with AutoDoc highlighting
      setFilteredContent([]);
      return;
    }

    // Get all text nodes from the markdown content
    const processNode = (node: React.ReactNode): React.ReactNode => {
      if (typeof node === 'string') {
        // Apply AutoDoc highlighting first, then search highlighting
        let processed = <AutoDocHighlighter content={node} />;

        // If there's a search query, also highlight search matches
        if (searchQuery.trim()) {
          processed = highlightMatches(processed, searchQuery);
        }

        return processed;
      }

      if (React.isValidElement(node)) {
        // Recursively process children
        const children = React.Children.toArray(node.props.children);
        const processedChildren = children.map(processNode);

        // Clone element with processed children
        return React.cloneElement(node, {
          ...node.props,
          children: processedChildren,
        });
      }

      return node;
    };

    // Filter and highlight content
    const childrenArray = React.Children.toArray(children);
    const filtered = childrenArray
      .map(processNode)
      .filter((child) => {
        // Check if content matches search query
        if (React.isValidElement(child)) {
          const elementText = extractTextContent(child);
          const regex = new RegExp(searchQuery, 'i');
          return regex.test(elementText);
        }
        return true;
      });

    setFilteredContent(filtered as React.ReactNode[]);
  }, [searchQuery, children, isBrowser]);

  // Extract text content from React element
  const extractTextContent = (element: React.ReactElement): string => {
    if (typeof element.props.children === 'string') {
      return element.props.children;
    }

    if (Array.isArray(element.props.children)) {
      return element.props.children
        .map((child: React.ReactNode) => {
          if (typeof child === 'string') return child;
          if (React.isValidElement(child)) return extractTextContent(child);
          return '';
        })
        .join(' ');
    }

    if (React.isValidElement(element.props.children)) {
      return extractTextContent(element.props.children);
    }

    return '';
  };

  // Count visible matches
  const matchCount = useMemo(() => {
    if (!searchQuery.trim()) return 0;

    const markdownContent = document.querySelector('.markdown');
    if (!markdownContent) return 0;

    const regex = new RegExp(searchQuery, 'gi');
    const matches = markdownContent.textContent?.match(regex);
    return matches ? matches.length : 0;
  }, [searchQuery]);

  return (
    <div className={styles.docPageContainer}>
      <SearchBar
        onSearch={setSearchQuery}
        placeholder="Search in this page..."
        autoFocus={false}
      />

      <div className={styles.contentWrapper}>
        {searchQuery.trim() && filteredContent.length > 0 ? (
          <div className={styles.filteredContent}>
            <div className={styles.resultsHeader}>
              Found {matchCount} match{matchCount !== 1 ? 'es' : ''}
            </div>
            {filteredContent}
          </div>
        ) : searchQuery.trim() && filteredContent.length === 0 ? (
          <div className={styles.noResults}>
            <p>No matches found for "{searchQuery}"</p>
          </div>
        ) : (
          enhancedContent
        )}
      </div>
    </div>
  );
}
