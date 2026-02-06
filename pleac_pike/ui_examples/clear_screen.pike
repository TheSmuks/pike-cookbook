#!/usr/bin/env pike
#pragma strict_types
// Recipe: Clearing the Screen and Terminal Control

// ANSI escape codes for terminal control
constant ANSI =([
    "clear": "\033[2J",          // Clear screen
    "home": "\033[H",            // Move cursor to home
    "clear_line": "\033[2K",     // Clear entire line
    "clear_end": "\033[0K",      // Clear to end of line
    "clear_start": "\033[1K",    // Clear to start of line
    "save_pos": "\033[s",        // Save cursor position
    "restore_pos": "\033[u",     // Restore cursor position
    "reset": "\033c",            // Reset terminal
]);

// Color codes
constant COLORS =([
    "reset": "\033[0m",
    "black": "\033[30m",
    "red": "\033[31m",
    "green": "\033[32m",
    "yellow": "\033[33m",
    "blue": "\033[34m",
    "magenta": "\033[35m",
    "cyan": "\033[36m",
    "white": "\033[37m",
]);

void clear_screen() {
    // Concatenate ANSI escape codes for screen clearing and cursor positioning
    // Cast to string to satisfy strict type checking
    write((string)ANSI->clear + (string)ANSI->home);
}

void move_cursor(int row, int col) {
    write(sprintf("\033[%d;%dH", row, col));
}

void set_color(string color) {
    // Use strict indexing with fallback to reset
    write((string)(COLORS[color] || COLORS->reset));
}

void reset_color() {
    write(COLORS->reset);
}

int main(int argc, array(string) argv) {
    // Check for terminal availability using function type check
    // This is the Pike 8.0 idiomatic way to check for isatty availability
    int use_ansi = 0;
    if (functionp(Stdio.stdout->isatty)) {
        mixed result = Stdio.stdout->isatty();
        if (intp(result) && result) {
            use_ansi = 1;
        }
    }

    if (!use_ansi) {
        write("Terminal control requires an interactive terminal\n");
        write("This demo uses ANSI escape codes for screen manipulation.\n");
        return 1;
    }

    // Demonstrates: screen clearing, cursor positioning, colored text
    array(string) colors_array = ({"red", "green", "yellow", "blue", "magenta"});

    // Clear screen and display header
    clear_screen();
    set_color("cyan");
    move_cursor(1, 1);
    write("=" * 60 + "\n");
    write("  Pike Terminal Control Demo\n");
    write("=" * 60 + "\n");
    reset_color();

    // Demonstrate cursor positioning
    move_cursor(5, 10);
    set_color("green");
    write("Positioned at row 5, column 10\n");
    reset_color();

    // Demonstrate different colors
    move_cursor(7, 1);
    foreach (colors_array;; string color) {
        set_color(color);
        write(sprintf("  This text is %s\n", color));
    }
    reset_color();

    // End at bottom with user prompt
    move_cursor(15, 1);
    write("\nPress Enter to exit...");
    Stdio.stdin->gets();

    return 0;
}
