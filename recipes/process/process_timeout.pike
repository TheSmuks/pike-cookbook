#!/usr/bin/env pike
#pragma strict_vars
#pragma strict_types

//! Recipe: Process with Timeout
//!
//! Demonstrates creating processes with timeout handling using Process.Process class
//!
//! @example
//!   // Create process with 5 second timeout
//!   Process.Process proc = Process.Process(
//!       ({"long_running_command"}),
//!       ([
//!           "timeout": 5,
//!           "timeout_callback": lambda(Process.Process p) {
//!               write("Process timed out!\n");
//!           }
//!       ])
//!   );
//!
//! @note
//!   The timeout_callback is invoked when the process exceeds the time limit.
//!   The process will be automatically terminated after the callback executes
//!
//! @seealso
//!   @[Process.Process], @[Process.create_process]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
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
