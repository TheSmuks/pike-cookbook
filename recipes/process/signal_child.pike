#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Avoiding Zombie Processes
//! Demonstrates proper child process handling to prevent zombies

int main() {
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
              i + 1, proc->pid(), exit_code);
    }

    write("\nAll children reaped successfully. No zombies!\n");

    // Alternative: Using Process.run which handles waiting automatically
    write("\n=== Using Process.run (automatic cleanup) ===\n");

    mapping result = Process.run(({"sleep", "1"}));
    write("Process completed with exit code: %d\n", result->exitcode);

    return 0;
}
