---
id: userinterfaces
title: User Interfaces
sidebar_label: User Interfaces
---

## Introduction

```pike
// User Interfaces in Pike 8
// Demonstrating terminal, console, and GUI programming

// Available UI modules:
// - Stdio.Readline: Interactive console input
// - GTK2/GTK3: Graphical user interfaces
// - NCurses: Terminal screen management
// - ANSI escape codes: Terminal control

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

## Parsing Program Arguments

```pike
// Recipe 15.1: Parsing Program Arguments with Getopt
import Getopt;

int verbose;
string output_file;
int number;

// Define all options
foreach (find_all_options(argv, ((
    ({"help", NO_ARG, ({"-h", "--help"})}),
    ({"verbose", NO_ARG, ({"-v", "--verbose"})}),
    ({"output", HAS_ARG, ({"-o", "--output"})}),
    ({"number", HAS_ARG, ({"-n", "--number"})}),
}), array(string) opt) {
    switch(opt[0]) {
        case "help":
            usage();
            return 0;
        case "verbose":
            verbose = 1;
            break;
        case "output":
            output_file = opt[1];
            break;
        case "number":
            number = (int)opt[1];
            break;
```