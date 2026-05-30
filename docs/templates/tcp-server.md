---
id: tcp-server
title: TCP Server (Non-Blocking)
sidebar_label: TCP Server
---

# TCP Server — Non-Blocking Accept Loop

A complete, copy-paste-ready TCP server using `Stdio.Port` and non-blocking I/O. Handles multiple concurrent connections without threads — a single backend loop processes all reads and writes via callbacks.

## Why This Pattern?

- **No threading needed.** Pike's backend loop + non-blocking I/O handles hundreds of connections in a single thread.
- **Callback-driven.** Each connection gets `read_cb`, `write_cb`, and `close_cb` — no polling, no select() gymnastics.
- **Clean connection lifecycle.** Per-connection state is encapsulated in a class instance.

## The Server

```pike
// tcp_server.pike — Non-blocking TCP server.
//
// Listens on a port. Each accepted connection gets its own Conn object
// with non-blocking callbacks. Data received is echoed back (replace
// the echo logic with your protocol).

#define PORT 8080
#define HOST "127.0.0.1"

int connections_total = 0;

class Conn
{
    Stdio.File fd;
    string peer;
    string write_buf = "";

    void create(Stdio.File f)
    {
        fd = f;
        peer = sprintf("%s:%d", @fd->query_address() / " ");
        werror("[server] connect from %s\n", peer);
        fd->set_nonblocking(read_cb, write_cb, close_cb);
    }

    void read_cb(mixed _, string data)
    {
        // Replace with your protocol parser.
        werror("[%s] received %d bytes\n", peer, sizeof(data));

        // Echo back with a prompt.
        write_buf += sprintf("You sent: %s> ", data);
        fd->set_nonblocking(read_cb, write_cb, close_cb);
    }

    void write_cb(mixed _)
    {
        int written = fd->write(write_buf);
        if (written < 0) {
            // OS error (EPIPE, ECONNRESET, etc.) — close connection.
            fd->close();
            return;
        }
        if (written > 0)
            write_buf = write_buf[written..];
        if (!sizeof(write_buf))
            fd->set_nonblocking(read_cb, 0, close_cb);
    }

    void close_cb(mixed _)
    {
        if (fd->errno())
            werror("[server] error from %s: %s\n", peer, strerror(fd->errno()));
        else
            werror("[server] disconnect from %s\n", peer);
        fd->close();
    }
}

Stdio.Port port;

void accept_cb(mixed _)
{
    Stdio.File conn = port->accept();
    if (conn) {
        connections_total++;
        Conn(conn);
    }
}

int main()
{
    port = Stdio.Port();
    if (!port->bind(PORT, accept_cb, HOST))
        error(sprintf("bind failed: %s\n", strerror(port->errno())));

    werror("[server] listening on %s:%d\n", HOST, PORT);
    return -1; // stay alive
}
```

## The Client

```pike
// tcp_client.pike — Simple TCP client for testing.

int main()
{
    Stdio.File sock = Stdio.File();
    if (!sock->connect("127.0.0.1", 8080)) {
        werror("connect failed\n");
        return 1;
    }

    sock->write("Hello from client\n");

    // Read until the server closes or we get a response.
    string response = sock->read(1024, 1);
    write("Server said: %s", response || "(nothing)\n");

    sock->close();
    return 0;
}
```

## Line-Based Protocol Variant

If your protocol is line-based (HTTP-like, Redis-like), use `set_read_callback` with `f->line_reader()`:

```pike
void read_cb(mixed _, string data)
{
    // Buffer and split on newlines.
    buf += data;
    while (has_value(buf, "\n")) {
        int pos = search(buf, "\n");
        string line = buf[..pos - 1];
        buf = buf[pos + 1..];

        // Dispatch on the line.
        handle_line(line);
    }
}

void handle_line(string line)
{
    if (line == "QUIT") {
        write_buf = "Bye!\n";
        fd->set_nonblocking(read_cb, write_cb, close_cb);
        return;
    }
    // ... your protocol here
    write_buf += sprintf("OK: %s\n", line);
    fd->set_nonblocking(read_cb, write_cb, close_cb);
}
```

## Running

```bash
# Terminal 1: start server
pike tcp_server.pike

# Terminal 2: connect with client
pike tcp_client.pike

# Or use telnet/netcat for ad-hoc testing
nc 127.0.0.1 8080
```

---

## SSL/TLS Variant

Wrap accepted connections with `SSL.Context`:

```pike
#include <ssl.h>

SSL.Context ctx;

void create_ssl_context()
{
    ctx = SSL.Context();
    ctx->load_certificates("server_cert.pem");
    ctx->load_private_keys("server_key.pem");
}

void accept_cb(mixed _)
{
    Stdio.File raw = port->accept();
    if (!raw) return;

    SSL.File secure = SSL.File(raw, ctx);
    if (!secure->connect()) {
        werror("[server] TLS handshake failed\n");
        return;
    }

    // Now use secure just like a regular non-blocking File.
    Conn(secure);
}
```

---

:::tip Port options
`port->bind(PORT, accept_cb, HOST)` binds to a specific interface. Use `"0.0.0.0"` for all interfaces, or `"127.0.0.1"` for loopback only. For local IPC, prefer a Unix-domain socket — see the [IPC Daemon](/docs/templates/ipc-daemon) template.
:::

:::warning Resource limits
A non-blocking server has no built-in connection limit. Add a guard in `accept_cb`:
```pike
if (connections_total > MAX_CONNECTIONS) {
    Stdio.File reject = port->accept();
    reject->write("503 Too many connections\n");
    reject->close();
    return;
}
```
:::
