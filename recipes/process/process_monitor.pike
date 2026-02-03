#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Monitoring Child Processes
//!
//! Demonstrates monitoring multiple child processes with status checking
//!
//! @example
//!   // Create and monitor child process
//!   Process.Process proc = Process.Process(({"sleep", "10"}));
//!
//!   // Check status: 0=running, 1=exited, 2=signaled
//!   int(-1..2) status = proc->status();
//!   if (status == 0) {
//!       write("Process is running\n");
//!   }
//!
//! @note
//!   The status() method returns: 0 (running), 1 (exited), 2 (signaled), -1 (error)
//!   Use last_signal() to get the signal number if status returns 2
//!
//! @seealso
//!   @[Process.Process], @[Process.status], @[Process.wait]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    write("=== Process Monitoring Example ===\n\n");

    // Create multiple child processes
    array(Process.Process) children = ({});

    for (int i = 0; i < 3; i++) {
        Process.Process proc = Process.Process(({
            "sleep", sprintf("%d", (i + 1) * 2)
        }));

        children += ({ proc });
        write("Started child %d: PID %d\n", i + 1, proc->pid());
    }

    write("\nMonitoring child processes...\n\n");

    // Monitor children until all complete
    int running = sizeof(children);
    while (running > 0) {
        running = 0;

        foreach (children; int i; Process.Process proc) {
            int(-1..2) status = proc->status();

            switch (status) {
                case 0:  // Still running
                    write("Child %d (PID %d): RUNNING\n", i + 1, proc->pid());
                    running++;
                    break;

                case 1:  // Exited
                    write("Child %d (PID %d): EXITED (code %d)\n",
                          i + 1, proc->pid(), proc->wait());
                    break;

                case 2:  // Signaled
                    write("Child %d (PID %d): SIGNALED (signal %d)\n",
                          i + 1, proc->pid(), proc->last_signal());
                    break;

                default:
                    write("Child %d: UNKNOWN STATUS\n", i + 1);
                    break;
            }
        }

        if (running > 0) {
            write("\n--- Waiting 1 second ---\n\n");
            sleep(1);
        }
    }

    write("\nAll children have terminated.\n");

    // Ensure all children are reaped
    foreach (children; int i; Process.Process proc) {
        int exit_code = proc->wait();
        write("Child %d final exit code: %d\n", i + 1, exit_code);
    }

    return 0;
}
