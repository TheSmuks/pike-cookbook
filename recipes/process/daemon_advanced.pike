#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Advanced Daemonization with Custom I/O
//!
//! Demonstrates daemon with custom stdout/stderr redirection
//!
//! @example
//!   // Daemonize with custom I/O redirection
//!   Process.daemon(1, 0, ([
//!       "stdout": "/tmp/daemon.log",
//!       "stderr": "/tmp/daemon.err",
//!       "cwd": "/tmp"
//!   ]));
//!
//! @note
//!   The third parameter to Process.daemon accepts a mapping with "stdout",
//!   "stderr", and "cwd" keys to control I/O and working directory
//!
//! @seealso
//!   @[Process.daemon], @[getcwd], @[getpid]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    write("Starting advanced daemon...\n");

    // Daemonize with custom stdout/stderr to files
    Process.daemon(1, 0, ([
        "stdout": "/tmp/pike_daemon_stdout.log",
        "stderr": "/tmp/pike_daemon_stderr.log",
        "cwd": "/tmp"
    ]));

    // Now we're running as a daemon in /tmp
    // Log startup
    Stdio.File log = Stdio.File("daemon_startup.log", "wac");
    log->write(sprintf("[%s] Daemon PID: %d\n", ctime(time()), getpid()));
    log->write(sprintf("[%s] Working directory: %s\n", ctime(time()), getcwd()));
    log->close();

    // Write to stdout (goes to /tmp/pike_daemon_stdout.log)
    write("This message goes to stdout log file\n");

    // Write to stderr (goes to /tmp/pike_daemon_stderr.log)
    werror("This message goes to stderr log file\n");

    // Simulate work
    for (int i = 0; i < 3; i++) {
        write("Iteration %d\n", i + 1);
        sleep(1);
    }

    write("Daemon complete\n");

    return 0;
}
