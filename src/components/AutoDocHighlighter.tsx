import React from 'react';
import styles from './AutoDocHighlighter.module.css';

interface AutoDocHighlighterProps {
  content: string;
}

interface ParsedSegment {
  type: 'text' | 'tag' | 'inline-markup';
  content: string;
  tagType?: string;
}

export default function AutoDocHighlighter({ content }: AutoDocHighlighterProps) {
  const segments = React.useMemo(() => parseAutoDoc(content), [content]);

  return (
    <span className={styles.autodoc}>
      {segments.map((segment, index) => renderSegment(segment, index))}
    </span>
  );
}

function parseAutoDoc(content: string): ParsedSegment[] {
  const segments: ParsedSegment[] = [];
  let remaining = content;

  while (remaining.length > 0) {
    // Check for inline markup tags first (@i{...@}, @b{...@}, etc.)
    const inlineMatch = remaining.match(/^@(i|b|tt|ref|xml)\{([^@]*)@/);
    if (inlineMatch) {
      segments.push({
        type: 'inline-markup',
        content: inlineMatch[2],
        tagType: inlineMatch[1],
      });
      remaining = remaining.slice(inlineMatch[0].length);
      continue;
    }

    // Check for standalone tags (@param, @returns, etc.)
    const tagMatch = remaining.match(/^@(\w+)(\s*)/);
    if (tagMatch) {
      const tagName = tagMatch[1];
      const whitespace = tagMatch[2];

      // Check if it's a known AutoDoc tag
      if (isKnownTag(tagName)) {
        segments.push({
          type: 'tag',
          content: `@${tagName}`,
          tagType: tagName,
        });

        // Add the whitespace after the tag as regular text
        if (whitespace) {
          segments.push({
            type: 'text',
            content: whitespace,
          });
        }

        remaining = remaining.slice(tagMatch[0].length);
        continue;
      }
    }

    // Extract text until next tag or inline markup
    const nextTagIndex = remaining.indexOf('@');
    if (nextTagIndex === 0) {
      // @ at start but no match - treat as text
      segments.push({
        type: 'text',
        content: '@',
      });
      remaining = remaining.slice(1);
    } else if (nextTagIndex > 0) {
      segments.push({
        type: 'text',
        content: remaining.slice(0, nextTagIndex),
      });
      remaining = remaining.slice(nextTagIndex);
    } else {
      // No more tags
      segments.push({
        type: 'text',
        content: remaining,
      });
      break;
    }
  }

  return segments;
}

function isKnownTag(tagName: string): boolean {
  const knownTags = new Set([
    // Meta keywords
    'decl', 'class', 'endclass', 'module', 'endclass', 'endmodule',
    // Common tags
    'param', 'return', 'returns', 'throws', 'seealso', 'example',
    'note', 'deprecated', 'bugs',
    // Block keywords
    'dl', 'enddl', 'mapping', 'endmapping', 'array', 'endarray',
    'item', 'member', 'index',
  ]);
  return knownTags.has(tagName);
}

function renderSegment(segment: ParsedSegment, index: number): React.ReactNode {
  switch (segment.type) {
    case 'tag':
      return (
        <span key={index} className={`${styles.tag} ${styles[`tag-${segment.tagType}`] || ''}`}>
          {segment.content}
        </span>
      );

    case 'inline-markup':
      return (
        <span
          key={index}
          className={`${styles.inlineMarkup} ${styles[`markup-${segment.tagType}`] || ''}`}
        >
          {segment.content}
        </span>
      );

    case 'text':
    default:
      return <span key={index}>{segment.content}</span>;
  }
}

// Utility function to highlight AutoDoc in any text content
export function highlightAutoDoc(text: string): React.ReactNode {
  return <AutoDocHighlighter content={text} />;
}
