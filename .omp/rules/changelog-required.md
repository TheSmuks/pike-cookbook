# Changelog Required Rule

Ensures all user-facing changes are documented in CHANGELOG.md.

## Purpose

The CHANGELOG.md is the primary way users learn about:
- New features they can use
- Bug fixes that affect them
- Breaking changes they need to handle
- Improvements to existing functionality

Without changelog entries, users miss important updates.

## Scope

This rule applies to changes that affect:

| Category | Examples |
|----------|----------|
| Added | New recipes, new documentation sections, new features |
| Changed | Modified code examples, updated functionality |
| Deprecated | Features marked for removal |
| Removed | Deleted recipes, removed functionality |
| Fixed | Bug fixes in examples or documentation |
| Security | Security-related fixes or updates |

This rule does NOT require changelog entries for:

| Category | Examples |
|----------|----------|
| chore | Dependency updates, CI configuration |
| refactor | Internal code restructuring |
| style | Formatting changes, no semantic difference |
| test | Adding or updating tests |

## When to Update

Update the changelog when:

1. **Creating new content** users will use
2. **Fixing bugs** users may have encountered
3. **Changing existing behavior** users depend on
4. **Removing features** users currently use
5. **Improving documentation** significantly

## Format

Entries go in the `[Unreleased]` section under the appropriate category:

```markdown
## [Unreleased]

### Added
- New Pike recipe for feature (PR #123)

### Fixed
- Bug fix description (PR #124)
```

## Anti-Patterns

### Don't Add

```markdown
- Updated CHANGELOG.md
- Fixed typo in own documentation
- Refactored internal code
```

### Do Add

```markdown
### Added
- New recipe: Database connection pooling with Pike

### Fixed
- Corrected syntax error in signal handler example that prevented compilation
```

## Validation

This rule is enforced by `.github/workflows/changelog-check.yml` using `dangoslen/changelog-enforcer`.

When a PR changes a file, the workflow checks that CHANGELOG.md was updated with an entry for that change.

## Exceptions

If a change genuinely doesn't need changelog documentation:

1. Add `[skip changelog]` to the commit message footer
2. Include justification in the commit body

Example:
```
chore(deps): update npm dependencies

[skip changelog] - Internal dependency updates only, no user-facing impact
```

## References

- [Keep a Changelog](https://keepachangelog.com/)
- [CHANGELOG.md](../../CHANGELOG.md)
