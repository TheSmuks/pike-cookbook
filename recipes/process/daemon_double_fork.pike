#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Traditional Double-Fork Daemonization
//!
//! Demonstrates the classic Unix double-fork technique for daemonization
//!
//! @example
//!   // First fork and exit parent
//!   int pid1 = fork();
//!   if (pid1 > 0) exit(0);
//!
//!   // Create new session
//!   setsid();
//!
//!   // Second fork and exit first child
//!   int pid2 = fork();
//!   if (pid2 > 0) exit(0);
//!
//! @note
//!   The double-fork technique ensures the daemon is not a session leader
//!   and cannot acquire a controlling terminal. Process.daemon() handles this
//!
//! @seealso
//!   @[Process.daemon], @[fork], @[setsid]

#if constant(fork) && constant(exece)

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    write("Starting double-fork daemon...\n");

    // First fork: create parent-child relationship
    mixed fork1 = fork();

    // In parent, fork1 is an object with pid() method
    // In child, fork1 is 0
    int pid1;
    if (objectp(fork1)) {
        pid1 = fork1->pid();
    } else {
        pid1 = 0;  // We're in the child
    }

    if (pid1 < 0) {
        error("First fork failed: %s\n", strerror(errno()));
    }

    // Parent exits
    if (pid1 > 0) {
        write("Parent (PID %d) exiting. Child PID: %d\n", getpid(), pid1);
        exit(0);
    }

    // Child continues
    write("First fork successful. Child PID: %d\n", getpid());

    // Create new session
#if constant(setsid)
    setsid();
    write("Created new session\n");
#endif

    // Second fork: ensure daemon cannot acquire a controlling terminal
    mixed fork2 = fork();

    // In parent (first child), fork2 is an object with pid() method
    // In child (daemon), fork2 is 0
    int pid2;
    if (objectp(fork2)) {
        pid2 = fork2->pid();
    } else {
        pid2 = 0;  // We're in the child
    }

    if (pid2 < 0) {
        error("Second fork failed: %s\n", strerror(errno()));
    }

    // First child exits
    if (pid2 > 0) {
        write("First child (PID %d) exiting. Daemon PID: %d\n", getpid(), pid2);
        exit(0);
    }

    // Daemon continues
    write("Daemon (PID %d) running in background\n", getpid());

    // Change working directory
    cd("/");

    // Close file descriptors
    Stdio.File devnull = Stdio.File("/dev/null", "rw");
    devnull->dup2(Stdio.stdin);
    devnull->dup2(Stdio.stdout);
    devnull->dup2(Stdio.stderr);

    // Daemon work
    Stdio.File logfile = Stdio.File("/tmp/double_fork_daemon.log", "wac");
    logfile->write(sprintf("[%s] Daemon started with PID %d\n", ctime(time()), getpid()));

    for (int i = 0; i < 5; i++) {
        logfile->write(sprintf("[%s] Working... %d/5\n", ctime(time()), i + 1));
        sleep(2);
    }

    logfile->write(sprintf("[%s] Daemon exiting\n", ctime(time())));
    logfile->close();

    return 0;

#else
    write("Error: fork() not available on this system\n");
    return 1;
#endif
}
