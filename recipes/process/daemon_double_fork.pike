#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Traditional Double-Fork Daemonization
//! Demonstrates the classic Unix double-fork technique for daemonization

#if constant(fork) && constant(exece)

int main() {
    write("Starting double-fork daemon...\n");

    // First fork: create parent-child relationship
    int pid1 = fork();
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
    int pid2 = fork();
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
