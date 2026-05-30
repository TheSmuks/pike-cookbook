---
id: ipc-daemon
title: IPC Daemon (encode_value + %4H framing)
sidebar_label: IPC Daemon
---

# IPC Daemon — Fire-and-Forget Job Queue

A complete, copy-paste-ready pattern for sending `array(mapping(string:string))` jobs from one Pike process to a background worker daemon over a Unix-domain socket. Uses `encode_value`/`decode_value` for lossless Pike-to-Pike serialisation and `%4H` framing for stream socket message boundaries.

## Why This Pattern?

- **Lossless types.** `encode_value` preserves mappings, arrays, floats, integer keys, multisets, even circular structures — JSON can't do that round-trip.
- **Near-instant send.** The write lands in the kernel buffer and returns immediately. The sender goes back to work.
- **Backpressure built in.** If the daemon is down or slow, `submit()` returns 0 and the caller decides what to do (spool, log, return 503).
- **Process isolation.** The worker is a separate OS process — if it crashes, the sender stays up.

## Architecture

```
  Sender                           Worker daemon
  ┌──────────┐    Unix socket      ┌─────────────────┐
  │ encode_  │ ──────────────────► │ read_cb →       │
  │ value()  │  %4H framed bytes   │ decode_value()  │
  │ sprintf  │                     │       ↓         │
  │ write()  │                     │ Thread.Queue    │
  │ return 1 │                     │       ↓         │
  └──────────┘                     │ worker threads  │
                                   └─────────────────┘
```

---

## The Worker (Daemon)

Save as `worker.pike`. Listens on a Unix-domain socket, decodes frames, pushes jobs to a `Thread.Queue`, and drains them with a pool of worker threads.

```pike
// worker.pike — Background job daemon.
//
// Framing: sprintf("%4H", encode_value(payload)) on the sender side.
// %4H writes a 4-byte big-endian length header followed by the raw bytes.
// sscanf(buf, "%4H%s", blob, rest) peels exactly one complete frame off
// the buffer, leaving any partial tail for the next read_cb invocation.

#define SOCKET_PATH "/tmp/pike_job_sock"
#define NUM_WORKERS 4

Thread.Queue jobs = Thread.Queue();

// ---------------------------------------------------------------------------
// Worker threads
// ---------------------------------------------------------------------------

void worker_thread()
{
    while (true) {
        // read() blocks until a job is available — no polling.
        array(mapping(string:string)) batch = jobs->read();
        if (mixed e = catch { do_job(batch); })
            werror("[worker] job failed: %O\n", e);
    }
}

void do_job(array(mapping(string:string)) batch)
{
    // Replace with real work (image resize, e-mail dispatch, ...).
    werror("[worker] processing batch of %d items:\n", sizeof(batch));
    foreach (batch; int i; mapping(string:string) item)
        werror("  [%d] %O\n", i, item);
}

// ---------------------------------------------------------------------------
// Connection handling — one Conn per accepted client
// ---------------------------------------------------------------------------

class Conn
{
    Stdio.File fd;
    string buf = "";

    void create(Stdio.File f)
    {
        fd = f;
        fd->set_nonblocking(read_cb, 0, close_cb);
    }

    void read_cb(mixed _, string data)
    {
        buf += data;

        // Drain every complete frame currently in the buffer.
        string blob, rest;
        while (sscanf(buf, "%4H%s", blob, rest) == 2) {
            buf = rest;
            if (mixed e = catch {
                mixed decoded = decode_value(blob);
                if (!arrayp(decoded))
                    error(sprintf("expected array, got %O\n", decoded));
                jobs->write(decoded);
            }) {
                werror("[conn] bad frame: %O\n", e);
            }
        }
        // Partial tail stays in buf for the next read_cb.
    }

    void close_cb(mixed _)
    {
        if (fd->errno())
            werror("[conn] error: %s\n", strerror(fd->errno()));
        fd->close();
    }
}

// ---------------------------------------------------------------------------
// Accept loop
// ---------------------------------------------------------------------------

Stdio.Port port;

void accept_cb(mixed _)
{
    Stdio.File conn = port->accept();
    if (conn)
        Conn(conn);
}

// ---------------------------------------------------------------------------
// Entry
// ---------------------------------------------------------------------------

int main()
{
    // Clean up stale socket from a previous run.
    rm(SOCKET_PATH);

    for (int i = 0; i < NUM_WORKERS; i++)
        thread_create(worker_thread);

    port = Stdio.Port();
    if (!port->bind_unix(SOCKET_PATH, accept_cb))
        error(sprintf("bind: %s\n", strerror(port->errno())));

    werror("[worker] listening on %s\n", SOCKET_PATH);
    return -1; // stay alive — backend loop
}
```

