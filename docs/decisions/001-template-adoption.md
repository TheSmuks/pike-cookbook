# ADR-001: ai-project-template Adoption

**Status**: Accepted  
**Date**: 2026-05-05  
**Deciders**: Pike Cookbook maintainers

## Context

The Pike Cookbook has evolved from a simple documentation project into a substantial codebase with:
- Docusaurus 3.9.2 documentation site
- Pike 8.0 code examples (4500+ lines across ~50 files)
- TypeScript React components with strict mode
- CI/CD deployment to GitHub Pages
- Multiple contributors

The project lacked:
- Standardized agent/prompt configuration
- Architecture documentation
- Quality gates beyond build success
- Conventional commit enforcement
- Changelog maintenance

The [ai-project-template](https://github.com/nicoqiujs/ai-project-template) v0.7.0 provides a proven foundation for AI-augmented development with OMP integration, quality gates, and architecture rules.

## Decision

Adopt ai-project-template v0.7.0 with the following adaptations:

### What to Add

1. **Documentation**
   - `AGENTS.md` - Project context for AI agents (Pike + Docusaurus specifics)
   - `ARCHITECTURE.md` + `docs/architecture.md` - System documentation
   - `CHANGELOG.md` - Release tracking
   - `.template-version` - Version tracking

2. **Quality Gates**
   - `commit-lint.yml` - Conventional commit enforcement
   - `changelog-check.yml` - Changelog entry requirement
   - `blob-size-policy.yml` - File size limits

3. **OMP Configuration**
   - `.omp/agents/code-reviewer.md` - Pike + TypeScript review
   - `.omp/rules/conventional-commits.md` - Commit rules
   - `.omp/rules/changelog-required.md` - Changelog rules

### What to Skip

| Item | Reason |
|------|--------|
| `.devcontainer/` | No dev container needed |
| `.pre-commit-config.yaml` | Python/pip dependency adds friction |
| `branch-lint.yml`, `branch-cleanup.yml` | Low value for docs project |
| `.github/dependabot.yml` | Add later if desired |
| `ci.yml` | Template-specific; cookbook has `deploy.yml` |

### What to Adapt

1. **`AGENTS.md`** - Fill with:
   - Project name, stack, build commands
   - Pike code style (4-space indent, `#pragma strict_types`)
   - File size thresholds calibrated to codebase

2. **`.architecture.yml`** - Configure:
   - `ignore_patterns`: `docs/**`, `pleac_pike/**`, `static/**`, `build/**`, `*.html`
   - `max_file_lines`: 400 for Pike (longest existing is 973)
   - `max_function_lines`: 60

## Consequences

### Positive

- Standardized AI agent behavior across the project
- Automatic quality gates reduce review burden
- Architecture documentation improves onboarding
- Conventional commits improve changelog generation

### Negative

- Learning curve for contributors unfamiliar with OMP
- Additional CI workflows to maintain
- Template upgrade path to manage

### Neutral

- Some template files skipped (greenfield-specific items)

## Alternatives Considered

### 1. No Template Adoption
- **Pro**: No change to current workflow
- **Con**: Continue without standardized agent configuration, quality gates, or documentation

### 2. Custom Implementation
- **Pro**: Full control over what's included
- **Con**: More work, less tested, no upgrade path

### 3. Partial Adoption
- **Pro**: Start small, add more later
- **Con**: Inconsistent tooling, migration burden later

## References

- [ai-project-template](https://github.com/nicoqiujs/ai-project-template) v0.7.0
- [OMP Documentation](https://oh-my-pi.dev/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
