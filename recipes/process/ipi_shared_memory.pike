#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Communication Between Related Processes
//! Demonstrates using file descriptors for IPC between parent and child

int main() {
    write("=== Parent-Child Communication Example ===\n\n");

    // Create pipes for bidirectional communication
    Stdio.File parent_to_child_rd = Stdio.File();
    Stdio.File parent_to_child_wr = Stdio.File();
    Stdio.File child_to_parent_rd = Stdio.File();
    Stdio.File child_to_parent_wr = Stdio.File();

    // Spawn child process with redirected I/O
    Process.create_process child = Process.create_process(
        ({"cat", "-e"}),  // cat with -e shows line endings
        ([
            "stdin": parent_to_child_rd->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
            "stdout": child_to_parent_wr->pipe()
        ])
    );

    parent_to_child_rd->close();
    child_to_parent_wr->close();

    write("Child PID: %d\n\n", child->pid());

    // Send data to child
    write("Sending data to child...\n");
    Stdio.File write_pipe = parent_to_child_wr;
    write_pipe->write("Message 1 from parent\n");
    write_pipe->write("Message 2 from parent\n");
    write_pipe->close();

    // Read response from child
    write("Reading response from child...\n");
    child_to_parent_rd->close();
    string response = child_to_parent_rd->read();
    child_to_parent_rd->close();

    write("\nChild response:\n%s", response);

    // Wait for child to complete
    int exit_code = child->wait();
    write("\nChild exited with code: %d\n", exit_code);

    return 0;
}
