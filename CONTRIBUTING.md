# Contributing to Pike Cookbook

Thank you for your interest in contributing to the Pike Cookbook. This document provides guidelines for contributing.

## Getting Started

### Prerequisites

- Pike 8.0 or later
- Node.js 18+ and Bun (for documentation builds)
- Git

### Setting Up

```bash
# Clone the repository
git clone https://github.com/TheSmuks/pike-cookbook.git
cd pike-cookbook

# Install dependencies
bun install

# Start development server
bun start
```

## Contribution Guidelines

### Adding Recipes

1. **Choose the Right Location**
   - Basics: `/docs/basics/` for fundamental language features
   - Files: `/docs/files/` for file operations
   - Network: `/docs/network/` for network programming
   - Advanced: `/docs/advanced/` for complex topics

2. **Follow the Format**

Each recipe should include:
- Clear title and description
- Practical code example with `#pragma strict_types`
- Explanation of how it works
- "What this covers" and "Why use it" context
- Docusaurus callouts (`:::tip`, `:::note`, `:::warning`)
- "See Also" section with cross-references

3. **Use AutoDoc Comments**

Document code using Pike AutoDoc format:
```pike
//! @param key
//!   The lookup key
//! @returns
//!   The associated value, or zero if not found
//! @note
//!   This function performs a case-sensitive search
//! @seealso
//!   @[search()]
mixed lookup(string key) {
    return mapping[key];
}
```

4. **Test Your Code**

Ensure all code examples:
- Run without errors
- Use `#pragma strict_types` for type safety
- Follow Pike 8.0 syntax and best practices
- Include proper error handling

### Documentation Style

- Use clear, concise language
- Avoid jargon unless explained
- Provide context before showing code
- Use callouts for important information
- Link to related recipes

### Commit Messages

Follow conventional commit format:
```
type: brief description

Detailed explanation (optional)

Co-Authored-By: Name <email>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-recipe`)
3. Make your changes following the guidelines above
4. Test thoroughly
5. Submit a pull request with:
   - Clear title and description
   - Link to related issues
   - Screenshots if applicable (for UI changes)

### PR Review Checklist

- [ ] Code follows Pike 8.0 syntax
- [ ] AutoDoc comments included where appropriate
- [ ] Documentation builds without errors (`bun run build`)
- [ ] Examples tested and working
- [ ] Cross-references added
- [ ] Spelling and grammar checked

## CLA Requirements

Before your pull request can be merged, you must sign the Contributor License Agreement (CLA). This ensures that:
- Your contributions can be used under the ISC license
- You have the rights to submit the code
- The community can benefit from your work

To sign the CLA:
1. Open a pull request
2. You'll receive a comment with CLA instructions
3. Follow the provided link to sign

## Coding Standards

### Pike Guidelines

- Use `#pragma strict_types` for all code
- Follow Pike naming conventions:
  - `lower_snake_case` for variables and functions
  - `PascalCase` for classes
  - `UPPER_SNAKE_CASE` for constants
- Indent with 4 spaces
- Maximum line length: 80 characters

### Documentation Guidelines

- Use `:::tip` for best practices and optimizations
- Use `:::note` for important information
- Use `:::warning` for dangerous operations
- Keep paragraphs short and focused
- Use active voice

## Questions?

Open an issue for discussion before starting significant work. This helps ensure your contribution aligns with project goals.

## License

By contributing, you agree that your contributions will be licensed under the ISC License.
