#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Sending Signals to Processes
//!
//! Demonstrates sending signals to processes using Process.kill
//!
//! @example
//!   // Create a process and send SIGTERM
//!   Process.create_process proc = Process.create_process(({"sleep", "30"}));
//!   proc->kill(signum("SIGTERM"));
//!   proc->wait();
//!
//! @note
//!   SIGKILL (9) and SIGSTOP (19) cannot be caught or ignored by the process.
//!   SIGTERM (15) is the preferred way to gracefully terminate processes
//!
//! @seealso
//!   @[Process.kill], @[signum], @[signal]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    // Create a long-running child process
    write("Creating child process (sleep 30)...\n");
    Process.create_process proc = Process.create_process(({"sleep", "30"}));

    int pid = proc->pid();
    write("Child PID: %d\n", pid);

    // Wait a moment
    write("Waiting 2 seconds...\n");
    sleep(2);

    // Send SIGTERM (15) to gracefully terminate
    write("Sending SIGTERM to process %d...\n", pid);
#if constant(kill)
    proc->kill(signum("SIGTERM"));
#else
    write("Warning: kill() not available on this system\n");
    proc->kill(15);
#endif

    // Wait for process to finish
    int exit_code = proc->wait();
    write("Process exited with code: %d\n", exit_code);

    return 0;
}
