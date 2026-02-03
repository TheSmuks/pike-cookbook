#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Installing Signal Handlers
//! Demonstrates setting up signal handlers for graceful shutdown

// Global flag for signal handling
private volatile int shutdown_requested = 0;

//! Signal handler for SIGINT (Ctrl+C)
void handle_sigint()
{
    write("\n[INFO] SIGINT received. Initiating graceful shutdown...\n");
    shutdown_requested = 1;
}

//! Signal handler for SIGTERM
void handle_sigterm()
{
    write("\n[INFO] SIGTERM received. Initiating graceful shutdown...\n");
    shutdown_requested = 1;
}

int main() {
    // Install signal handlers
#if constant(signal)
    signal(signum("SIGINT"), handle_sigint);
    signal(signum("SIGTERM"), handle_sigterm);
    write("Signal handlers installed.\n");
    write("Press Ctrl+C to trigger graceful shutdown.\n\n");
#else
    write("Warning: signal() not available on this system\n");
#endif

    // Simulate work
    int counter = 0;
    while (!shutdown_requested) {
        write("Working... %d\n", ++counter);
        sleep(1);

        // Check for shutdown every iteration
        if (counter >= 10) {
            write("Work completed normally.\n");
            break;
        }
    }

    // Cleanup
    write("\n[CLEANUP] Performing cleanup tasks...\n");
    write("[CLEANUP] Closing resources...\n");
    write("[CLEANUP] Shutdown complete.\n");

    return 0;
}
