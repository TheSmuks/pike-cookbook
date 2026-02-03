#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Basic Daemonization
//! Demonstrates creating a daemon process using Process.daemon

int main() {
    write("Starting daemon process...\n");
    write("This process will daemonize and run in the background.\n\n");

    // Daemonize: change to /, close all fds
    Process.daemon(0, 0);

    // At this point, we're running as a daemon
    // Open log file for output
    Stdio.File log_file = Stdio.File("/tmp/pike_daemon.log", "wac");

    // Write to log
    log_file->write(sprintf("[%s] Daemon started\n", ctime(time())));
    log_file->write(sprintf("[%s] PID: %d\n", ctime(time()), getpid()));

    // Simulate daemon work
    for (int i = 0; i < 5; i++) {
        log_file->write(sprintf("[%s] Working... iteration %d\n", ctime(time()), i + 1));
        sleep(2);
    }

    log_file->write(sprintf("[%s] Daemon finished\n", ctime(time())));
    log_file->close();

    return 0;
}
