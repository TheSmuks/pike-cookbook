# Pike Cookbook — Agent Guidelines

Cross-agent configuration for developing the Pike Cookbook documentation site.

## Project Overview

- **Name**: Pike Cookbook
- **Type**: Docusaurus 3.9.2 documentation site + Pike code examples
- **URL**: https://thesmuks.github.io/pike-cookbook/
- **Repository**: github.com/TheSmuks/pike-cookbook
- **License**: ISC

## Technology Stack

| Component | Technology |
|-----------|------------|
| Documentation | Docusaurus 3.9.2 |
| Package Manager | Bun (local), npm (CI for Pages compatibility) |
| TypeScript | Strict mode (src/components, src/theme) |
| Pike | 8.0 with `#pragma strict_types` |
| Build | `npm run build` / `bun run build` |
| Dev Server | `npm start` / `bun start` |
| Pike Tests | `pike test_recipes.pike` |

## Build Commands

```bash
# Local development
bun start              # Start Docusaurus dev server
bun run build          # Production build
bun run serve          # Serve production build

# CI / Production
npm install            # Install dependencies
npm run build          # Build for deployment

# Pike recipes
pike test_recipes.pike # Test all Pike examples for syntax
```

## Code Style

### Pike (4-space indent, strict types)

All Pike code must use `#pragma strict_types` and follow these conventions:

```
// Variables and functions: lower_snake_case
array(string) find_pike_files(string dir) { ... }
int test_syntax(string file) { ... }

// Classes: PascalCase
class HTTPClient { ... }

// Constants: UPPER_SNAKE_CASE
constant MAX_RETRIES = 3;

// Maximum line length: 80 characters
// Indent: 4 spaces (no tabs)
```

### TypeScript/React (Docusaurus theme)

- Strict TypeScript mode enabled
- Functional components with hooks
- CSS modules for styling
- Maximum function length: 60 lines

### Documentation (Markdown/MDX)

- Use Docusaurus callouts:
  - `:::tip` for best practices
  - `:::note` for important info
  - `:::warning` for dangerous operations
- Include "See Also" cross-references
- Code blocks with Pike syntax highlighting

## File Organization

```
pike-cookbook/
├── docs/                  # Documentation content
│   ├── intro.md          # Introduction
│   ├── basics/           # Fundamental language features
│   ├── files/            # File operations
│   ├── network/          # Network programming
│   ├── advanced/         # OOP, processes, modules
│   └── autodoc-*.md      # AutoDoc formatting guides
├── src/                  # Docusaurus theme
│   ├── components/       # React components (TypeScript)
│   ├── css/             # Styles
│   ├── theme/            # Theme customizations
│   └── pages/           # Custom pages
├── recipes/              # Pike code examples
│   ├── database/        # Database operations
│   └── process/         # Process management
├── examples/            # Additional Pike examples
│   └── webautomation/  # Web automation recipes
├── pleac_pike/          # PLEAC reference implementations
├── docusaurus.config.js # Site configuration
└── sidebars.js          # Documentation sidebar
```

## Quality Gates

### Thresholds (from `.architecture.yml`)

| Metric | Pike | TypeScript/JS | Markdown |
|--------|------|--------------|----------|
| Max file lines | 400 | 200 | 300 |
| Max function lines | 60 | 40 | — |
| Max expression complexity | 10 | 8 | — |

### Required Checks

1. **Build passes**: `npm run build` must succeed
2. **Pike syntax**: All `.pike` files pass `pike -x dump`
3. **No dead code**: Remove unused imports/variables
4. **No placeholders**: Fill all TODO comments before merging

### CI Workflows

| Workflow | Purpose |
|----------|---------|
| `deploy.yml` | Build and deploy to GitHub Pages |
| `commit-lint.yml` | Validate conventional commit messages |
| `changelog-check.yml` | Require changelog entry for changed files |
| `blob-size-policy.yml` | Block oversized file additions |

## Commit Conventions

Format: `type: brief description`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Branch naming: `feature/my-recipe`, `fix/bug-description`

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

## Non-Goals

- No backend/server logic
- No database integration beyond Pike examples
- No user authentication
- No internationalization (English only)
