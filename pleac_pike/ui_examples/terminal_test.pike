#!/usr/bin/env pike
#pragma strict_types
// Recipe: Testing Whether a Program Is Running Interactively

int main(int argc, array(string) argv) {
    // Check if stdout is a terminal using function type check
    // This is the Pike 8.0 idiomatic way to check for isatty availability
    if (functionp(Stdio.stdout->isatty) && Stdio.stdout->isatty()) {
        write("Running in interactive terminal mode\n");
    } else {
        write("Running in non-interactive mode (piped or redirected)\n");
    }

    // Check if stdin is a terminal
    if (functionp(Stdio.stdin->isatty) && Stdio.stdin->isatty()) {
        write("stdin is connected to a terminal\n");
    } else {
        write("stdin is redirected or piped\n");
    }

    // Demonstrate different output based on context
    if (functionp(Stdio.stdout->isatty) && Stdio.stdout->isatty()) {
        // Interactive: use colors and fancy output
        write("\033[1;32mSuccess!\033[0m Running with terminal support\n");
    } else {
        // Non-interactive: plain text (no ANSI codes)
        write("Success: Running without terminal\n");
    }

    return 0;
}
