---
id: user-interfaces
title: User Interfaces
sidebar_label: User Interfaces
---

# User Interfaces

## Introduction

**What this covers**
- Terminal/console programming with Readline
- Command-line argument parsing with Getopt
- ANSI escape codes for colors and formatting
- Interactive terminal UIs with keyboard navigation
- Password input and terminal control with termios
- GTK2/GTK3 graphical user interfaces
- Event-driven programming patterns

**Why use it**
User interfaces are how users interact with your programs. Pike 8 provides excellent support for both text-based terminal interfaces and graphical applications. This guide covers everything from simple command-line tools to interactive terminal menus and GUI applications.

:::tip Key Concept
Pike's `Stdio.Readline` provides powerful interactive input with history, editing, and completion. For GUI applications, Pike supports GTK2/GTK3 through optional modules. Always check for interactive terminals with `isatty()` before using ANSI codes.
:::

```pike
// User Interfaces in Pike 8
// Demonstrating terminal, console, and GUI programming

import Stdio;

void check_ui_modules() {
    // Check terminal capabilities
    if (isatty(STDOUT->fd())) {
        write("Running in terminal mode\n");
    } else {
        write("Running in non-interactive mode\n");
    }

    // Check for optional modules
#ifdef __GTK2__
    write("GTK2 support available\n");
#else
    write("GTK2 not available\n");
#endif

#ifdef __NCURSES__
    write("NCurses support available\n");
#else
    write("NCurses not available\n");
#endif
}
```

---

## Parsing Program Arguments

Pike 8 provides the `Getopt` module for sophisticated command-line argument parsing. This modern approach handles short options, long options, and arguments with type safety.

```pike
//-----------------------------
// Recipe: Parse command-line arguments
//-----------------------------
import Getopt;

int verbose;
string output_file;
int number;

// Define all options
foreach (find_all_options(argv, ({
    ({"help", NO_ARG, ({ "-h", "--help" })}),
    ({"verbose", NO_ARG, ({ "-v", "--verbose" })}),
    ({"output", HAS_ARG, ({ "-o", "--output" })}),
    ({"number", HAS_ARG, ({ "-n", "--number" })}),
}), array(string) opt) {
    switch(opt[0]) {
        case "help":
            usage();
            return 0;
        case "verbose":
            verbose;
            break;
        case "output":
            output_file;
            break;
        case "number":
            number;
            break;
    }
}

// Get remaining arguments
array(string) args;
args;
```

:::tip
Use `find_all_options()` from the Getopt module for clean, maintainable argument parsing. It automatically generates help text and handles both short (`-v`) and long (`--verbose`) option formats.
:::

---

## Testing Whether a Program Is Running Interactively

Use `Stdio.isatty()` to detect if your program is running in an interactive terminal or being piped/redirected. This is crucial for deciding whether to use colors, progress indicators, or fancy terminal output.

```pike
//-----------------------------
// Recipe: Detect interactive terminal
//-----------------------------

int is_interactive() {
    return isatty(STDOUT->fd());
}

void smart_output(string msg) {
    if (is_interactive()) {
        // Use colors and fancy output
        write("\033[1;32m%s\033[0m\n", msg);
    } else {
        // Plain text for pipes/redirection
        write("%s\n", msg);
    }
}
```

Checking `isatty()` before using ANSI escape codes or terminal-specific features ensures your program works correctly when output is redirected to files or piped to other programs.

---

## Clearing the Screen

Use ANSI escape sequences for screen clearing and cursor positioning. Always check if you're in a terminal first.

```pike
//-----------------------------
// Recipe: Clear screen and position cursor
//-----------------------------

constant ANSI_CLEAR = "\033[2J";
constant ANSI_HOME = "\033[H";
constant ANSI_RESET = "\033[0m";

void clear_screen() {
    if (isatty(STDOUT->fd())) {
        write(ANSI_CLEAR);
        write(ANSI_HOME);
    }
}

// ANSI color codes
constant COLORS = ([
    "black": "\033[30m",
    "red": "\033[31m",
    "green": "\033[32m",
    "yellow": "\033[33m",
    "blue": "\033[34m",
    "magenta": "\033[35m",
    "cyan": "\033[36m",
    "white": "\033[37m",
]);

void colored_write(string color, string msg) {
    if (isatty(STDOUT->fd())) {
        write(COLORS[color]);
        write(msg);
        write(ANSI_RESET);
    } else {
        write(msg);
    }
}
```

