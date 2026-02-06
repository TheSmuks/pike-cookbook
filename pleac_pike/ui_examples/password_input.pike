#!/usr/bin/env pike
#pragma strict_types
// Recipe: Reading Passwords Securely

// Check if termios module is available
#if constant(Stdio.File.tcgetattr) || constant(Stdio.File.tcsetattr)

// Secure password input using termios (legacy approach)
// This method saves and restores full terminal state
string get_password(string|void prompt) {
    string p = prompt || "Password: ";

    // Save current terminal settings
    mapping old_settings = Stdio.stdin->tcgetattr();

    // Create new settings without echo
    mapping new_settings = copy_value(old_settings);
    // Note: For full termios control, modify the appropriate flags
    // For simpler cases, use get_password_modern() below

    // Apply new settings
    Stdio.stdin->tcsetattr(new_settings);

    // Display prompt (after disabling echo so it doesn't get affected)
    write(p);

    // Read password
    string password = Stdio.stdin->gets();

    // Restore original settings (CRITICAL: always restore terminal state)
    Stdio.stdin->tcsetattr(old_settings);

    // Output newline since user couldn't see their typing
    write("\n");

    return password || "";
}

// Modern Pike 8 version using tcsetattr array syntax
string get_password_modern(string|void prompt) {
    string p = prompt || "Password: ";
    write(p);

    // Disable echo using modern array syntax
    Stdio.stdin->tcsetattr((["ECHO": 0]));

    string password = Stdio.stdin->gets();

    // Restore echo
    Stdio.stdin->tcsetattr((["ECHO": 1]));

    write("\n");
    return password || "";
}

// Confirm password (enter twice)
int confirm_password(string prompt) {
    string pass1 = get_password(prompt);
    string pass2 = get_password("Confirm password: ");

    if (pass1 == pass2 && sizeof(pass1) > 0) {
        return 1;
    }

    write("Passwords don't match or are empty\n");
    return 0;
}

int main(int argc, array(string) argv) {
    // Check for interactive terminal using function type check
    if (!functionp(Stdio.stdin->isatty) || !Stdio.stdin->isatty()) {
        write("Password input requires an interactive terminal\n");
        return 1;
    }

    // Simple password input demo
    write("=== Simple Password Input ===\n");
    string password = get_password_modern("Enter your password: ");
    write(sprintf("Password entered (length: %d)\n", sizeof(password)));

    // Password confirmation demo
    write("\n=== Password Confirmation ===\n");
    if (confirm_password("Set new password: ")) {
        write("Password successfully set!\n");
    } else {
        write("Password setup failed\n");
    }

    // Password strength checker demo
    write("\n=== Password Strength Check ===\n");
    string pw = get_password("Enter password to check: ");

    int strength = 0;
    if (sizeof(pw) >= 8) strength++;
    if (sizeof(pw) >= 12) strength++;
    // Check for mixed case
    if (has_value(pw, lower_case(pw)) && has_value(pw, upper_case(pw))) strength++;
    // Check for special characters using Pike's String methods
    string special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?";
    int has_special = 0;
    foreach (special_chars / "";; string ch) {
        if (has_value(pw, ch)) {
            has_special = 1;
            break;
        }
    }
    if (has_special) strength++;

    array(string) levels = ({"Weak", "Fair", "Good", "Strong"});
    write(sprintf("Password strength: %s\n", levels[min(strength, 3)]));

    return 0;
}

#else

int main() {
    write("Termios module not available.\n");
    write("This example requires terminal I/O control for secure password input.\n");
    write("Password input without termios is insecure and not recommended.\n");
    write("\nFor testing purposes, you can use regular input (not secure):\n");
    write("  write('Password: ');\n");
    write("  string password = Stdio.stdin->gets();\n");
    return 0;
}

#endif
