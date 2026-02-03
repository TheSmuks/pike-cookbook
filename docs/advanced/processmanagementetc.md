---
id: processmanagementetc
title: Process Management and Communication
sidebar_label: Process Management and Communication
---

## Gathering Output from a Program

```pike
// Gather output using Process.run (Pike 8 modern API)
#pragma strict_types

#include <process.h>

mapping result = Process.run(({"ls", "-l", "/tmp"}));

write("Exit code: %d\n", result->exitcode);
write("Output:\n%s\n", result->stdout);
write("Errors:\n%s\n", result->stderr);
```

## Running Another Program

```pike
// Run a command using Process.create_process (Pike 8)
#pragma strict_types

#include <process.h>

// Method 1: Create and wait
Process.create_process proc = Process.create_process(({"echo", "Hello"}));
int exit_code = proc->wait();
write("Exit code: %d\n", exit_code);

// Method 2: Use Process.Process with callbacks
Process.Process p = Process.Process(({"sleep", "5"}"), ([
    "timeout": 10,
    "timeout_callback": lambda(Process.Process proc) {
        write("Process timed out!\n");
    }
]));

p->wait();
```

## Replacing the Current Program with a Different One

```pike
// Replace current process using Process.exec (Pike 8)
#pragma strict_types

#include <process.h>

#if constant(exece)
// Exec replaces the current process image
Process.exec("/bin/ls", "-l", "/tmp");

// This line is never reached if exec succeeds
werror("Exec failed: %s\n", strerror(errno()));
#else
write("exec not available on this system\n");
#endif
```

## Reading or Writing to Another Program

```pike
// Bidirectional communication with a process (Pike 8)
#pragma strict_types

#include <process.h>

// Create pipes for stdin/stdout
Stdio.File stdin_pipe = Stdio.File();
Stdio.File stdout_pipe = Stdio.File();

Process.create_process proc = Process.create_process(
    ({"cat", "-n"}),
    ([
        "stdin": stdin_pipe->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
        "stdout": stdout_pipe->pipe()
    ])
);

// Close unused ends
stdin_pipe->close();

// Write to process
stdin_pipe->write("Line 1\nLine 2\nLine 3\n");
stdin_pipe->close();

// Read response
stdout_pipe->close();
string output = stdout_pipe->read();
write("Output:\n%s", output);

proc->wait();
```

## Filtering Your Own Output

```pike
// Filter output through external processes (Pike 8)
#pragma strict_types

#include <process.h>

string text = "zebra\napple\nbanana\napple\ncherry\n";

// Sort the output
mapping sorted = Process.run(
    ({"sort"}),
    (["stdin": text])
);

// Get unique lines
mapping unique = Process.run(
    ({"uniq"}),
    (["stdin": sorted->stdout])
);

write("After sort | uniq:\n%s", unique->stdout);
```

## Preprocessing Input

```pike
// Preprocess input through awk (Pike 8)
#pragma strict_types

#include <process.h>

string data = "alice:30\nbob:25\ncharlie:35\n";

mapping result = Process.run(
    ({"awk", "-F:", "{print $1, $2}"}),
    (["stdin": data])
);

write("Processed output:\n%s", result->stdout);
```

## Reading STDERR from a Program

```pike
// Capture stderr separately (Pike 8)
#pragma strict_types

#include <process.h>

mapping result = Process.run(({
    "ls", "/nonexistent"
}));

write("Exit code: %d\n", result->exitcode);
write("STDERR:\n%s\n", result->stderr);

// Manual pipe handling for stderr
Stdio.File stderr_pipe = Stdio.File();

Process.create_process proc = Process.create_process(
    ({"ls", "/nonexistent"}),
    (["stderr": stderr_pipe->pipe()])
);

stderr_pipe->close();
string errors = stderr_pipe->read();
write("Errors: %s\n", errors);
```

## Controlling Input and Output of Another Program

```pike
// Full control of stdin, stdout, stderr (Pike 8)
#pragma strict_types

#include <process.h>

Stdio.File stdin_p = Stdio.File();
Stdio.File stdout_p = Stdio.File();
Stdio.File stderr_p = Stdio.File();

Process.create_process proc = Process.create_process(
    ({"cat", "-n"}),
    ([
        "stdin": stdin_p->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
        "stdout": stdout_p->pipe(),
        "stderr": stderr_p->pipe()
    ])
);

// Write to stdin
stdin_p->write("test data\n");
stdin_p->close();

// Read stdout and stderr
stdout_p->close();
stderr_p->close();

string out = stdout_p->read();
string err = stderr_p->read();

proc->wait();
```

