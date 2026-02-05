# Pike 8.0 API Migration Report

**Date:** 2026-02-05
**Pike Version:** 8.1116
**Files Fixed:** 33
**Total Lines Changed:** 544 insertions, 306 deletions

---

## Summary

All Pike examples in the pike-cookbook repository have been reviewed and migrated to Pike 8.0 API compatibility. The validation covered:

- **34 web automation examples** - 13 fixes applied
- **22 process recipe examples** - 9 fixes applied
- **8 pleac-pike UI examples** - 6 fixes applied
- **6 database recipe examples** - 5 fixes applied

**Total: 70+ example files validated, 33 files fixed**

---

## Common Pike 8.0 API Changes

### 1. String Operations
| Old API | New API |
|---------|---------|
| `String.trim_whitespace(s)` | `s - " " - "\t" - "\n" - "\r"` or `String.trim(s)` |

### 2. Process/Time Operations
| Old API | New API |
|---------|---------|
| `usleep(n)` | `System.usleep(n)` |
| `fork()` returns `int` | `fork()` returns `Process.Fork` object |
| `waitpid(pid)` | Use `proc->wait()` on process objects |
| `Process.create_process("cmd arg")` | `Process.create_process({"cmd", "arg"})` |

### 3. Stdio/Terminal Operations
| Old API | New API |
|---------|---------|
| `Stdio.isatty(fd)` | `Stdio.stdin->isatty()` |
| `STDIN`, `STDOUT` | `Stdio.stdin`, `Stdio.stdout` |
| `write("fmt", args...)` | `write(sprintf("fmt", args...))` |
| `Stdio.isFile(path)` | `file_stat(path) && stat->isreg` |

### 4. Type System
| Old API | New API |
|---------|---------|
| `static` keyword | `protected` keyword |
| `volatile int` | `int` (volatile not supported) |
| `foreach (arr, Type var)` | `foreach (arr, int i, Type var)` |

### 5. Database
| Old API | New API |
|---------|---------|
| `query()` always returns array | Returns `int` for INSERT/UPDATE/DELETE, `array` for SELECT |

---

## Files Fixed by Category

### Web Automation (13 files)

| File | Issue |
|------|-------|
| `advanced_css_selectors.pike` | String.trim_whitespace(), static → protected |
| `api_rate_limit_handler.pike` | usleep() → System.usleep(), added missing classes |
| `async_http_requests.pike` | Lambda expression syntax |
| `basic_auth.pike` | Added CookieJar class definition |
| `cookie_jar.pike` | trim_whitespace(), get_url_host() |
| `handle_redirects.pike` | sync_request() argument types |
| `http_with_headers.pike` | async_request() argument types |
| `multipart_upload.pike` | Stdio.isFile() → file_stat() |
| `retry_strategy.pike` | RetryConfig type annotations |
| `session_persistence.pike` | Added CookieJar class definition |
| `web_crawler.pike` | Syntax errors, set() → multiset() |
| `xpath_queries.pike` | Reserved word 'class' → 'class_name' |
| `xpath_advanced.pike` | static → protected |

### Process Recipes (9 files)

| File | Issue |
|------|-------|
| `process_io_capture.pike` | Pipe closure logic |
| `process_io_streams.pike` | Pipe write end handling |
| `process_stdin_write.pike` | Pipe write end handling |
| `popen_filter.pike` | Pipe closure logic |
| `process_group.pike` | fork() returns Process.Fork object |
| `process_status.pike` | Array arguments for Process.create_process() |
| `signal_handler.pike` | Removed volatile keyword |
| `ipc_fifo.pike` | Array arguments for Process.create_process() |
| `daemon_double_fork.pike` | fork() object handling |

### Database Recipes (5 files)

| File | Issue |
|------|-------|
| `async_operations.pike` | Extra closing parenthesis |
| `best_practices.pike` | Invalid search syntax |
| `basic_queries.pike` | query() return type handling |
| `advanced_operations.pike` | Sql.sql_result indexing |
| `dbconnection.pike` | Added null checks |

### UI Examples (6 files)

| File | Issue |
|------|-------|
| `readline_demo.pike` | isatty(), write() → sprintf() |
| `password_input.pike` | isatty(), Constants.System.ECHO |
| `clear_screen.pike` | foreach arrow syntax |
| `event_demo.pike` | Rewritten to use call_out() |
| `parse_args.pike` | foreach type annotation |
| `terminal_test.pike` | isatty() call |

---

## Verification

All fixed files have been tested with `pike <file>` to ensure:
- ✅ No syntax errors
- ✅ No compile errors
- ✅ Proper Pike 8.0 API usage
- ✅ CI pipeline passes

---

## Commit

```
fix: migrate all Pike examples to Pike 8.0 API compatibility

Commit: eda21fd
Branch: main
Date: 2026-02-05
```
