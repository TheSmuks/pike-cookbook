---
id: file-contents
title: File Contents
sidebar_label: File Contents
---

## File Contents

### Introduction

### Reading Lines with Continuation Characters

### Counting Lines (or Paragraphs or Records) in a File

```pike
// Does not check file existence but return a correct value with empty (size=0) files
// Does count paragraphs correctly (does not count empty lines (\n\n))
int main(int argc, array(string) argv) {
    int count=0;
    object f = Stdio.FILE(argv[1]);
    foreach(f->line_iterator(f); int number; string paragraph) {
        count++;
        // write(number+" "+paragraph+"\n");
    }
    write("number of paragraphs= "+count+"\n");
    return 0;
}
```

### Processing Every Word in a File

### Reading a File Backwards by Line or Paragraph

### Trailing a Growing File

### Picking a Random Line from a File

### Randomizing All Lines

### Reading a Particular Line in a File

### Processing Variable-Length Text Fields

### Removing the Last Line of a File

### Processing Binary Files

### Using Random-Access I/O

### Updating a Random-Access File

### Reading a String from a Binary File

### Reading Fixed-Length Records

### Reading Configuration Files

### Testing a File for Trustworthiness

### Program: tailwtmp

### Program: tctee

### Program: laston