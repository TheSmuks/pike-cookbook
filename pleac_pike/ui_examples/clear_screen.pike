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
    write(ANSI->clear + ANSI->home);
}

void move_cursor(int row, int col) {
    write(sprintf("\033[%d;%dH", row, col));
}

void set_color(string color) {
    write(COLORS[color] || COLORS->reset);
}

void reset_color() {
    write(COLORS->reset);
}

int main() {
    // Only use ANSI codes if we're in a terminal
    int use_ansi = Stdio.stdout->isatty && Stdio.stdout->isatty();

    if (use_ansi) {
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
        for (int i = 0; i < sizeof(colors_array); i++) {
            set_color(colors_array[i]);
            write(sprintf("  This text is %s\n", colors_array[i]));
        }
        reset_color();

        // End at bottom
        move_cursor(15, 1);
        write("\nPress Enter to exit...");
        Stdio.stdin->gets();
    } else {
        write("Terminal control requires an interactive terminal\n");
    }

    return 0;
}
