#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Listing Available Signals
//!
//! Demonstrates enumerating all available signals in the system
//!
//! @example
//!   // Get signal number for SIGINT
//!   int sigint_num = signum("SIGINT");
//!   write("SIGINT is signal number: %d\n", sigint_num);
//!
//! @note
//!   Not all signals are available on all platforms. Use signum() to check
//!   if a signal exists (returns -1 if not found)
//!
//! @seealso
//!   @[signum], @[signal], @[Process.kill]

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    write("=== Available Signals ===\n\n");

    // Get list of all signals
    array(string) signals = ({
        "SIGHUP", "SIGINT", "SIGQUIT", "SIGILL", "SIGTRAP",
        "SIGABRT", "SIGBUS", "SIGFPE", "SIGKILL", "SIGUSR1",
        "SIGSEGV", "SIGUSR2", "SIGPIPE", "SIGALRM", "SIGTERM",
        "SIGSTKFLT", "SIGCHLD", "SIGCONT", "SIGSTOP", "SIGTSTP",
        "SIGTTIN", "SIGTTOU", "SIGURG", "SIGXCPU", "SIGXFSZ",
        "SIGVTALRM", "SIGPROF", "SIGWINCH", "SIGIO", "SIGPWR",
        "SIGSYS"
    });

    // Display signal numbers
    foreach(signals; ; string sig) {
        int sig_num = signum(sig);
        if (sig_num > 0) {
            write("%2d: %s\n", sig_num, sig);
        }
    }

    // Common signals with descriptions
    write("\n=== Common Signals ===\n");
    mapping(string:string) descriptions = ([
        "SIGINT": "Interrupt from keyboard (Ctrl+C)",
        "SIGTERM": "Termination signal",
        "SIGKILL": "Kill signal (cannot be caught)",
        "SIGHUP": "Hangup detected on controlling terminal",
        "SIGQUIT": "Quit from keyboard",
        "SIGCHLD": "Child process stopped or terminated",
        "SIGSTOP": "Stop process (cannot be caught)",
        "SIGCONT": "Continue if stopped",
        "SIGALRM": "Timer signal from alarm()",
        "SIGUSR1": "User-defined signal 1",
        "SIGUSR2": "User-defined signal 2"
    ]);

    foreach (descriptions; string sig; string desc) {
        int num = signum(sig);
        if (num > 0) {
            write("%2d %-10s: %s\n", num, sig, desc);
        }
    }

    return 0;
}
