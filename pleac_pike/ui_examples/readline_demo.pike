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
            write("Invalid choice. Please enter 1-%d\n", sizeof(options));
        }
    }
}

int main() {
    // Check if we have an interactive terminal
    if (!Stdio.isatty(STDIN->fd())) {
        write("This program requires an interactive terminal\n");
        return 1;
    }

    ReadlineUI readline = ReadlineUI(" Pike> ");

    // Simple input
    write("\n=== Simple Input ===\n");
    string name = readline->get_line();
    write("Hello, %s!\n", name);

    // Password input
    write("\n=== Password Input ===\n");
    string password = readline->get_password("Enter password: ");
    write("Password received (length: %d)\n", sizeof(password));

    // Confirmation
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
    write("You selected: %d\n", choice);

    // Multiline input
    write("\n=== Multiline Input ===\n");
    array(string) lines = readline->get_multiline();
    write("You entered %d lines\n", sizeof(lines));

    return 0;
}
