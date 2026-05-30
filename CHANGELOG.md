# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## [Unreleased]

### Added

- `docs/templates/` — copy-paste-ready scaffolds for common Pike patterns:
  - IPC Daemon (encode_value + %4H framing, fire-and-forget job queue)
  - TCP Server (non-blocking accept loop with callback-driven I/O)
  - Worker Pool (Thread.Queue + thread pool for concurrent processing)
  - Signal-Handling Daemon (graceful shutdown, SIGHUP reload, SIGCHLD reaping)
- Templates section in sidebar — prominent placement, not buried in Advanced
- Templates overview on the Introduction page

### Changed

- Sidebar categories are now individually collapsible — collapse what you don't need, keep what you do
- Network & Web ordering adjusted: Sockets first (most referenced), then CGI, Web Automation, Internet Services

### Fixed

- Templates validated against Pike 8.0.1116 source (Stdio.pmod, Thread.pmod): write_cb error handling, nonblocking write patterns, Thread.Queue timeout, signal handler safety
- 7 inaccuracies in existing cookbook pages: wrong error() signatures, fake API calls (Stdio.File->get_dir()), incorrect set_nonblocking() args, variable shadowing

### Removed

- 22 root-level junk files: conversion scripts (html_to_markdown*.py), AI session reports, test data, orphaned docs
- Test artifacts from examples/webautomation/ (crawl results, feed aggregation data, improvement report)
- Misnamed recipes/process/ipi_shared_memory.pike (content duplicated ipc_pipe.pike)

### Fixed

- Nothing yet

### Security

- Nothing yet

---

Previous versions can be found in [the GitHub releases](https://github.com/TheSmuks/pike-cookbook/releases).
