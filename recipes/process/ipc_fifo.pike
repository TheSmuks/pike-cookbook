#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Named Pipes (FIFOs) for IPC
//! Demonstrates creating and using named pipes for inter-process communication

int main() {
    string fifo_path = "/tmp/pike_fifo_" + (string)time();

    write("=== Named Pipe (FIFO) Example ===\n\n");

    // Create a named pipe (FIFO)
    write("Creating FIFO at: %s\n", fifo_path);

    mixed err = catch {
        // Remove existing FIFO if present
        if (file_stat(fifo_path)) {
            Stdio.recursive_rm(fifo_path);
        }

        // Create the FIFO
        Process.create_process mkfifo = Process.create_process((
            "mkfifo", fifo_path
        ));
        mkfifo->wait();

        write("FIFO created successfully.\n\n");

        // Example: Writer process
        write("Starting writer process...\n");
        Process.create_process writer = Process.create_process((
            "sh", "-c", sprintf(
                "echo 'Hello through FIFO' > %s && echo 'Second message' > %s",
                fifo_path, fifo_path
            )
        ));

        // Example: Reader process (this program)
        sleep(1);  // Give writer time to start
        write("Reading from FIFO...\n");

        mapping result = Process.run((
            "cat", fifo_path
        ));

        write("Data read from FIFO:\n%s\n", result->stdout);

        writer->wait();

        // Cleanup
        write("\nCleaning up FIFO...\n");
        Process.create_process cleanup = Process.create_process((
            "rm", "-f", fifo_path
        ));
        cleanup->wait();

        write("FIFO removed.\n");

    };

    if (err) {
        write("Error: %s\n", describe_error(err));
        // Cleanup on error
        catch { Stdio.recursive_rm(fifo_path); };
    }

    return 0;
}
