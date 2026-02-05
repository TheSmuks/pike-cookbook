#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Bidirectional Process Communication
//!
//! Demonstrates reading and writing to a process simultaneously
//!
//! @example
//!   // Create pipes for stdin and stdout
//!   Stdio.File stdin_pipe = Stdio.File();
//!   Stdio.File stdout_pipe = Stdio.File();
//!
//!   Process.create_process proc = Process.create_process(
//!       ({"cat"}),
//!       ([
//!           "stdin": stdin_pipe->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
//!           "stdout": stdout_pipe->pipe()
//!       ])
//!   );
//!
//! @note
//!   Use Stdio.PROP_IPC | Stdio.PROP_REVERSE for stdin to get the write end
//!   of the pipe. Remember to close pipe ends you don't use to avoid deadlocks
//!
//! @seealso
//!   @[Process.create_process], @[Stdio.File.pipe], @[Stdio.PROP_IPC]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    // Create pipes for stdin, stdout, and stderr
    Stdio.File stdin_pipe = Stdio.File();
    Stdio.File stdout_pipe = Stdio.File();
    Stdio.File stderr_pipe = Stdio.File();

    Process.create_process proc = Process.create_process(
        ({"cat", "-n"}),  // Number lines
        ([
            "stdin": stdin_pipe->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
            "stdout": stdout_pipe->pipe(),
            "stderr": stderr_pipe->pipe()
        ])
    );

    // stdin_pipe->pipe(PROP_REVERSE) returned the write end for us
    // So stdin_pipe IS the write end we need!

    // Write data to process
    stdin_pipe->write("Line 1\nLine 2\nLine 3\n");
    stdin_pipe->close();

    // stdout_pipe and stderr_pipe are the read ends - don't close before reading!

    string stdout_data = stdout_pipe->read();
    string stderr_data = stderr_pipe->read();

    write("Process output:\n%s", stdout_data);
    if (sizeof(stderr_data)) {
        write("Process errors:\n%s", stderr_data);
    }

    int exit_code = proc->wait();
    write("\nExit code: %d\n", exit_code);

    return 0;
}
