#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Process Status and Error Handling
//! Demonstrates comprehensive process status checking and error handling

int main() {
    write("=== Process Status Checking ===\n\n");

    // Example 1: Successful process
    write("Example 1: Successful process\n");
    Process.create_process proc1 = Process.create_process(({"echo", "Hello"}));

    int(-1..2) status = proc1->status();
    write("Status: %d\n", status);
    write("Exit code: %d\n", proc1->wait());
    write("Final status: %d\n\n", proc1->status());

    // Example 2: Failed command
    write("Example 2: Failed command (nonexistent)\n");
    Process.create_process proc2 = Process.create_process((
        "/nonexistent/command"
    ));

    mixed err = catch {
        int exit_code = proc2->wait();
        write("Exit code: %d\n", exit_code);
        write("Status: %d\n", proc2->status());
    };

    if (err) {
        write("Error caught: %s\n", describe_error(err));
    }

    write("\n");

    // Example 3: Process with timeout
    write("Example 3: Process with timeout callback\n");
    Process.Process proc3 = Process.Process(
        ({"sleep", "10"}),
        ([
            "timeout": 2,
            "timeout_callback": lambda(Process.Process p) {
                write("Timeout callback triggered for PID %d\n", p->pid());
            }
        ])
    );

    int exit3 = proc3->wait();
    write("Process 3 exit code: %d (likely killed)\n", exit3);
    write("Process 3 status: %d\n", proc3->status());

    // Example 4: Process.run error handling
    write("\nExample 4: Process.run with error checking\n");
    mapping result = Process.run(({"ls", "/nonexistent/path"}));

    write("Exit code: %d\n", result->exitcode);
    if (result->exitcode != 0) {
        write("STDERR:\n%s\n", result->stderr);
    }

    return 0;
}
