#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Process with Environment and Working Directory
//! Demonstrates setting custom environment and working directory for spawned processes

int main() {
    // Set custom environment variables
    mapping(string:string) custom_env = ([
        "MY_VAR": "custom_value",
        "PATH": getenv("PATH") || "",
        "HOME": getenv("HOME") || ""
    ]);

    // Spawn process with custom environment and working directory
    Process.create_process proc = Process.create_process(
        ({"sh", "-c", "echo \"MY_VAR=$MY_VAR\"; echo \"PWD=$(pwd)\""}),
        ([
            "env": custom_env,
            "cwd": "/tmp"
        ])
    );

    proc->wait();

    write("\n--- Example with Process.run ---\n");

    // Using Process.run with environment
    mapping result = Process.run(
        ({"sh", "-c", "echo \"Working in: $(pwd)\"; ls | head -5"}),
        ([
            "cwd": "/etc",
            "env": custom_env
        ])
    );

    write("%s\n", result->stdout);

    return 0;
}