## Controlling the Input, Output, and Error of Another Program

```pike
// Using Process.run for simple cases (Pike 8)
#pragma strict_types

#include <process.h>

mapping result = Process.run(
    ({"awk", "{print $1}"}),
    ([
        "stdin": "apple:1\nbanana:2\n",
        "cwd": "/tmp"
    ])
);

write("Output: %s", result->stdout);
```

## Communicating Between Related Processes

```pike
// Parent-child communication via pipes (Pike 8)
#pragma strict_types

#include <process.h>

Stdio.File parent_rd = Stdio.File();
Stdio.File parent_wr = Stdio.File();
Stdio.File child_rd = Stdio.File();
Stdio.File child_wr = Stdio.File();

Process.create_process child = Process.create_process(
    ({"cat", "-e"}),
    ([
        "stdin": child_rd->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
        "stdout": child_wr->pipe()
    ])
);

child_rd->close();
child_wr->close();

// Send data to child
parent_wr->write("Message from parent\n");
parent_wr->close();

// Read response
parent_rd->close();
string response = parent_rd->read();
write("Child response:\n%s", response);

child->wait();
```

## Making a Process Look Like a File with Named Pipes

```pike
// Named pipes (FIFOs) for IPC (Pike 8)
#pragma strict_types

#include <process.h>

string fifo_path = "/tmp/pike_fifo";

// Create FIFO
Process.create_process mkfifo = Process.create_process(({"mkfifo", fifo_path}));
mkfifo->wait();

// Writer process
Process.create_process writer = Process.create_process(
    ({"sh", "-c", "echo 'Hello through FIFO' > " + fifo_path})
);

// Reader process
mapping result = Process.run(({"cat", fifo_path}));
write("FIFO data: %s", result->stdout);

writer->wait();

// Cleanup
Process.create_process({"rm", "-f", fifo_path})->wait();
```

## Sharing Variables in Different Processes

```pike
// Shared state via file (Pike 8)
#pragma strict_types

string state_file = "/tmp/pike_shared_state.txt";

// Writer process
mapping state = ([
    "counter": 42,
    "timestamp": time()
]);

Stdio.write_file(state_file, encode_value(state));

// Reader process
string data = Stdio.read_file(state_file);
mapping loaded_state = mixederr = catch {
    return decode_value(data);
};

if (loaded_state) {
    write("Counter: %d\n", loaded_state->counter);
    write("Timestamp: %s\n", ctime(loaded_state->timestamp));
}
```

## Listing Available Signals

```pike
// List available signals (Pike 8)
#pragma strict_types

array(string) signals = ({
    "SIGHUP", "SIGINT", "SIGQUIT", "SIGILL", "SIGTRAP",
    "SIGABRT", "SIGBUS", "SIGFPE", "SIGKILL", "SIGUSR1",
    "SIGSEGV", "SIGUSR2", "SIGPIPE", "SIGALRM", "SIGTERM",
    "SIGCHLD", "SIGCONT", "SIGSTOP", "SIGTSTP"
});

write("Available signals:\n");
foreach(signals; int i; string sig) {
    int num = signum(sig);
    if (num > 0) {
        write("  %2d: %s\n", num, sig);
    }
}
```

## Sending a Signal

```pike
// Send signal to process (Pike 8)
#pragma strict_types

#include <process.h>

#if constant(kill)
// Create a long-running process
Process.create_process proc = Process.create_process(({"sleep", "30"}));
int pid = proc->pid();

// Wait a bit, then send SIGTERM
sleep(2);
proc->kill(signum("SIGTERM"));

// Wait for process to exit
int exit_code = proc->wait();
write("Process exited with code: %d\n", exit_code);
#else
write("kill() not available on this system\n");
#endif
```

## Installing a Signal Handler

```pike
// Signal handlers for graceful shutdown (Pike 8)
#pragma strict_types

volatile int shutdown_requested = 0;

void handle_sigint() {
    write("\n[INFO] SIGINT received. Shutting down...\n");
    shutdown_requested = 1;
}

#if constant(signal)
signal(signum("SIGINT"), handle_sigint);
signal(signum("SIGTERM"), handle_sigint);
#endif

while (!shutdown_requested) {
    write("Working...\n");
    sleep(1);
}

write("Cleanup complete.\n");
```

