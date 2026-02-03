#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Anonymous Pipes for IPC
//! Demonstrates using pipes for communication between processes

int main() {
    write("=== Anonymous Pipe Example ===\n\n");

    // Example 1: Simple pipe between parent and child
    write("Example 1: Parent writes to child via pipe\n");

    // Create pipes
    Stdio.File parent_read = Stdio.File();
    Stdio.File parent_write = Stdio.File();
    Stdio.File child_read = Stdio.File();
    Stdio.File child_write = Stdio.File();

    Process.create_process proc = Process.create_process(
        ({"cat", "-n"}),  // Number lines read from stdin
        ([
            "stdin": child_read->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
            "stdout": child_write->pipe()
        ])
    );

    child_read->close();
    child_write->close();

    // Write data to child
    parent_write->write("Line 1 from parent\n");
    parent_write->write("Line 2 from parent\n");
    parent_write->write("Line 3 from parent\n");
    parent_write->close();

    // Read response from child
    string response = parent_read->read();
    parent_read->close();

    write("Response from child:\n%s", response);

    int exit_code = proc->wait();
    write("Child exited with code: %d\n", exit_code);

    return 0;
}
