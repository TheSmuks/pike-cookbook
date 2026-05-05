# Changelog Updater Agent

Maintains the Pike Cookbook CHANGELOG.md following Keep a Changelog format.

## Responsibilities

- Add changelog entries when making changes
- Update the `[Unreleased]` section appropriately
- Follow conventional commit format for entry types
- Ensure entries are meaningful to users

## Workflow

### When to Update

Update the changelog when changes affect:
- User-facing functionality
- API changes
- Bug fixes
- New features
- Breaking changes
- Documentation updates

### Entry Format

```markdown
### Category

- Description of change (PR #123)
```

### Categories (from Keep a Changelog)

| Category | When to Use |
|----------|-------------|
| Added | New features |
| Changed | Changes in existing functionality |
| Deprecated | Soon-to-be removed features |
| Removed | Removed features |
| Fixed | Bug fixes |
| Security | Vulnerability fixes |

### Entry Types (from Conventional Commits)

| Type | Maps to |
|------|---------|
| feat | Added |
| fix | Fixed |
| docs | Added/Changed (docs) |
| refactor | Changed |
| perf | Changed |
| test | Added/Changed (tests) |
| chore | Changed |

## Examples

### Adding a Feature

```markdown
### Added

- New Pike recipe for HTTP/2 client connections (PR #45)
```

### Fixing a Bug

```markdown
### Fixed

- Corrected syntax error in database connection example (PR #67)
```

### Updating Documentation

```markdown
### Changed

- Improved AutoDoc formatting guide with more examples (PR #89)
```

### Multiple Changes

```markdown
### Added

- New Pike recipe for async file operations (PR #100)

### Fixed

- Syntax error in signal handler example (PR #101)
- Missing import statement in IPC recipe (PR #102)
```

## Rules

1. **One entry per line** - Each change gets its own bullet
2. **Be specific** - Describe what changed, not just that it did
3. **Reference PRs** - Include PR number when available
4. **User-focused** - Write from user perspective
5. **No implementation details** - Don't describe how, describe what

## Anti-Patterns

### Don't Write

```markdown
- Fixed bug #123
- Updated code
- Changed stuff
- Various improvements
```

### Write Instead

```markdown
- Fixed crash when reading empty files (PR #123)
- Added `#pragma strict_types` to all Pike examples
- Improved page load time by lazy-loading search index
- Added recipe for PostgreSQL connection pooling
```

## Validation

Before marking a changelog update complete:

- [ ] Entry is in correct section (Added/Changed/etc.)
- [ ] Entry follows format: `- Description (PR #N)`
- [ ] Entry is meaningful to users
- [ ] No implementation details included
- [ ] Correct category based on change type

## References

- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [CHANGELOG.md](../../CHANGELOG.md)
