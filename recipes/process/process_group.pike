#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Process Groups and Sessions
//! Demonstrates managing process groups for signaling multiple processes

#if constant(fork) && constant(setpgrp)

int main() {
    write("=== Process Group Example ===\n\n");

    // Fork to create a child
    int child_pid = fork();

    if (child_pid < 0) {
        error("fork() failed: %s\n", strerror(errno()));
    }

    if (child_pid == 0) {
        // Child process
        write("Child PID: %d\n", getpid());
        write("Child PGID: %d\n", getpgrp(0));

        // Create a new process group
#if constant(setpgid)
        setpgid(0, 0);  // Create new process group with child as leader
        write("Child created new process group. PGID: %d\n", getpgrp(0));
#endif

        // Spawn grandchild in same process group
        Process.create_process grandchild = Process.create_process(
            ({"sleep", "5"})
        );

        write("Grandchild PID: %d\n", grandchild->pid());

        // Do some work
        sleep(3);

        write("Child exiting\n");
        exit(0);

    } else {
        // Parent process
        write("Parent PID: %d\n", getpid());
        write("Parent PGID: %d\n", getpgrp(0));
        write("Child PID: %d\n", child_pid);

        sleep(1);

        // Send signal to entire process group
#if constant(kill)
        write("\nSending SIGTERM to child's process group (%d)\n", child_pid);
        kill(-child_pid, signum("SIGTERM"));  // Negative PID signals entire group
#endif

        // Wait for child
        int status;
        int result = waitpid(child_pid, status);
        write("\nChild %d exited. Result: %d\n", child_pid, result);
    }

    return 0;

#else
    write("Error: Required process control functions not available\n");
    return 1;
#endif
}
