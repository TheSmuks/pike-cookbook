# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [Unreleased]

### Added

- `AGENTS.md` - Cross-agent configuration for Pike Cookbook development
- `ARCHITECTURE.md` - Pointer to detailed architecture documentation
- `docs/architecture.md` - Mermaid diagrams and component documentation
- `.template-version` - Template version tracking (0.7.0)
- `docs/decisions/001-template-adoption.md` - ADR for ai-project-template adoption
- `.omp/` - OMP agent and rule definitions
  - `.omp/agents/code-reviewer.md` - Pike + TypeScript code review guidelines
  - `.omp/agents/changelog-updater.md` - Automated changelog maintenance
  - `.omp/rules/conventional-commits.md` - Commit message rules
  - `.omp/rules/changelog-required.md` - Changelog enforcement rules
- `.github/workflows/commit-lint.yml` - Conventional commit validation
- `.github/workflows/changelog-check.yml` - Changelog entry enforcement
- `.github/workflows/blob-size-policy.yml` - File size limits in PRs

### Changed

- `CONTRIBUTING.md` - Added reference to AGENTS.md for full conventions

### Deprecated

- Nothing yet

### Removed

- Nothing yet

### Fixed

- Nothing yet

### Security

- Nothing yet

---

Previous versions can be found in [the GitHub releases](https://github.com/TheSmuks/pike-cookbook/releases).
