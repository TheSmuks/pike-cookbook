#!/usr/bin/env pike
#pragma strict_types
// Recipe: Reading Passwords Securely

// Secure password input using termios
string get_password(string|void prompt) {
    string p = prompt || "Password: ";

    // Save current terminal settings
    mapping old_settings = Stdio.stdin->tcgetattr();

    // Create new settings without echo
    mapping new_settings = copy_value(old_settings);
    // Note: ECHO flag handling - in Pike 8, use modern approach below

    // Apply new settings
    Stdio.stdin->tcsetattr(new_settings);

    // Display prompt (after disabling echo so it doesn't get affected)
    write(p);

    // Read password
    string password = Stdio.stdin->gets();

    // Restore original settings
    Stdio.stdin->tcsetattr(old_settings);

    // Output newline since user couldn't
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

int main() {
    if (!Stdio.stdin->isatty || !Stdio.stdin->isatty()) {
        write("Password input requires an interactive terminal\n");
        return 1;
    }

    // Simple password
    write("=== Simple Password Input ===\n");
    string password = get_password_modern("Enter your password: ");
    write(sprintf("Password entered (length: %d)\n", sizeof(password)));

    // Password confirmation
    write("\n=== Password Confirmation ===\n");
    if (confirm_password("Set new password: ")) {
        write("Password successfully set!\n");
    } else {
        write("Password setup failed\n");
    }

    // Password strength check
    write("\n=== Password Strength Check ===\n");
    string pw = get_password("Enter password to check: ");

    int strength = 0;
    if (sizeof(pw) >= 8) strength++;
    if (sizeof(pw) >= 12) strength++;
    if (has_value(pw, lower_case(pw)) && has_value(pw, upper_case(pw))) strength++;
    // Check for special characters
    string special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?";
    int has_special = 0;
    for (int i = 0; i < sizeof(special_chars); i++) {
        if (has_value(pw, special_chars[i..i])) {
            has_special = 1;
            break;
        }
    }
    if (has_special) strength++;

    array(string) levels = ({"Weak", "Fair", "Good", "Strong"});
    write(sprintf("Password strength: %s\n", levels[min(strength, 3)]));

    return 0;
}
