#!/usr/bin/env pike
#pragma strict_types
// Recipe: Reading from the Keyboard with Stdio.Readline

// Modern Pike 8 Readline wrapper
class ReadlineUI(string|void prompt) {
    inherit Stdio.Readline;

    void create(string|void p) {
        ::create();
        set_prompt(p || "> ");
    }

    // Get a line with history support
    string get_line() {
        return read();
    }

    // Get password without echo
    string get_password(string|void prompt) {
        string p = prompt || "Password: ";
        write(p);

        // Disable echo
        Stdio.stdin->tcsetattr(([
            "ECHO": 0,
        ]));

        string pass = Stdio.stdin->gets();

        // Restore echo
        Stdio.stdin->tcsetattr(([
            "ECHO": 1,
        ]));

        write("\n");
        return pass;
    }

    // Get multiline input
    array(string) get_multiline() {
        array(string) lines = ({});
        string line;

        write("Enter text (empty line to finish):\n");
        while ((line = read()) && line != "") {
            lines += ({line});
        }
        return lines;
    }

    // Confirm with y/n
    int confirm(string question) {
        string old_prompt = get_prompt();
        set_prompt(question + " [y/N]: ");
        string answer = lower_case(read() || "");
        set_prompt(old_prompt);
        return answer == "y" || answer == "yes";
    }

    // Menu selection
    int menu(string title, array(string) options) {
        write(sprintf("\n%s\n", title));
        for (int i = 0; i < sizeof(options); i++) {
            write(sprintf("  %d. %s\n", i + 1, options[i]));
        }

        while (1) {
            set_prompt("Choose: ");
            string input = read();
            int choice = (int)input;

            if (choice > 0 && choice <= sizeof(options)) {
                return choice - 1;
            }
            write(sprintf("Invalid choice. Please enter 1-%d\n", sizeof(options)));
        }
    }
}

int main(int argc, array(string) argv) {
    // Check if Readline module is available
    if (!objectp(Stdio.Readline())) {
        write("Stdio.Readline not available on this system.\n");
        write("Falling back to basic input.\n\n");

        // Basic fallback demo
        write("=== Basic Input Demo ===\n");
        write("Enter your name: ");
        string name = Stdio.stdin->gets();
        write(sprintf("Hello, %s!\n", name || "stranger"));
        return 0;
    }

    // Check for interactive terminal using function type check
    if (!functionp(Stdio.stdin->isatty) || !Stdio.stdin->isatty()) {
        write("This program requires an interactive terminal\n");
        return 1;
    }

    // Create readline interface with custom prompt
    ReadlineUI readline = ReadlineUI(" Pike> ");

    // Simple input with history
    write("\n=== Simple Input ===\n");
    string name = readline->get_line();
    write(sprintf("Hello, %s!\n", name));

    // Password input (no echo)
    write("\n=== Password Input ===\n");
    string password = readline->get_password("Enter password: ");
    write(sprintf("Password received (length: %d)\n", sizeof(password)));

    // Confirmation prompt
    write("\n=== Confirmation ===\n");
    if (readline->confirm("Do you want to continue?")) {
        write("User chose to continue\n");
    } else {
        write("User chose to stop\n");
    }

    // Menu selection
    write("\n=== Menu Selection ===\n");
    int choice = readline->menu("Select an option:", ({
        "Create new file",
        "Open existing file",
        "Save and exit",
        "Quit without saving",
    }));
    write(sprintf("You selected: %d\n", choice));

    // Multiline input (empty line to finish)
    write("\n=== Multiline Input ===\n");
    array(string) lines = readline->get_multiline();
    write(sprintf("You entered %d lines\n", sizeof(lines)));

    return 0;
}
