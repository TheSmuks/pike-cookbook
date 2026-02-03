#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Process Output Filtering
//! Demonstrates filtering output through external processes

int main() {
    write("=== Output Filtering Examples ===\n\n");

    // Example 1: Simple pipeline using popen
    write("Example 1: Using Process.popen()\n");
    string output = Process.popen("echo 'Hello World' | tr '[:lower:]' '[:upper:]'");
    write("Output: %s\n", output);

    // Example 2: Chaining multiple filters
    write("\nExample 2: Chained filters\n");

    // Generate text, sort it, then get unique lines
    string text = "zebra\napple\nbanana\napple\ncherry\nbanana\n";
    mapping result = Process.run(
        ({"awk", "-F:", "{print $1}"}),
        ([
            "stdin": text
        ])
    );

    // Sort the output
    mapping sorted = Process.run(
        ({"sort"}),
        ([
            "stdin": result->stdout
        ])
    );

    // Get unique lines
    mapping unique = Process.run(
        ({"uniq"}),
        ([
            "stdin": sorted->stdout
        ])
    );

    write("Original:\n%s", text);
    write("After sort | uniq:\n%s", unique->stdout);

    // Example 3: Using spawn with custom filtering
    write("\nExample 3: Custom filter pipeline\n");

    Stdio.File pipe1 = Stdio.File();
    Stdio.File pipe2 = Stdio.File();

    // Create filter process (grep)
    Process.create_process filter = Process.create_process(
        ({"grep", "[0-9]"}),
        ([
            "stdin": pipe1->pipe(Stdio.PROP_IPC | Stdio.PROP_REVERSE),
            "stdout": pipe2->pipe()
        ])
    );

    pipe1->close();
    pipe2->close();

    // Feed data to filter
    pipe1->write("item1\nitem2\nitem_three\nitem4\nitem_five\n");
    pipe1->close();

    // Read filtered output
    string filtered = pipe2->read();
    pipe2->close();

    write("Filtered output (lines containing digits):\n%s", filtered);

    filter->wait();

    return 0;
}
