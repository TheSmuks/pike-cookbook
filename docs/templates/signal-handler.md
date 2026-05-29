---
id: signal-handler
title: Signal-Handling Daemon
sidebar_label: Signal-Handling Daemon
---

# Signal-Handling Daemon — Graceful Shutdown

A complete, copy-paste-ready daemon that handles SIGTERM and SIGINT for clean shutdown, SIGCHLD for child process reaping, and SIGHUP for config reload. Demonstrates Pike's `signal()` API and proper daemon lifecycle.

## Why This Pattern?

- **No orphaned resources.** A daemon that ignores SIGTERM leaves sockets, temp files, and child processes behind.
- **Proper child reaping.** Without SIGCHLD handling, child processes become zombies.
- **Reload without restart.** SIGHUP lets you reload configuration without dropping the process.

## The Daemon

```pike
// signal_daemon.pike — Daemon with graceful signal handling.
//
// Handles SIGTERM/SIGINT for clean shutdown, SIGCHLD for child reaping,
// and SIGHUP for config reload. Demonstrates proper daemon lifecycle.

#define SOCKET_PATH "/tmp/signal_daemon.sock"
#define PID_FILE    "/tmp/signal_daemon.pid"

int running = 1;
Stdio.Port port;
mapping config = ([]);

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

mapping load_config()
{
    // Replace with real config loading (file, database, environment).
    return ([
        "max_workers": 4,
        "log_level": "info",
        "socket_path": SOCKET_PATH,
    ]);
}

// ---------------------------------------------------------------------------
// Signal handlers
// ---------------------------------------------------------------------------

void sigterm_handler(int sig)
{
    werror("[daemon] received SIGTERM — shutting down\n");
    running = 0;
}

void sigint_handler(int sig)
{
    werror("[daemon] received SIGINT — shutting down\n");
    running = 0;
}

void sighup_handler(int sig)
{
    werror("[daemon] received SIGHUP — reloading config\n");
    config = load_config();
    werror("[daemon] config reloaded: %O\n", config);
}

void sigchld_handler(int sig)
{
    // Reap all dead children to prevent zombies.
    while (true) {
        int status;
        int pid = waitpid(-1, status, 1); // WNOHANG = 1
        if (pid <= 0) break;
        werror("[daemon] reaped child %d (status %d)\n", pid, status);
    }
}

// ---------------------------------------------------------------------------
// Accept loop
// ---------------------------------------------------------------------------

class Conn
{
    Stdio.File fd;
    string write_buf = "";
    void create(Stdio.File f) { fd = f; fd->set_nonblocking(read_cb, 0, close_cb); }

    void read_cb(mixed _, string data)
    {
        werror("[conn] received: %O\n", String.trim_whites(data));
        write_buf = "OK\n";
        fd->set_nonblocking(read_cb, write_cb, close_cb);
    }

    void write_cb(mixed _)
    {
        int written = fd->write(write_buf);
        if (written < 0) { fd->close(); return; }
        if (written > 0)
            write_buf = write_buf[written..];
        if (!sizeof(write_buf))
            fd->set_nonblocking(read_cb, 0, close_cb);
    }

    void close_cb(mixed _)
    {
        if (fd->errno())
            werror("[conn] error: %s\n", strerror(fd->errno()));
        fd->close();
    }
}

void accept_cb(mixed _)
{
    Stdio.File conn = port->accept();
    if (conn) Conn(conn);
}

// ---------------------------------------------------------------------------
// Cleanup
// ---------------------------------------------------------------------------

void cleanup()
{
    werror("[daemon] cleaning up\n");
    if (port) port->close();
    rm(SOCKET_PATH);
    rm(PID_FILE);
    werror("[daemon] done\n");
}

// ---------------------------------------------------------------------------
// Entry
// ---------------------------------------------------------------------------

int main()
{
    config = load_config();

    // Install signal handlers.
    signal(signum("TERM"), sigterm_handler);
    signal(signum("INT"),  sigint_handler);
    signal(signum("HUP"),  sighup_handler);
    signal(signum("CHLD"), sigchld_handler);

    // Write PID file.
    Stdio.write_file(PID_FILE, sprintf("%d\n", getpid()));

    // Bind socket.
    rm(SOCKET_PATH);
    port = Stdio.Port();
    if (!port->bind_unix(SOCKET_PATH, accept_cb))
        error(sprintf("bind: %s\n", strerror(port->errno())));

    werror("[daemon] pid %d, listening on %s\n", getpid(), SOCKET_PATH);

    // Main loop — keeps running until a signal sets running = 0.
    // The backend handles I/O callbacks; we just poll the flag.
    while (running) {
        sleep(0.1);
    }

    cleanup();
    return 0;
}
```

## Managing the Daemon

```bash
# Start in background
pike signal_daemon.pike &

# Check it's running
cat /tmp/signal_daemon.pid
ps -p $(cat /tmp/signal_daemon.pid)

# Reload config
kill -HUP $(cat /tmp/signal_daemon.pid)

# Graceful shutdown
kill -TERM $(cat /tmp/signal_daemon.pid)

# Force kill (if graceful shutdown hangs)
kill -9 $(cat /tmp/signal_daemon.pid)
```

## Double-Fork Daemonization

For a proper background daemon that detaches from the terminal:

```pike
void daemonize()
{
    // First fork — parent exits, child continues.
    if (fork()) exit(0);

    // Create a new session.
    setsid();

    // Second fork — ensures the process is not a session leader.
    if (fork()) exit(0);

    // Close standard file descriptors.
    Stdio.stdin->close();
    Stdio.stdout->close();
    Stdio.stderr->close();

    // Redirect stdin/stdout/stderr to /dev/null.
    Stdio.File null = Stdio.File("/dev/null", "rw");
    null->dup2(Stdio.stdin);
    null->dup2(Stdio.stdout);
    null->dup2(Stdio.stderr);

    // Change working directory to root.
    cd("/");

    // Reset umask.
    umask(0);
}
```

Call `daemonize()` at the start of `main()` before binding the socket.

---

## Available Signals

| Signal  | Default Action | Typical Use |
|---------|---------------|-------------|
| SIGTERM | Terminate     | Graceful shutdown |
| SIGINT  | Terminate     | Ctrl-C in foreground |
| SIGHUP  | Terminate     | Config reload |
| SIGCHLD | Ignore        | Child process reaping |
| SIGUSR1 | Terminate     | Custom (e.g. debug toggle) |
| SIGUSR2 | Terminate     | Custom (e.g. rotate logs) |
| SIGPIPE | Terminate     | Ignored in most daemons |

---

:::tip Signal handlers are deferred, not raw POSIX
Pike's `signal()` does NOT install a raw POSIX signal handler. It sets a flag that the Pike backend picks up and dispatches as a normal function call in the interpreter context. This means `werror()`, `sprintf()`, memory allocation, and other Pike operations are safe inside the handler. You still want to keep handlers short for responsiveness, but there is no risk of crashing the runtime with I/O calls.
:::

:::tip Combine with the IPC Daemon pattern
If your daemon accepts jobs over a socket, combine this signal-handling skeleton with the [IPC Daemon](/docs/templates/ipc-daemon) template for a complete production-ready daemon.
:::
