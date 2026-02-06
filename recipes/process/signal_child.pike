#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Avoiding Zombie Processes
//!
//! Demonstrates proper child process handling to prevent zombies
//!
//! @example
//!   // Always wait for child processes
//!   Process.create_process proc = Process.create_process(({"sleep", "10"}));
//!   proc->wait();  // Reap the child
//!
//! @note
//!   Zombie processes are created when children exit but parent hasn't waited.
//!   Always call wait() on child processes or use Process.run which handles it
//!
//! @seealso
//!   @[Process.create_process], @[Process.wait], @[Process.run]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    write("=== Creating multiple child processes ===\n\n");

    array(Process.create_process) children = ({});

    // Spawn multiple child processes
    for (int i = 0; i < 3; i++) {
        Process.create_process proc = Process.create_process(({
            "sleep", sprintf("%d", (i + 1) * 2)
        }));

        children += ({ proc });
        write("Spawned child %d with PID: %d\n", i + 1, proc->pid());
    }

    write("\nWaiting for children to complete...\n");

    // Wait for all children to prevent zombies
    foreach (children; int i; Process.create_process proc) {
        int exit_code = proc->wait();
        write("Child %d (PID %d) exited with code: %d\n",
              i + 1, proc->pid(), (int)exit_code);
    }

    write("\nAll children reaped successfully. No zombies!\n");

    // Alternative: Using Process.run which handles waiting automatically
    write("\n=== Using Process.run (automatic cleanup) ===\n");

    mapping result = Process.run(({"sleep", "1"}));
    write("Process completed with exit code: %d\n", (int)result->exitcode);

    return 0;
}