---

## Determining Terminal or Window Size

Use `Stdio.get_terminal_size()` to get terminal dimensions for proper text layout and UI sizing.

```pike
//-----------------------------
// Recipe: Get terminal dimensions
//-----------------------------

mapping(string:int) size;
size;

if (size) {
    int cols = size["xsize"];
    int rows = size["ysize"];
    write("Terminal: %dx%d\n", cols, rows);
}

// Responsive text wrapping
string wrap_text(string text, int width) {
    array(string) words = text / " ";
    array(string) lines = ({});
    string current = "";

    foreach (words, string word) {
        if (sizeof(current) + sizeof(word) + 1 > width) {
            lines += ({current});
            current = word;
        } else {
            if (current != "") current += " ";
            current += word;
        }
    }
    if (current) lines += ({current});

    return lines * "\n";
}
```

---

## Changing Text Color

ANSI color codes provide colored terminal output. Always wrap with `isatty()` checks.

```pike
//-----------------------------
// Recipe: Add colors to terminal output
//-----------------------------

constant COLORS = ([
    "black": "\033[30m",
    "red": "\033[31m",
    "green": "\033[32m",
    "yellow": "\033[33m",
    "blue": "\033[34m",
    "magenta": "\033[35m",
    "cyan": "\033[36m",
    "white": "\033[37m",
]);

constant BG_COLORS = ([
    "black": "\033[40m",
    "red": "\033[41m",
    "green": "\033[42m",
    "yellow": "\033[43m",
    "blue": "\033[44m",
    "magenta": "\033[45m",
    "cyan": "\033[46m",
    "white": "\033[47m",
]);

// Text styling
constant BOLD = "\033[1m";
constant DIM = "\033[2m";
constant UNDERLINE = "\033[4m";
constant BLINK = "\033[5m";
constant REVERSE = "\033[7m";

// Colored write function
void cwrite(string fg, string msg) {
    if (isatty(STDOUT->fd())) {
        write(COLORS[fg]);
        write(msg);
        write("\033[0m");
    } else {
        write(msg);
    }
}

// Progress bar example
void progress_bar(int percent) {
    int width = 50;
    int filled = (percent * width) / 100;

    write("\r[");
    write("\033[42m");  // Green background
    write(" " * filled);
    write("\033[0m");
    write("%s] %3d%%", " " * (width - filled), percent);
}
```

:::tip
Always test for interactive terminal with `isatty()` before using ANSI codes. This prevents escape sequences from appearing in log files or when output is piped to other programs.
:::

---

## Reading from the Keyboard

`Stdio.Readline` provides interactive input with history, editing, and completion support - perfect for command-line applications.

```pike
//-----------------------------
// Recipe: Interactive input with Readline
//-----------------------------

class ReadlineUI {
    inherit Stdio.Readline;

    void create(string|void prompt) {
        ::create();
        set_prompt(prompt || "> ");
    }

    // Get a single line
    string get_line() {
        return read();
    }

    // Confirm y/n
    int confirm(string question) {
        string old_prompt = get_prompt();
        set_prompt(question + " [y/N]: ");
        string answer = read();
        set_prompt(old_prompt);
        return lower_case(answer) == "y";
    }

    // Menu selection
    int menu(string title, array(string) options) {
        write("\n%s\n", title);
        for (int i = 0; i < sizeof(options); i++) {
            write("  %d. %s\n", i + 1, options[i]);
        }

        while (1) {
            set_prompt("Choose: ");
            string input = read();
            int choice = (int)input;

            if (choice > 0 && choice <= sizeof(options)) {
                return choice - 1;
            }
            write("Invalid choice\n");
        }
    }
}
```

---

## Reading Passwords

For password input, disable terminal echo using `tcsetattr()` to prevent characters from being displayed.

```pike
//-----------------------------
// Recipe: Secure password input
//-----------------------------

string get_password(string|void prompt) {
    string p = prompt || "Password: ";
    write(p);

    // Disable echo using modern Pike 8 syntax
    STDIN->tcsetattr(([ "ECHO": 0 ]));

    string password = read();

    // Restore echo
    STDIN->tcsetattr(([ "ECHO": 1 ]));

    write("\n");
    return password || "";
}

// Password confirmation
int confirm_password(string prompt) {
    string pass1 = get_password(prompt);
    string pass2 = get_password("Confirm password: ");

    if (pass1 == pass2 && sizeof(pass1) > 0) {
        return 1;
    }
    write("Passwords don't match\n");
    return 0;
}
```

