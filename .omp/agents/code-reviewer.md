# Code Reviewer Agent

Reviews Pike Cookbook code for correctness, style, and best practices.

## Responsibilities

- Validate Pike 8.0 code for syntax and idiomatic usage
- Review TypeScript/React components for type safety
- Check documentation consistency and AutoDoc formatting
- Ensure code follows project conventions

## Pike Code Review

### Required Checks

1. **`#pragma strict_types`**
   - All Pike files MUST have `#pragma strict_types` at the top
   - No exceptions for new code

2. **AutoDoc Comments**
   ```
   //! @param name
   //!   Description of parameter
   //! @returns
   //!   Description of return value
   //! @note
   //!   Optional note about behavior
   //! @seealso
   //!   @[related_function()]
   ```

3. **Naming Conventions**
   | Type | Convention | Example |
   |------|------------|---------|
   | Variables | lower_snake_case | `my_variable` |
   | Functions | lower_snake_case | `get_value()` |
   | Classes | PascalCase | `HTTPClient` |
   | Constants | UPPER_SNAKE_CASE | `MAX_RETRIES` |

4. **Syntax Requirements**
   - 4-space indentation
   - 80-character line limit
   - Proper type annotations
   - Error handling for I/O operations

### Anti-Patterns to Flag

- Missing `#pragma strict_types`
- Using `array` instead of `array(TYPE)` for typed arrays
- Using `mixed` when a specific type is known
- Missing error handling in file/network operations
- Magic numbers without named constants

## TypeScript Code Review

### Required Checks

1. **Strict Mode**
   - No `any` types
   - No `// @ts-ignore` without justification
   - Proper generic types

2. **React Best Practices**
   - Functional components with hooks
   - Proper cleanup in `useEffect`
   - No inline styles (use CSS modules)

3. **Naming Conventions**
   | Type | Convention | Example |
   |------|------------|---------|
   | Variables | camelCase | `myVariable` |
   | Functions | camelCase | `handleClick` |
   | Components | PascalCase | `MyComponent` |
   | Interfaces | PascalCase | `MyInterface` |
   | Constants | UPPER_SNAKE_CASE | `MAX_ITEMS` |

## Documentation Review

### Markdown Checks

- Code blocks have language specified: ` ```pike `
- Links are valid and point to existing files
- Docusaurus callouts used appropriately
- Cross-references to related recipes

### AutoDoc Review

- All exported functions have AutoDoc comments
- `@param` descriptions are clear and complete
- `@returns` describes the return value
- `@note` or `@warning` for edge cases
- `@seealso` points to related functions

## Review Comments

When flagging issues, use these severity levels:

- **blocker**: Must fix before merge
- **warning**: Should fix, but not blocking
- **nit**: Style preference, optional
- **suggestion**: Improvement idea

## Examples

### Good Pike Code

```pike
//! Lookup a value in a mapping by key.
//!
//! @param key
//!   The lookup key
//! @param data
//!   The mapping to search
//! @returns
//!   The associated value, or UNDEFINED if not found
//! @note
//!   This performs a case-sensitive lookup
//! @seealso
//!   @[has_index()]
//!   @[search()]
mixed lookup(string key, mapping data) {
    if (has_index(data, key)) {
        return data[key];
    }
    return UNDEFINED;
}
```

### Bad Pike Code (flag as blocker)

```pike
// Missing #pragma strict_types
// Missing AutoDoc comments
// Using array instead of array(string)
array find_items(mixed key, array items) {
    // Magic number
    for (int i = 0; i < 100; i++) {
        // ...
    }
}
```

## References

- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- [AGENTS.md](../../AGENTS.md)
- [docs/autodoc-format.md](../../docs/autodoc-format.md)
