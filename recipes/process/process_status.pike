#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Process Status and Error Handling
//!
//! Demonstrates comprehensive process status checking and error handling
//!
//! @example
//!   // Check process status
//!   Process.create_process proc = Process.create_process(({"echo", "test"}));
//!   int(-1..2) status = proc->status();
//!
//!   // Wait and check final status
//!   int exit_code = proc->wait();
//!   int final_status = proc->status();
//!
//! @note
//!   Status values: -1 (error), 0 (running), 1 (exited), 2 (signaled)
//!   Always check exit codes and stderr when using Process.run
//!
//! @seealso
//!   @[Process.create_process], @[Process.status], @[Process.wait]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    write("=== Process Status Checking ===\n\n");

    // Example 1: Successful process
    write("Example 1: Successful process\n");
    mixed err = catch {
        Process.create_process proc1 = Process.create_process(({"echo", "Hello"}));

        if (!proc1) {
            error("Failed to create process");
        }

        mixed status_raw = proc1->status();
        write("Status: %d\n", (int)status_raw);
        int exit_code = proc1->wait();
        write("Exit code: %d\n", exit_code);
        int final_status = proc1->status();
        write("Final status: %d\n\n", final_status);
    };

    if (err) {
        write("Error in Example 1: %s\n\n", describe_error(err));
    }

    // Example 2: Failed command
    write("Example 2: Failed command (nonexistent)\n");
    err = catch {
        Process.create_process proc2 = Process.create_process(
            ({"/nonexistent/command"})
        );

        if (!proc2) {
            error("Failed to create process");
        }

        mixed err2 = catch {
            int exit_code = proc2->wait();
            write("Exit code: %d\n", exit_code);
            int status = proc2->status();
            write("Status: %d\n", status);
        };

        if (err2) {
            write("Error caught: %s\n", describe_error(err2));
        }
    };

    if (err) {
        write("Error in Example 2 (expected): %s\n\n", describe_error(err));
    }

    // Example 3: Process with timeout
    write("Example 3: Process with timeout callback\n");
    err = catch {
        Process.Process proc3 = Process.Process(
            ({"sleep", "10"}),
            ([
                "timeout": 2,
                "timeout_callback": lambda(Process.Process p) {
                    write("Timeout callback triggered for PID %d\n", p->pid());
                }
            ])
        );

        if (!proc3) {
            error("Failed to create process with timeout");
        }

        int exit3 = proc3->wait();
        write("Process 3 exit code: %d (likely killed)\n", exit3);
        int status3 = proc3->status();
        write("Process 3 status: %d\n", status3);
    };

    if (err) {
        write("Error in Example 3: %s\n\n", describe_error(err));
    }

    // Example 4: Process.run error handling
    write("\nExample 4: Process.run with error checking\n");
    err = catch {
        mapping result = Process.run(({"ls", "/nonexistent/path"}));

        write("Exit code: %d\n", (int)result->exitcode);
        if ((int)result->exitcode != 0) {
            write("STDERR:\n%s\n", (string)(result->stderr || "(no stderr)"));
        } else {
            write("Command succeeded\n");
        }
    };

    if (err) {
        write("Error in Example 4: %s\n\n", describe_error(err));
    }

    write("\n✓ All process status examples completed\n");
    return 0;
}
