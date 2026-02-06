#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Anonymous Pipes for IPC
//!
//! Demonstrates using pipes for communication between processes
//!
//! @example
//!   // Create a pipe for child stdin
//!   Stdio.File stdin_pipe = Stdio.File();
//!   Process.create_process proc = Process.create_process(
//!       ({"cat"}),
//!       (["stdin": stdin_pipe->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE)])
//!   );
//!
//! @note
//!   Anonymous pipes are only available between related processes (parent-child).
//!   For unrelated processes, use named pipes (FIFOs) or sockets
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
    write("=== Anonymous Pipe Example ===\n\n");

    // Example 1: Simple pipe between parent and child
    write("Example 1: Parent writes to child via pipe\n");

    mixed err = catch {
        // Create pipes
        Stdio.File parent_read = Stdio.File();
        Stdio.File parent_write = Stdio.File();
        Stdio.File child_read = Stdio.File();
        Stdio.File child_write = Stdio.File();

        // Check if pipe() is available
        if (!parent_read->pipe) {
            write("Note: Stdio.File.pipe() not available on this system\n");
            write("Pipes may not be supported on this platform\n");
            return 0;
        }

        // Create child process with redirected I/O
        Process.create_process proc = Process.create_process(
            ({"cat", "-n"}),  // Number lines read from stdin
            ([
                "stdin": child_read->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
                "stdout": child_write->pipe()
            ])
        );

        if (!proc) {
            error("Failed to create child process");
        }

        child_read->close();
        child_write->close();

        // Write data to child
        write("Writing data to child...\n");
        parent_write->write("Line 1 from parent\n");
        parent_write->write("Line 2 from parent\n");
        parent_write->write("Line 3 from parent\n");
        parent_write->close();

        // Read response from child
        write("Reading response from child...\n");
        string response = parent_read->read();
        parent_read->close();

        if (!response) {
            write("Warning: No response read from child\n");
        }

        write("Response from child:\n%s", response);

        // Wait for child to complete
        int exit_code = proc->wait();
        write("\nChild exited with code: %d\n", exit_code);

        write("\n✓ Pipe example completed successfully\n");
    };

    if (err) {
        write("Error in pipe example: %s\n", describe_error(err));
        write("\nNote: This example requires pipe support which may not be available on all systems.\n");
        write("Alternative: Use Process.popen() for simpler pipe operations.\n");

        // Demonstrate alternative with popen
        write("\nAlternative using Process.popen():\n");
        mixed alt_err = catch {
            string result = Process.popen("echo 'Alternative pipe demo'");
            write("Output: %s\n", result || "");
        };
        if (alt_err) {
            write("Alternative also failed: %s\n", describe_error(alt_err));
        }
    }

    return 0;
}
