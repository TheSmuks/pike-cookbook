#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Installing Signal Handlers
//!
//! Demonstrates setting up signal handlers for graceful shutdown
//!
//! @example
//!   // Install a signal handler
//!   signal(signum("SIGINT"), my_handler);
//!
//!   void my_handler() {
//!       write("Caught SIGINT\n");
//!   }
//!
//! @note
//!   Signal handlers should be minimal and async-signal-safe.
//!   Avoid complex operations in handlers - set flags and handle in main loop
//!
//! @seealso
//!   @[signal], @[signum]

// Global flag for signal handling
private int shutdown_requested = 0;

//! Signal handler for SIGINT (Ctrl+C)
//!
//! @note
//!   Keep signal handlers minimal - just set flags and let main loop handle cleanup

void handle_sigint()
{
    write("\n[INFO] SIGINT received. Initiating graceful shutdown...\n");
    shutdown_requested = 1;
}

//! Signal handler for SIGTERM
//!
//! @note
//!   SIGTERM is the standard signal for requesting process termination

void handle_sigterm()
{
    write("\n[INFO] SIGTERM received. Initiating graceful shutdown...\n");
    shutdown_requested = 1;
}

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
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
