#!/usr/bin/env pike
#pragma strict_types

//! Recipe: Listing Available Signals
//! Demonstrates enumerating all available signals in the system

int main() {
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
    foreach(signals; int i; string sig) {
        int signum = signum(sig);
        if (signum > 0) {
            write("%2d: %s\n", signum, sig);
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
