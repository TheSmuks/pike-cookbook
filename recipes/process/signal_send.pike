#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Sending Signals to Processes
//! Demonstrates sending signals to processes using Process.kill

int main() {
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