## Temporarily Overriding a Signal Handler

```pike
// Save and restore signal handler (Pike 8)
#pragma strict_types

#if constant(signal)
// Save current handler
function old_handler = signal(signum("SIGINT"), 0);

// Install temporary handler
void temp_handler() {
    write("Temporary handler\n");
}

signal(signum("SIGINT"), temp_handler);

// Do work...

// Restore original handler
signal(signum("SIGINT"), old_handler);
#endif
```

## Writing a Signal Handler

```pike
// Comprehensive signal handler (Pike 8)
#pragma strict_types

#if constant(signal)
volatile int signal_count = 0;

void signal_handler() {
    signal_count++;
    write("Signal received (count: %d)\n", signal_count);
}

void cleanup() {
    write("Performing cleanup...\n");
    // Close files, save state, etc.
}

// Install handlers
signal(signum("SIGTERM"), signal_handler);
signal(signum("SIGINT"), signal_handler);

// Main loop
while (signal_count < 3) {
    sleep(1);
}

cleanup();
#endif
```

## Catching Ctrl-C

```pike
// Catch Ctrl+C (SIGINT) (Pike 8)
#pragma strict_types

#if constant(signal)
volatile int interrupted = 0;

void handle_interrupt() {
    interrupted++;
    if (interrupted == 1) {
        write("\nPress Ctrl+C again to force exit.\n");
    } else {
        write("\nForced exit!\n");
        exit(1);
    }
}

signal(signum("SIGINT"), handle_interrupt);

write("Running... Press Ctrl+C to interrupt.\n");

while (!interrupted) {
    write(".\n");
    sleep(1);
}

write("Graceful shutdown complete.\n");
#endif
```

## Avoiding Zombie Processes

```pike
// Proper child reaping to avoid zombies (Pike 8)
#pragma strict_types

#include <process.h>

array(Process.create_process) children = ({});

// Spawn multiple children
for (int i = 0; i < 3; i++) {
    Process.create_process proc = Process.create_process(({
        "sleep", sprintf("%d", (i + 1) * 2)
    }));
    children += ({ proc });
}

// Wait for all children (reap zombies)
foreach(children; int i; Process.create_process proc) {
    int exit_code = proc->wait();
    write("Child %d exited with code: %d\n", i + 1, exit_code);
}

write("All children reaped. No zombies!\n");
```

## Blocking Signals

```pike
// Signal blocking for critical sections (Pike 8)
#pragma strict_types

#if constant(sigprocmask)
// Block signals during critical operation
int signal_block(int sig, int block) {
    return sigprocmask(sig, block);
}

// Block SIGINT during critical section
signal_block(signum("SIGINT"), 1);
write("Critical section - signals blocked\n");
// Do critical work...

// Unblock signals
signal_block(signum("SIGINT"), 0);
write("Signals unblocked\n");
#else
write("sigprocmask not available\n");
#endif
```

## Timing Out an Operation

```pike
// Process timeout with callback (Pike 8)
#pragma strict_types

#include <process.h>

Process.Process proc = Process.Process(
    ({"sleep", "30"}),
    ([
        "timeout": 2,
        "timeout_callback": lambda(Process.Process p) {
            write("\n[TIMEOUT] Process exceeded time limit!\n");
        }
    ])
);

write("Process started with 2 second timeout...\n");
int exit_code = proc->wait();
write("Exit code: %d\n", exit_code);
```

## Program: sigrand

```pike
// Signal-handling daemon example (Pike 8)
#pragma strict_types

#include <process.h>

volatile int running = 1;
volatile int count = 0;

void sigterm_handler() {
    write("\n[SIGTERM] Shutting down...\n");
    running = 0;
}

#if constant(signal)
signal(signum("SIGTERM"), sigterm_handler);
signal(signum("SIGINT"), sigterm_handler);
#endif

// Daemonize
Process.daemon(0, 0);

Stdio.File log = Stdio.File("/tmp/sigrand.log", "wac");

while (running) {
    int rand_num = random(100);
    log->write(sprintf("[%s] Random: %d\n", ctime(time()), rand_num));
    count++;
    sleep(1);
}

log->write(sprintf("Total iterations: %d\n", count));
log->close();
```