:::warning
Always restore terminal echo after reading passwords. Use `catch` blocks or ensure the restore code runs even if errors occur to prevent leaving the terminal in a bad state.
:::

---

## Using POSIX termios

Pike's `Stdio.File.tcsetattr()` provides direct access to POSIX termios for fine-grained terminal control.

```pike
//-----------------------------
// Recipe: Terminal control with termios
//-----------------------------

// Save current settings
mapping old_settings = Stdio.File(STDIN)->tcgetattr();

// Create new settings (no echo, raw mode)
mapping new_settings = old_settings + ([]);
new_settings->c_lflag &= ~Constants.System.ECHO;
new_settings->c_lflag &= ~Constants.System.ICANON;

// Apply settings
STDIN->tcsetattr(new_settings);

// Read single character (non-blocking)
int ch;
while (ch == -1) {
    ch = (int)STDIN->read(1);
    // Do other work while waiting
}

// Restore original settings
STDIN->tcsetattr(old_settings);
```

---

## Checking for Waiting Input

Use `Stdio.File.peek()` or `select()` to check for available input without blocking.

```pike
//-----------------------------
// Recipe: Non-blocking input check
//-----------------------------

// Check if input is available
int has_input() {
    return STDIN->peek() != "";
}

// Wait for input with timeout
int wait_for_input(float timeout) {
    return select(({ STDIN }), ({}), ({}), timeout)[0];
}

// Read with timeout
string|zero read_with_timeout(float timeout) {
    if (!wait_for_input(timeout)) {
        return 0;
    }
    return STDIN->gets();
}
```

---

## Editing Input

`Stdio.Readline` automatically provides line editing (arrow keys, backspace, delete, home/end) and command history.

```pike
//-----------------------------
// Recipe: Readline with history and editing
//-----------------------------

class InteractiveShell {
    inherit Stdio.Readline;

    void create() {
        ::create();
        set_prompt("shell> ");

        // Enable history
        enable_history(100);

        // Load/save history
        read_history(".pike_history");
    }

    void run() {
        while (string line = read()) {
            if (sizeof(line)) {
                add_history(line);
                execute_command(line);
            }
        }

        write_history(".pike_history");
    }

    void execute_command(string cmd) {
        // Process command
        write("Executed: %s\n", cmd);
    }
}
```

---

## Managing the Screen

For complex terminal UIs, use NCurses or create your own screen management with ANSI codes and positioning.

```pike
//-----------------------------
// Recipe: Simple screen management
//-----------------------------

class Screen {
    array(array(string)) buffer;
    int width;
    int height;

    void create(int w, int h) {
        width = w;
        height = h;
        buffer = allocate(height, allocate(width, " "));
    }

    void clear() {
        buffer = allocate(height, allocate(width, " "));
    }

    void write(int x, int y, string text) {
        if (y >= 0 && y < height && x >= 0 && x < width) {
            buffer[y][x..x+sizeof(text)-1] = text;
        }
    }

    void refresh() {
        write("\033[2J\033[H");  // Clear and home
        foreach (buffer, array(string) line; int y) {
            write("\033[%d;0H%s\n", y+1, line * "");
        }
    }
}
```

---

## Creating GUI Applications with GTK2

GTK2 provides full-featured GUI development with Pike. Use lambda functions for callbacks and modern Pike 8 syntax.

```pike
//-----------------------------
// Recipe: Basic GTK2 window
//-----------------------------
#ifdef __GTK2__
import GTK2;

class SimpleWindow {
    inherit Window;

    void create(string title) {
        ::create(GTK2_WINDOW_TOPLEVEL);
        set_title(title);
        set_default_size(400, 300);

        // Connect signals with lambda functions
        signal_connect("destroy", lambda() {
            write("Exiting...\n");
            GTK2.main_quit();
        });

        setup_widgets();
    }

    void setup_widgets() {
        VBox vbox = VBox();
        add(vbox);

        // Add button
        Button btn = Button("Click Me");
        btn->signal_connect("clicked", lambda(mixed self) {
            write("Button clicked!\n");
        });
        vbox->pack_start(btn, 0, 0, 5);

        // Add text entry
        Entry entry = Entry();
        vbox->pack_start(entry, 0, 0, 5);
    }

    void run() {
        show();
        GTK2.main();
    }
}

int main(int argc, array(string) argv) {
    GTK2.setup_gtk(argc, argv);
    SimpleWindow app = SimpleWindow("Pike GTK2 Demo");
    app->run();
    return 0;
}
#else
int main() {
    write("GTK2 not available\n");
    return 1;
}
#endif
```

