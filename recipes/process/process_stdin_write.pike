#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Writing to Process stdin
//! Demonstrates sending data to a process via stdin

int main() {
    // Example 1: Using Process.run with string stdin
    write("=== Example 1: Process.run with stdin ===\n");

    mapping result = Process.run(
        ({"awk", "-F:", "{print $1, $2}"}),
        ([
            "stdin": "alice:30\nbob:25\ncharlie:35\n"
        ])
    );

    write("Output:\n%s\n", result->stdout);

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

    // Close the pipe ends we don't need
    stdin_pipe->close();

    // Write data to stdin
    Stdio.File write_fd = stdin_pipe;
    write_fd->write("apple\nbanana\ncherry\navocado\n");
    write_fd->close();  // Signal EOF to the process

    // Read output
    stdout_pipe->close();
    string output = stdout_pipe->read();
    write("Filtered output:\n%s", output);

    proc->wait();

    return 0;
}
