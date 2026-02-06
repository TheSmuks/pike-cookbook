#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Writing to Process stdin
//!
//! Demonstrates sending data to a process via stdin
//!
//! @example
//!   // Write to process stdin using Process.run
//!   mapping result = Process.run(
//!       ({"grep", "pattern"}),
//!       (["stdin": "line1\nline2\nline3\n"])
//!   );
//!
//! @note
//!   When writing to stdin manually, always close the write end to signal
//!   EOF to the process, otherwise it may hang waiting for more input
//!
//! @seealso
//!   @[Process.run], @[Stdio.File.pipe]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    // Example 1: Using Process.run with string stdin
    write("=== Example 1: Process.run with stdin ===\n");

    mapping result = Process.run(
        ({"awk", "-F:", "{print $1, $2}"}),
        ([
            "stdin": "alice:30\nbob:25\ncharlie:35\n"
        ])
    );

    write("Output:\n%s\n", (string)result->stdout);

    // Example 2: Manual stdin pipe
    write("\n=== Example 2: Manual stdin pipe ===\n");

    Stdio.File stdin_pipe = Stdio.File();
    Stdio.File stdout_pipe = Stdio.File();

    Process.create_process proc = Process.create_process(
        ({"grep", "a"}),
        ([
            "stdin": stdin_pipe->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
            "stdout": stdout_pipe->pipe()
        ])
    );

    // stdin_pipe->pipe(PROP_REVERSE) returned the write end for us
    // So stdin_pipe IS the write end we need!

    // Write data to stdin
    stdin_pipe->write("apple\nbanana\ncherry\navocado\n");
    stdin_pipe->close();  // Signal EOF to the process

    // stdout_pipe is the read end - don't close it before reading!
    string output = stdout_pipe->read();
    write("Filtered output:\n%s", output);

    proc->wait();

    return 0;
}
