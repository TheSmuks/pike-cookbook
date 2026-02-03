#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Basic Process Spawning
//!
//! Demonstrates creating a new process using Process.create_process
//!
//! @example
//!   // Create a simple process
//!   Process.create_process proc = Process.create_process(({"echo", "Hello"}));
//!   proc->wait();
//!
//! @note
//!   Process.create_process is the preferred method for spawning processes
//!   in Pike 8.x over the older Process.spawn
//!
//! @seealso
//!   @[Process.run], @[Process.spawn], @[Process.Process]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    // Method 1: Using Process.create_process with array of arguments
    write("Method 1: Process.create_process\n");
    Process.create_process proc = Process.create_process(
        ({"echo", "Hello from Pike 8!"})
    );

    int exit_code = proc->wait();
    write("Exit code: %d\n\n", exit_code);

    // Method 2: Using Process.run for easy output capture
    write("Method 2: Process.run (captures output)\n");
    mapping result = Process.run(({"ls", "-la", "/tmp"}));

    write("STDOUT:\n%s\n", result->stdout);
    write("Exit code: %d\n\n", result->exitcode);

    // Method 3: Using Process.spawn for shell commands
    write("Method 3: Process.spawn\n");
    Process.Process p = Process.spawn("echo 'Hello from shell'");

    exit_code = p->wait();
    write("Exit code: %d\n", exit_code);

    return 0;
}
