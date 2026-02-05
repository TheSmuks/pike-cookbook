---
id: autodoc-highlighter
title: AutoDoc Syntax Highlighter Component
sidebar_label: AutoDoc Highlighter
---

# AutoDoc Syntax Highlighter Component

This document describes the AutoDoc syntax highlighting component that automatically highlights AutoDoc tags and inline markup in documentation.

## Overview

The `AutoDocHighlighter` component parses text content and applies color-coded syntax highlighting to AutoDoc tags and inline markup, making documentation more readable and easier to understand.

## Features

### Supported Tags

#### Meta Keywords
- `@decl` - Function/variable declarations (purple theme)
- `@class`, `@endclass` - Class documentation (pink theme)
- `@module`, `@endmodule` - Module documentation (magenta theme)

#### Documentation Tags
- `@param` - Parameter documentation (blue theme)
- `@return`, `@returns` - Return value documentation (green theme)
- `@throws` - Exception documentation (red theme)
- `@seealso` - Related references (indigo theme)
- `@example` - Usage examples (cyan theme)
- `@note` - Important notes (amber theme)
- `@deprecated` - Deprecation warnings (gray with strikethrough)
- `@bugs` - Known issues (orange theme)

#### Block Keywords
- `@dl`, `@enddl` - Description lists (teal theme)
- `@mapping`, `@endmapping` - Mapping documentation (green theme)
- `@array`, `@endarray` - Array documentation (lime theme)
- `@item` - List items (light green)
- `@member` - Mapping members (green)
- `@index` - Index entries (purple)

#### Inline Markup
- `@i{...@}` - Italic text (gray, italic)
- `@b{...@}` - Bold text (dark gray, bold)
- `@tt{...@}` - Monospace/teletype (red, monospace font)
- `@ref{...@}` - References to Pike entities (purple, underlined)
- `@xml{...@}` - Raw XML content (dark red, bordered)

## Usage

### Basic Usage

```tsx
import AutoDocHighlighter from '@site/src/components/AutoDocHighlighter';

<AutoDocHighlighter content="//! @param x The x coordinate" />
```

### Standalone Usage

You can also use the utility function to highlight AutoDoc content:

```tsx
import { highlightAutoDoc } from '@site/src/components/AutoDocHighlighter';

// Returns React.ReactNode with highlighted tags
const highlighted = highlightAutoDoc("Your @param documentation here");
```

## Examples

### Function Documentation

```pike
//! Calculate the factorial of a number.
//! @param n
//!   Non-negative integer to calculate factorial for
//! @returns
//!   Factorial of n
//! @throws
//!   Error if n is negative
int factorial(int n)
```

### Multiple Parameters

```pike
//! Connect to a database.
//! @param host
//!   Database host address
//! @param port
//!   Database port number
//! @returns
//!   Database connection object
//! @throws
//!   ConnectionError if connection fails
```

### Class Documentation

```pike
//! A logger class with different severity levels.
//! @note
//!   Log messages are written to stderr by default
//! @seealso
//!   @[FileLogger] for file-based logging
//! @deprecated
//!   Use @[AdvancedLogger] instead
//! @bugs
//!   May lose messages under high load
```

### Inline Markup

```pike
//! This is @i{italic@} and @b{bold@} text.
//! See @ref{function_name@} for more info.
//! Use @tt{code@} for monospace.
```

## Component API

### AutoDocHighlighter

#### Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `content` | `string` | Yes | The text content to parse and highlight |

#### Returns

Returns a React `span` element with highlighted tags and inline markup.

## Styling

The component uses CSS modules for styling. Each tag type has its own CSS class with specific colors and styling:

```css
.tag-param        /* Blue - parameters */
.tag-returns      /* Green - return values */
.tag-throws       /* Red - exceptions */
.tag-seealso      /* Indigo - references */
.tag-example      /* Cyan - examples */
.tag-note         /* Amber - notes */
.tag-deprecated   /* Gray - deprecated */
.tag-bugs         /* Orange - bugs */
```

## Implementation Details

### Parsing Algorithm

1. The component scans the input text for `@` characters
2. When found, it checks if it matches a known tag pattern
3. For inline markup (`@i{...@}`, `@b{...@}`, etc.), it extracts the content between braces
4. For standalone tags, it applies the appropriate styling
5. Regular text is passed through unchanged

### Performance

- Uses `React.useMemo` to cache parsed results
- Only re-parses when content changes
- Minimal overhead for text without tags

## File Structure

```
src/components/
├── AutoDocHighlighter.tsx          # Main component
├── AutoDocHighlighter.module.css   # Styling
└── __tests__/
    └── AutoDocHighlighter.test.tsx # Unit tests
```

## Testing

The component includes comprehensive unit tests covering:
- All tag types
- Inline markup variations
- Multiple tags in one line
- Mixed text and tags
- Edge cases

Run tests with:
```bash
npm test -- AutoDocHighlighter
```

## Future Enhancements

Potential improvements:
- Support for custom color themes
- Configurable tag detection
- Export functionality
- Integration with code editors
- Syntax validation

## See Also

- [AutoDoc Format Guide](/docs/autodoc-format) - Complete reference for AutoDoc syntax
