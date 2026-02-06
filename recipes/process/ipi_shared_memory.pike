#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Communication Between Related Processes
//!
//! Demonstrates using file descriptors for IPC between parent and child
//!
//! @example
//!   // Create bidirectional pipes
//!   Stdio.File parent_to_child_rd = Stdio.File();
//!   Stdio.File parent_to_child_wr = Stdio.File();
//!   Stdio.File child_to_parent_rd = Stdio.File();
//!   Stdio.File child_to_parent_wr = Stdio.File();
//!
//!   // Spawn child with redirected I/O
//!   Process.create_process child = Process.create_process(
//!       ({"cat"}),
//!       ([
//!           "stdin": parent_to_child_rd->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
//!           "stdout": child_to_parent_wr->pipe()
//!       ])
//!   );
//!
//! @note
//!   Always close pipe ends you don't use to avoid deadlocks and resource leaks
//!
//! @seealso
//!   @[Stdio.File.pipe], @[Stdio.PROP_IPC], @[Process.create_process]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    write("=== Parent-Child Communication Example ===\n\n");

    mixed err = catch {
        // Create pipes for bidirectional communication
        Stdio.File parent_to_child_rd = Stdio.File();
        Stdio.File parent_to_child_wr = Stdio.File();
        Stdio.File child_to_parent_rd = Stdio.File();
        Stdio.File child_to_parent_wr = Stdio.File();

        // Check if pipe() is available
        if (!parent_to_child_rd->pipe) {
            write("Note: Stdio.File.pipe() not available on this system\n");
            write("IPC pipes may not be supported on this platform\n");
            return 0;
        }

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
        string response = child_to_parent_rd->read();
        child_to_parent_rd->close();

        write("\nChild response:\n%s", response);

        // Wait for child to complete
        int exit_code = child->wait();
        write("\nChild exited with code: %d\n", exit_code);
    };

    if (err) {
        write("Error: %s\n", describe_error(err));
        write("\nNote: This example requires pipe() support which may not be available.\n");
        write("For simpler IPC, consider using Process.popen() or FIFOs.\n");
    }

    return 0;
}
