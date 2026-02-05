# AutoDoc Syntax Highlighter

A React component that provides syntax highlighting for Pike AutoDoc tags and inline markup.

## Quick Start

```tsx
import AutoDocHighlighter from '@site/src/components/AutoDocHighlighter';

<AutoDocHighlighter content="//! @param x The x coordinate" />
```

## Features

- **AutoDoc Tag Highlighting**: Color-coded tags for `@param`, `@returns`, `@throws`, `@seealso`, `@example`, `@note`, `@deprecated`, `@bugs`, etc.
- **Inline Markup**: Supports `@i{...@}`, `@b{...@}`, `@tt{...@}`, `@ref{...@}`, `@xml{...@}`
- **TypeScript**: Fully typed with TypeScript
- **CSS Modules**: Scoped styling for easy customization
- **Performance**: Memoized parsing for efficient re-renders

## Supported Tags

### Meta Keywords
| Tag | Color | Description |
|-----|-------|-------------|
| `@decl` | Purple | Function/variable declarations |
| `@class` / `@endclass` | Pink | Class documentation |
| `@module` / `@endmodule` | Magenta | Module documentation |

### Documentation Tags
| Tag | Color | Description |
|-----|-------|-------------|
| `@param` | Blue | Parameter documentation |
| `@returns` | Green | Return value documentation |
| `@throws` | Red | Exception documentation |
| `@seealso` | Indigo | Related references |
| `@example` | Cyan | Usage examples |
| `@note` | Amber | Important notes |
| `@deprecated` | Gray | Deprecation warnings |
| `@bugs` | Orange | Known issues |

### Inline Markup
| Tag | Style | Description |
|-----|--------|-------------|
| `@i{...@}` | Italic, gray | Italic text |
| `@b{...@}` | Bold, dark gray | Bold text |
| `@tt{...@}` | Monospace, red | Teletype/monospace |
| `@ref{...@}` | Monospace, purple, underlined | References |
| `@xml{...@}` | Monospace, dark red, bordered | Raw XML |

## Examples

### Basic Usage

```tsx
import AutoDocHighlighter from '@site/src/components/AutoDocHighlighter';

function MyComponent() {
  const doc = `//! Calculate factorial.
//! @param n Non-negative integer
//! @returns Factorial of n
//! @throws Error if n is negative`;

  return <AutoDocHighlighter content={doc} />;
}
```

## Customization

### Modify Colors

Edit `AutoDocHighlighter.module.css`:

```css
.tag-param {
  background-color: #your-color;
  color: #your-text-color;
}
```

### Add New Tags

1. Add tag to `isKnownTag()` function in `AutoDocHighlighter.tsx`
2. Add CSS class in `AutoDocHighlighter.module.css`

## Testing

```bash
npm test -- AutoDocHighlighter
```

## Files

- `src/components/AutoDocHighlighter.tsx` - Main component
- `src/components/AutoDocHighlighter.module.css` - Styles
- `src/components/__tests__/AutoDocHighlighter.test.tsx` - Tests
- `docs/autodoc-highlighter.md` - Documentation

## Related Documentation

- [AutoDoc Format Guide](/docs/autodoc-format) - Complete AutoDoc syntax reference
- [AutoDoc Highlighter Documentation](/docs/autodoc-highlighter) - Detailed usage guide
