#!/usr/bin/env pike
#pragma strict_types
// Recipe: Creating GUI Applications with GTK2

// Note: GTK2 module must be available
// Compile with: pike -M GTK2 gtk2_demo.pike

#ifdef __GTK2__
import GTK2;

// Main GTK2 application class
class GTKApplication {
    inherit Window;

    void create(string title) {
        // Create main window
        ::create(GTK2_WINDOW_TOPLEVEL);
        set_title(title);
        set_default_size(400, 300);

        // Connect close event
        signal_connect("destroy", lambda() {
            write("Shutting down...\n");
            GTK2.main_quit();
        });

        // Add UI elements
        setup_ui();
    }

    void setup_ui() {
        // Create vertical box container
        VBox vbox = VBox(0, 5);
        add(vbox);

        // Create menu bar
        setup_menu(vbox);

        // Create toolbar
        setup_toolbar(vbox);

        // Create main text area
        TextView text_view = TextView();
        text_view->set_editable(1);
        text_view->set_wrap_mode(GTK2_WRAP_WORD);

        ScrolledWindow scroll = ScrolledWindow(0, 0);
        scroll->set_policy(GTK2_POLICY_AUTOMATIC, GTK2_POLICY_AUTOMATIC);
        scroll->add(text_view);
        vbox->pack_start(scroll, 1, 1, 0);

        // Create status bar
        Statusbar status = Statusbar();
        status->push(0, "Ready");
        vbox->pack_start(status, 0, 0, 0);

        // Show all widgets
        show_all();
    }

    void setup_menu(VBox vbox) {
        // Menu bar
        MenuBar menubar = MenuBar();

        // File menu
        Menu file_menu = Menu();
        MenuItem file_item = MenuItem("_File");
        file_item->set_submenu(file_menu);
        menubar->append(file_item);

        // File menu items
        MenuItem new_item = MenuItem("_New");
        new_item->signal_connect("activate", new_callback);
        file_menu->append(new_item);

        MenuItem open_item = MenuItem("_Open");
        open_item->signal_connect("activate", open_callback);
        file_menu->append(open_item);

        file_menu->append(SeparatorMenuItem());

        MenuItem quit_item = MenuItem("_Quit");
        quit_item->signal_connect("activate", lambda() {
            GTK2.main_quit();
        });
        file_menu->append(quit_item);

        // Help menu
        Menu help_menu = Menu();
        MenuItem help_item = MenuItem("_Help");
        help_item->set_submenu(help_menu);
        menubar->append(help_item);

        MenuItem about_item = MenuItem("_About");
        about_item->signal_connect("activate", about_callback);
        help_menu->append(about_item);

        vbox->pack_start(menubar, 0, 0, 0);
    }

    void setup_toolbar(VBox vbox) {
        Toolbar toolbar = Toolbar();
        toolbar->set_orientation(GTK2_ORIENTATION_HORIZONTAL);
        toolbar->set_style(GTK2_TOOLBAR_BOTH);

        // New button
        Button new_btn = Button(Stock::NEW);
        new_btn->signal_connect("clicked", new_callback);
        toolbar->append(new_btn);

        // Open button
        Button open_btn = Button(Stock::OPEN);
        open_btn->signal_connect("clicked", open_callback);
        toolbar->append(open_btn);

        // Save button
        Button save_btn = Button(Stock::SAVE);
        save_btn->signal_connect("clicked", save_callback);
        toolbar->append(save_btn);

        toolbar->append(SeparatorToolItem());

        // Quit button
        Button quit_btn = Button(Stock::QUIT);
        quit_btn->signal_connect("clicked", lambda() {
            GTK2.main_quit();
        });
        toolbar->append(quit_btn);

        vbox->pack_start(toolbar, 0, 0, 0);
    }

    // Callback functions
    void new_callback() {
        write("New clicked\n");
        // Show dialog
        MessageDialog dialog = MessageDialog(
            this,
            GTK2_DIALOG_MODAL,
            GTK2_MESSAGE_INFO,
            GTK2_BUTTONS_OK,
            "Creating new file..."
        );
        dialog->run();
        dialog->destroy();
    }

    void open_callback() {
        write("Open clicked\n");

        // File chooser dialog
        FileChooserDialog dialog = FileChooserDialog(
            "Open File",
            this,
            GTK2_FILE_CHOOSER_ACTION_OPEN,
            ([
                Stock::CANCEL: GTK2_RESPONSE_CANCEL,
                Stock::OPEN: GTK2_RESPONSE_ACCEPT,
            ])
        );

        int response = dialog->run();
        if (response == GTK2_RESPONSE_ACCEPT) {
            string filename = dialog->get_filename();
            write("Selected: %s\n", filename);
        }

        dialog->destroy();
    }

    void save_callback() {
        write("Save clicked\n");
    }

    void about_callback() {
        // About dialog
        AboutDialog dialog = AboutDialog();
        dialog->set_program_name("Pike GTK2 Demo");
        dialog->set_version("1.0");
        dialog->set_comments("Demonstration of GTK2 with Pike 8");
        dialog->set_website("https://pike.lysator.liu.se/");
        dialog->run();
        dialog->destroy();
    }

    void run() {
        show();
        GTK2.main();
    }
}

int main(int argc, array(string) argv) {
    // Initialize GTK2
    GTK2.setup_gtk(argc, argv);

    // Create and run application
    GTKApplication app = GTKApplication("Pike GTK2 Demo");
    app->run();

    return 0;
}

#else

int main() {
    write("GTK2 module not available.\n");
    write("Please install GTK2 support for Pike.\n");
    write("This example requires the GTK2 module.\n");
    return 1;
}

#endif
