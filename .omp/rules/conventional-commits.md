# Conventional Commits Rule

Enforces Conventional Commits format for all commit messages.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

## Type Reference

| Type | Description |
|------|-------------|
| feat | New feature for the user |
| fix | Bug fix for the user |
| docs | Documentation only changes |
| style | Formatting, missing semicolons, etc. |
| refactor | Code change that neither fixes a bug nor adds a feature |
| perf | Code change that improves performance |
| test | Adding or updating tests |
| chore | Changes to build process, dependencies, etc. |

## Scope Reference

| Scope | Description |
|-------|-------------|
| docs | Documentation content changes |
| site | Docusaurus site configuration |
| theme | React components or styling |
| recipe | Pike code example changes |
| example | Pike example file changes |
| ci | GitHub Actions workflow changes |
| archive | PLEAC reference files |

## Rules

### Must Have

1. **Type** - Must be one of: feat, fix, docs, style, refactor, perf, test, chore
2. **Colon** - Must have `:` after type or type(scope)
3. **Description** - Must have a short description after the colon

### Must Not Have

1. **No uppercase** - First letter of description should be lowercase
2. **No period** - Don't end the description with a period
3. **No line over 72 characters** - Keep descriptions concise

### Should Have

1. **Scope** - Use scope to identify affected area
2. **Body** - For complex changes, add explanatory body text
3. **Footer** - Reference issues/PRs with `Closes #N` or `PR #M`

## Examples

### Valid Commits

```
feat(recipe): add HTTP/2 client example
fix(docs): correct typo in sockets.md
docs: update contributing guidelines
feat(site): add dark mode toggle
fix(theme): resolve code block overflow issue
refactor(recipe): simplify database connection logic
test(recipe): add tests for new IPC functions
chore(ci): update Node.js version to 20
```

### Invalid Commits

```
Update code                           # Missing type
Fixed bug                             # Missing type
feat: Add new feature                  # Description starts uppercase
feat: added new feature                # Description starts lowercase but follows uppercase convention
docs: Fixed the docs.                  # Ends with period
feat: This is a very long description that goes on and on and exceeds the recommended line length limit # Line too long
```

## Validation

This rule is enforced by `.github/workflows/commit-lint.yml` using `@commitlint/config-conventional`.

## References

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Angular Commit Message Format](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