:::tip
GTK2 support is optional in Pike. Always wrap GTK2 code in `#ifdef __GTK2__` preprocessor directives and provide fallback behavior for systems without GTK2.
:::

---

## Event-Driven Programming

Pike's backend provides an event loop for timers, I/O events, and asynchronous operations.

```pike
//-----------------------------
// Recipe: Event loop and async I/O
//-----------------------------

class EventApplication {
    int running = 1;

    // Add timer event
    int add_timer(float delay, function callback) {
        return Pike.Backend()->call_out(callback, delay);
    }

    // Monitor file descriptor
    void add_io(Stdio.File file, function callback) {
        file->set_callback(callback);
        file->set_nonblocking(1, 0, Pike.POLLIN);
    }

    // Run event loop
    void run() {
        while (running) {
            Pike.Backend()->wait(1.0);
        }
    }

    void stop() {
        running = 0;
    }
}

// Example: Async HTTP client
class AsyncClient {
    inherit EventApplication;

    Protocols.HTTP.Query query;

    void fetch(string url, function cb) {
        query = Protocols.HTTP.Query();
        add_timer(30.0, lambda() {
            query->async_fetch(cb);
        });
    }
}
```

---

## Program: Interactive Menu System

Complete terminal-based menu system with keyboard navigation, using Readline and ANSI codes.

```pike
//-----------------------------
// Program: Full-Featured Terminal Menu System
//-----------------------------

class MenuSystem {
    inherit Stdio.Readline;

    array(string) items;
    int selected = 0;

    void create(array(string) opts) {
        ::create();
        items = opts;
        selected = 0;
    }

    void display() {
        write("\033[2J\033[H");  // Clear screen
        write("\033[1;36m=== Pike Menu ===\033[0m\n\n");

        foreach (items, string item; int i) {
            if (i == selected) {
                write("\033[7m");  // Reverse video
                write(">%2d. %s\033[0m\n", i+1, item);
            } else {
                write("  %d. %s\n", i+1, item);
            }
        }

        write("\nUse arrow keys, Enter to select, Q to quit\n");
    }

    int|zero navigate() {
        STDIN->tcsetattr(([ "ECHO": 0, "ICANON": 0 ]));

        while (1) {
            display();

            string input = read();
            int ch = (int)input[0];

            switch(ch) {
                case 'A':  // Up arrow
                    selected = (selected - 1 + sizeof(items)) % sizeof(items);
                    break;
                case 'B':  // Down arrow
                    selected = (selected + 1) % sizeof(items);
                    break;
                case '\r':  // Enter
                    STDIN->tcsetattr(([ "ECHO": 1, "ICANON": 1 ]));
                    return selected;
                case 'q':
                case 'Q':
                    STDIN->tcsetattr(([ "ECHO": 1, "ICANON": 1 ]));
                    return -1;
            }
        }
    }
}

int main() {
    array(string) menu_items = ({
        "File Operations",
        "Database Management",
        "Network Tools",
        "System Configuration",
        "Help",
        "Exit"
    });

    MenuSystem menu = MenuSystem(menu_items);
    int|zero choice = menu->navigate();

    if (choice >= 0) {
        write("\nYou selected: %s\n", menu->items[choice]);
    }

    return 0;
}
```

:::tip
This complete menu system demonstrates combining Readline, ANSI escape codes, and termios control for professional terminal UIs in Pike 8. The reverse video highlighting and arrow key navigation create an intuitive user experience.
:::

---

## See Also

- [Process Management](/docs/advanced/processes) - Inter-process communication
- [File Access](/docs/files/file-access) - File I/O operations
- [Network Programming](/docs/network/sockets) - Socket-based UIs
- [Classes](/docs/advanced/classes) - Object-oriented UI frameworks
