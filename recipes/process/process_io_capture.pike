#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Capturing Process Output
//! Demonstrates gathering stdout and stderr from spawned processes

int main() {
    // Example 1: Capture output using Process.run
    write("=== Example 1: Process.run ===\n");

    mapping result = Process.run(({
        "ls", "-la", "/nonexistent"  // This will generate error output
    }));

    write("STDOUT:\n%s\n", result->stdout || "(empty)");
    write("STDERR:\n%s\n", result->stderr);
    write("Exit code: %d\n\n", result->exitcode);

    // Example 2: Manual pipe handling
    write("=== Example 2: Manual pipe handling ===\n");

    Stdio.File stdout_pipe = Stdio.File();
    Stdio.File stderr_pipe = Stdio.File();

    Process.create_process proc = Process.create_process(
        ({"echo", "Hello through manual pipe"}),
        ([
            "stdout": stdout_pipe->pipe(),
            "stderr": stderr_pipe->pipe()
        ])
    );

    // Close write ends
    stdout_pipe->close();
    stderr_pipe->close();

    // Read from pipes
    string stdout_data = stdout_pipe->read();
    string stderr_data = stderr_pipe->read();

    write("Captured stdout: %s", stdout_data);
    write("Captured stderr: %s", stderr_data);

    int exit_code = proc->wait();
    write("Exit code: %d\n", exit_code);

    return 0;
}
