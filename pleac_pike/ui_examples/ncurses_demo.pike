#!/usr/bin/env pike
#pragma strict_types
// Recipe: NCurses Terminal UI with Pike

// Note: NCurses module must be available
// This demonstrates the structure for NCurses programming

#ifdef __NCURSES__

import NCurses;

class NCursesWindow {
    inherit Window;

    void create(int height, int width, int starty, int startx) {
        ::create(height, width, starty, startx);
        keypad(1);  // Enable function keys
    }

    // Draw a box border
    void draw_box() {
        box(0, 0);
    }

    // Draw centered title
    void draw_title(string title) {
        int width = getmaxx();
        int x = (width - sizeof(title)) / 2;
        mvaddstr(0, x, title);
        refresh();
    }

    // Write centered text
    void write_centered(int line, string text) {
        int width = getmaxx();
        int x = (width - sizeof(text)) / 2;
        mvaddstr(line, x, text);
        refresh();
    }
}

class MenuWindow {
    inherit NCursesWindow;

    array(string) items;
    int selected = 0;

    void create(int height, int width, int starty, int startx, array(string) opts) {
        ::create(height, width, starty, startx);
        items = opts;
    }

    void draw() {
        erase();
        draw_box();

        for (int i = 0; i < sizeof(items); i++) {
            if (i == selected) {
                standout();  // Highlight selection
            }
            mvaddstr(i + 1, 2, sprintf("%2d. %s", i + 1, items[i]));
            if (i == selected) {
                standend();  // Reset highlighting
            }
        }
        refresh();
    }

    int navigate() {
        draw();

        while (1) {
            int ch = getch();

            switch (ch) {
                case KEY_UP:
                    selected = (selected - 1 + sizeof(items)) % sizeof(items);
                    break;
                case KEY_DOWN:
                    selected = (selected + 1) % sizeof(items);
                    break;
                case '\n':  // Enter
                case '\r':
                    return selected;
                case 27:  // Escape
                    return -1;
                default:
                    beep();
                    continue;
            }
            draw();
        }
    }
}

class FormWindow {
    inherit NCursesWindow;

    mapping(string:string) fields = ([]);
    array(string) field_names;
    int current_field = 0;

    void create(int height, int width, int starty, int startx, array(string) names) {
        ::create(height, width, starty, startx);
        field_names = names;
        foreach(names, string name) {
            fields[name] = "";
        }
    }

    void draw() {
        erase();
        draw_box();
        draw_title("Data Entry Form");

        for (int i = 0; i < sizeof(field_names); i++) {
            string name = field_names[i];
            int y = i * 2 + 2;

            mvaddstr(y, 2, sprintf("%-15s:", name));

            if (i == current_field) {
                standout();
            }
            mvaddstr(y + 1, 4, sprintf("%-30s", fields[name] || ""));
            if (i == current_field) {
                standend();
            }
        }
        refresh();
    }

    mapping(string:string) edit() {
        draw();

        while (1) {
            int ch = getch();

            switch (ch) {
                case KEY_UP:
                    if (current_field > 0) current_field--;
                    break;
                case KEY_DOWN:
                case '\t':
                    if (current_field < sizeof(field_names) - 1) {
                        current_field++;
                    }
                    break;
                case '\n':
                case '\r':
                    return fields;
                case 27:  // Escape
                    return 0;
                case KEY_BACKSPACE:
                case 127:
                    string name = field_names[current_field];
                    string val = fields[name];
                    if (sizeof(val) > 0) {
                        fields[name] = val[0..<1];
                    }
                    break;
                default:
                    if (ch >= 32 && ch <= 126) {
                        name = field_names[current_field];
                        fields[name] += sprintf("%c", ch);
                    }
                    break;
            }
            draw();
        }
    }
}

int main() {
    // Initialize NCurses
    initscr();
    cbreak();
    noecho();
    nonl();
    intrflush(0, 0);
    keypad(0, 1);

    // Enable colors if available
    if (has_colors()) {
        start_color();
        init_pair(1, COLOR_RED, COLOR_BLACK);
        init_pair(2, COLOR_GREEN, COLOR_BLACK);
        init_pair(3, COLOR_BLUE, COLOR_BLACK);
    }

    // Get screen dimensions
    int max_y, max_x;
    getmaxyx(stdscr, max_y, max_x);

    // Create main window
    NCursesWindow main_win = NCursesWindow(max_y - 5, max_x - 10, 2, 5);
    main_win->draw_box();
    main_win->draw_title("Pike NCurses Demo");

    // Show welcome message
    main_win->write_centered(max_y / 2 - 5, "Welcome to Pike NCurses!");
    main_win->write_centered(max_y / 2 - 3, "Press any key to continue...");
    main_win->refresh();
    getch();

    // Create menu
    MenuWindow menu = MenuWindow(12, 40, 5, (max_x - 40) / 2, ({
        "View System Information",
        "Edit Configuration",
        "Process Data",
        "Show Logs",
        "Exit"
    }));

    int choice = menu->navigate();
    menu->destroy();

    // Process menu choice
    if (choice >= 0) {
        main_win->erase();
        main_win->draw_box();
        main_win->draw_title("Selected Option");
        main_win->write_centered(max_y / 2, sprintf("You chose: %s", menu->items[choice]));
        main_win->refresh();
        getch();
    }

    // Create form
    FormWindow form = FormWindow(15, 50, 5, (max_x - 50) / 2, ({
        "Name",
        "Email",
        "Phone",
        "Department"
    }));

    mapping(string:string) data = form->edit();
    form->destroy();

    if (data) {
        main_win->erase();
        main_win->draw_box();
        main_win->draw_title("Form Data");

        int y = max_y / 2 - 5;
        foreach (indices(data), string field) {
            main_win->mvaddstr(y++, 10, sprintf("%-15s: %s", field, data[field]));
        }
        main_win->refresh();
        getch();
    }

    // Cleanup
    endwin();

    write("NCurses demo completed.\n");
    return 0;
}

#else

int main() {
    write("NCurses module not available.\n");
    write("This example requires NCurses support for Pike.\n");
    write("\nDemonstrating terminal UI with ANSI escape codes instead:\n\n");

    // Fallback: Simple menu with ANSI codes
    array(string) menu_items = ({
        "View System Information",
        "Edit Configuration",
        "Process Data",
        "Show Logs",
        "Exit"
    });

    write("\033[2J\033[H");  // Clear screen
    write("\033[1;36m=== Pike Terminal UI Demo ===\033[0m\n\n");

    foreach (menu_items; int i; string item) {
        write("  %d. %s\n", i + 1, item);
    }

    write("\nSelect option: ");
    string input = Stdio.stdin->gets();
    int choice = (int)input;

    if (choice > 0 && choice <= sizeof(menu_items)) {
        write("\nYou selected: %s\n", menu_items[choice - 1]);
    }

    return 0;
}

#endif
