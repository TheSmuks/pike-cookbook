#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Capturing Process Output
//!
//! Demonstrates gathering stdout and stderr from spawned processes
//!
//! @example
//!   // Simple output capture with Process.run
//!   mapping result = Process.run(({"ls", "-la"}));
//!   write("STDOUT: %s\n", result->stdout);
//!   write("STDERR: %s\n", result->stderr);
//!   write("Exit code: %d\n", result->exitcode);
//!
//! @note
//!   Process.run provides the easiest way to capture output, but for
//!   long-running processes, manual pipe handling gives more control
//!
//! @seealso
//!   @[Process.run], @[Process.create_process], @[Stdio.File.pipe]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
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
