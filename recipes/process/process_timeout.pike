#!/usr/bin/env pike
#pragma strict_vars
#pragma strict_types

//! Recipe: Process with Timeout
//! Demonstrates creating processes with timeout handling using Process.Process class

int main() {
    // Create a process with timeout callback
    Process.Process proc = Process.Process(
        ({"sleep", "30"}),  // Long-running process
        ([
            "timeout": 2,  // 2 second timeout
            "timeout_callback": lambda(Process.Process p) {
                write("\n[TIMEOUT] Process exceeded time limit!\n");
                write("Process will be terminated automatically.\n");
            }
        ])
    );

    write("Process started with 2 second timeout...\n");
    write("Waiting for process completion...\n");

    int exit_code = proc->wait();
    write("\nProcess exit code: %d\n", exit_code);

    return 0;
}
