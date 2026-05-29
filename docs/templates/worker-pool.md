---
id: worker-pool
title: Worker Pool (Thread.Queue)
sidebar_label: Worker Pool
---

# Worker Pool — Thread.Queue + Thread Pool

A complete, copy-paste-ready pattern for distributing work across a pool of threads. Uses `Thread.Queue` for safe producer-consumer coordination — no locks needed at the application level.

## Why This Pattern?

- **No IPC overhead.** Everything runs in one process. Mappings pass by reference — no serialisation, no sockets.
- **Bounded concurrency.** Control exactly how many jobs run in parallel.
- **Simple.** `Thread.Queue` is thread-safe by design. `read()` blocks until a job arrives. No mutexes in your code.

## The Pattern

```pike
// worker_pool.pike — Generic worker pool.
//
// Producer threads push jobs onto a Thread.Queue. N worker threads
// drain the queue and process jobs concurrently.

#define NUM_WORKERS 4

Thread.Queue queue = Thread.Queue();
int jobs_completed = 0;
Thread.Mutex count_mutex = Thread.Mutex();

// ---------------------------------------------------------------------------
// Job definition — replace with your actual work
// ---------------------------------------------------------------------------

void process_job(mapping(string:string) job)
{
    werror("[worker %O] processing %O\n",
           Thread.this_thread()->get_id(), job["id"]);

    // Simulate work.
    sleep(random(100) / 100.0);

    werror("[worker %O] done with %O\n",
           Thread.this_thread()->get_id(), job["id"]);
}

// ---------------------------------------------------------------------------
// Worker thread
// ---------------------------------------------------------------------------

void worker_thread()
{
    while (true) {
        mixed job = queue->read(); // blocks until a job is available
        if (job == 0) return;      // sentinel: shut down

        if (mixed e = catch { process_job(job); })
            werror("[worker] job failed: %O\n", e);

        Thread.MutexKey key = count_mutex->lock();
        jobs_completed++;
        key = 0;
    }
}

// ---------------------------------------------------------------------------
// Main — start workers, enqueue jobs, wait
// ---------------------------------------------------------------------------

int main()
{
    // Start worker threads.
    array(Thread.Thread) workers = ({});
    for (int i = 0; i < NUM_WORKERS; i++)
        workers += ({ thread_create(worker_thread) });

    // Enqueue some jobs.
    for (int i = 0; i < 20; i++) {
        queue->write(([
            "id": sprintf("job-%d", i),
            "payload": sprintf("data for job %d", i),
        ]));
    }

    // Send shutdown sentinels — one per worker.
    for (int i = 0; i < NUM_WORKERS; i++)
        queue->write(0);

    // Wait for all workers to finish.
    workers->wait();

    werror("[main] all done — %d jobs completed\n", jobs_completed);
    return 0;
}
```

## Variants

### With Results Collection

If you need to collect results from workers, use a second `Thread.Queue`:

```pike
Thread.Queue results = Thread.Queue();

void worker_thread()
{
    while (true) {
        mixed job = queue->read();
        if (job == 0) return;

        mapping result = ([
            "id": job["id"],
            "status": "ok",
        ]);

        if (mixed e = catch {
            // Do the work and capture the result.
            result["output"] = do_work(job);
        }) {
            result["status"] = "error";
            result["error"] = sprintf("%O", e);
        }

        results->write(result);
    }
}

// In main, after enqueueing jobs:
array results_arr = ({});
for (int i = 0; i < num_jobs; i++)
    results_arr += ({ results->read() });
```

### With Priority

Use separate queues and have workers check the high-priority queue first:

```pike
Thread.Queue urgent = Thread.Queue();
Thread.Queue normal = Thread.Queue();

void worker_thread()
{
    while (true) {
        // Check urgent first (non-blocking).
        mixed job = urgent->try_read();
        if (!job) job = normal->read(); // blocks on normal queue
        if (job == 0) return;

        process_job(job);
    }
}
```

### With Timeouts on Wait

If you need to shut down idle workers after a timeout, use `read()` with a callback pattern instead:

```pike
// Worker exits if no job arrives within 30 seconds.
void worker_thread()
{
    while (true) {
        mixed job;
        if (mixed e = catch { job = queue->read(); }) {
            // Queue was destroyed or other error.
            return;
        }
        if (job == 0) return;
        process_job(job);
    }
}
```

---

## Scaling: When to Move to Processes

:::tip In-process is fastest
`Thread.Queue` + threads is the fastest option for Pike. No serialisation, no system calls for IPC, mappings shared by reference. Start here.
:::

:::warning The GIL
Pike threads run concurrently for I/O but share a global interpreter lock for CPU-bound Pike code. If your workers are CPU-heavy (image processing, crypto, compression), you won't get parallelism from threads — use the [IPC Daemon](/docs/templates/ipc-daemon) pattern instead to distribute across processes.
:::

Move to a separate process when:
- Workers are CPU-bound and you need true parallelism
- You want crash isolation (worker crash doesn't take down the producer)
- You need different privileges per worker