---

## The Sender (Client)

Save as `sender.pike`. Opens one persistent connection to the daemon, frames the payload, writes it, returns immediately. Thread-safe via `Thread.Mutex`.

```pike
// sender.pike — Fire-and-forget job submitter.
//
// The write is synchronous but near-instant for small payloads — the kernel
// buffers it and the call returns immediately.  If the write fails (broken
// pipe, daemon down) the connection is dropped and submit() returns 0 so the
// caller can decide what to do.

#define SOCKET_PATH "/tmp/pike_job_sock"

Stdio.File conn;
Thread.Mutex sender_mutex = Thread.Mutex();

// Returns 1 on success, 0 on failure.
int submit(array(mapping(string:string)) batch)
{
    Thread.MutexKey key = sender_mutex->lock();

    if (!conn || !conn->is_open()) {
        conn = Stdio.File();
        if (!conn->connect_unix(SOCKET_PATH)) {
            conn = 0;
            key = 0;
            return 0;
        }
    }

    string frame = sprintf("%4H", encode_value(batch));
    int written = conn->write(frame);

    if (written != sizeof(frame)) {
        conn->close();
        conn = 0;
        key = 0;
        return 0;
    }

    key = 0;
    return 1;
}

// ---------------------------------------------------------------------------
// Demo: send a batch and exit.
// ---------------------------------------------------------------------------

int main()
{
    array(mapping(string:string)) batch = ({
        ([ "id": "1", "action": "resize",  "file": "/tmp/img1.png" ]),
        ([ "id": "2", "action": "compress", "file": "/tmp/log.txt"  ]),
    });

    if (!submit(batch)) {
        werror("[sender] failed — is the worker running?\n");
        return 1;
    }

    werror("[sender] submitted %d items\n", sizeof(batch));
    return 0;
}
```

---

## Test Driver

Save as `run_test.pike`. Starts the worker as a subprocess, waits for the socket, runs the sender, prints output.

```pike
// run_test.pike — End-to-end test.

#define SOCKET_PATH "/tmp/pike_job_sock"

int main()
{
    rm(SOCKET_PATH);

    Process.create_process worker =
        Process.create_process(
            ({ "pike", combine_path(__FILE__, "..", "worker.pike") }),
            ([ "stdout": Stdio.stderr, "stderr": Stdio.stderr ])
        );

    // Wait for the socket file to appear.
    int waited = 0;
    while (!file_stat(SOCKET_PATH) && waited < 50) {
        sleep(0.1);
        waited++;
    }
    if (!file_stat(SOCKET_PATH)) {
        werror("[test] worker did not start\n");
        worker->kill(9);
        return 1;
    }

    // Run the sender.
    int rc =
        Process.create_process(
            ({ "pike", combine_path(__FILE__, "..", "sender.pike") }),
            ([ "stdout": Stdio.stderr, "stderr": Stdio.stderr ])
        )->wait();

    sleep(0.3); // let worker flush
    worker->kill(15);
    sleep(0.1);
    if (worker->status() == 0)
        worker->kill(9);

    rm(SOCKET_PATH);
    return rc;
}
```

---

## Safety Notes

:::danger decode_value is unsafe on untrusted input
It can instantiate arbitrary objects. This is acceptable here because both ends are your code over a loopback Unix-domain socket with filesystem permissions. **Never point it at attacker-controlled input.** If that guarantee weakens, switch to JSON and accept the type flattening.
:::

:::warning Concurrent writers corrupt framing
If multiple threads call `submit()` on the same shared connection, frames can interleave. The sender uses a `Thread.Mutex`. In a multi-threaded server (Roxen), the cleaner alternative is an in-process `Thread.Queue` with a single writer thread owning the socket.
:::

:::tip Reuse the connection
Connect-per-job adds latency and FD churn. The sender keeps one persistent connection and only reconnects on failure.
:::

---

## When to Skip the Socket

If the "other process" doesn't need to be separate — if a worker **thread** in the same daemon would do — then all of the above collapses. `Thread.Queue` passes the mapping **by reference**: `jobs->write(job)` in the handler, `jobs->read()` in the worker thread. No `encode_value`, no framing, no socket. You only need the separate process if you specifically want crash isolation, independent restarts, or different privileges.
