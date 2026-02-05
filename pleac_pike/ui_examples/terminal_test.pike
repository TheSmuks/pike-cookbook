#!/usr/bin/env pike
#pragma strict_types
// Recipe: Testing Whether a Program Is Running Interactively

int main() {
    // Check if stdout is a terminal
    if (Stdio.stdout->isatty && Stdio.stdout->isatty()) {
        write("Running in interactive terminal mode\n");
    } else {
        write("Running in non-interactive mode (piped or redirected)\n");
    }

    // Check if stdin is a terminal
    if (Stdio.stdin->isatty && Stdio.stdin->isatty()) {
        write("stdin is connected to a terminal\n");
    } else {
        write("stdin is redirected or piped\n");
    }

    // Demonstrate different output based on context
    if (Stdio.stdout->isatty && Stdio.stdout->isatty()) {
        // Interactive: use colors and fancy output
        write("\033[1;32mSuccess!\033[0m Running with terminal support\n");
    } else {
        // Non-interactive: plain text
        write("Success: Running without terminal\n");
    }

    return 0;
}
