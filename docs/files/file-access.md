---
id: file-access
title: File Access
sidebar_label: File Access
---

# File Access

## Introduction

File access is one of the most common operations in programming. Pike provides multiple ways to read and write files, from convenience functions to fine-grained control.

:::tip
- **Quick scripts**: Use `Stdio.read_file()` and `Stdio.write_file()`
- **Large files**: Use file handles with `Stdio.File()`
- **Line-by-line**: Use `line_iterator()` or buffered I/O
:::

---

## Reading Whole Files

### Convenience Method - Stdio.read_file()

```pike
//-----------------------------
// Recipe: Read entire file at once
//-----------------------------

// Read entire file into a string
string content = Stdio.read_file("/usr/local/widgets/data");

if (!content) {
    werror("Couldn't open file for reading\n");
    exit(1);
}

// Process the content
foreach(content / "\n";; string line) {
    if (search(line, "blue") != -1) {
        write("%s\n", line);
    }
}
```

:::tip
`Stdio.read_file()` is the easiest way to read small to medium files. It returns `0` (not an empty string) on failure.
:::

### Reading with File Handle

```pike
//-----------------------------
// Recipe: Read file with more control
//-----------------------------

Stdio.File file = Stdio.File("/usr/local/widgets/data", "r");

if (!file) {
    werror("Couldn't open file for reading\n");
    exit(1);
}

// Read line by line using iterator
foreach(file->line_iterator();; string line) {
    if (search(line, "blue") != -1) {
        write("%s\n", line);
    }
}

file->close();
```

---

## Opening Files

### File Open Modes

```pike
//-----------------------------
// Recipe: Open files with different modes
//-----------------------------

string path = "/path/to/file.txt";

// Read existing file
string content = Stdio.read_file(path);
Stdio.File file = Stdio.File(path, "r");

// Write new file (create or truncate)
Stdio.write_file(path, "content");
Stdio.File file = Stdio.File(path, "wc");

// Write with permissions (octal)
Stdio.write_file(path, "content", 0600);
Stdio.File file = Stdio.File(path, "wc", 0600);

// Append to file
Stdio.append_file(path, "new content\n");
Stdio.File file = Stdio.File(path, "wac");

// Read and write (update mode)
Stdio.File file = Stdio.File(path, "rw");

// Create new file (must not exist)
Stdio.File file = Stdio.File(path, "wcx");

// Append (file must exist)
Stdio.File file = Stdio.File(path, "wacx");
```

### Mode Quick Reference

| Mode | Description | Creates | Truncates |
|------|-------------|---------|-----------|
| `"r"` | Read only | No | No |
| `"w"` | Write only | Yes | Yes |
| `"a"` | Append | Yes | No |
| `"rw"` | Read/write | Yes | No |
| `"wc"` | Write create | Yes | Yes |
| `"wac"` | Write append create | Yes | No |
| `"wcx"` | Write create exclusive | Yes | Yes |
| `"rwcx"` | Read/write create exclusive | Yes | No |

:::warning
Be careful with mode `"wc"` - it **overwrites** existing files without warning!
:::

---

## Standard Input/Output

### Reading from STDIN

```pike
//-----------------------------
// Recipe: Read from standard input
//-----------------------------

// Read all input from stdin
foreach(Stdio.stdin;; string line) {
    // Process each line
    int has_digit = sizeof(array_sscanf(line, "%*s%d"));
    if (!has_digit) {
        werror("No digit found in: %s", line);
    }

    write("Read: %s\n", line);
}

// Read with line iteration
foreach(Stdio.stdin->line_iterator();; string line) {
    write("Got: %s\n", String.trim_whites(line));
}

// Write to STDOUT and STDERR
write("This goes to stdout\n");
werror("This goes to stderr\n");
```

### Redirecting Output

```pike
//-----------------------------
// Recipe: Switch output destination
//-----------------------------

// Create log file
Stdio.File logfile = Stdio.File("/tmp/log", "wc");

// Make write() point to log file
function write_orig = write;
function write = logfile->write;

write("This goes to log file\n");

// Restore stdout
write = write_orig;
write("Back to stdout\n");

// Close log
logfile->close();
```

---

## Writing Files

### Write Entire File

```pike
//-----------------------------
// Recipe: Write complete file
//-----------------------------

// Simple write
Stdio.write_file("/tmp/output.txt", "Hello, World!\n");

// Write with permissions
Stdio.write_file("/tmp/sensitive.txt", "Secret data\n", 0600);

// Append to file
Stdio.append_file("/tmp/log.txt", sprintf("[%s] Entry\n", ctime(time())));
```

### Writing with File Handle

```pike
//-----------------------------
// Recipe: Write with buffered output
//-----------------------------

// Stdio.File is unbuffered - use Stdio.FILE for buffered writes
Stdio.FILE file = Stdio.FILE();

if (!file->open("/tmp/output.txt", "wc")) {
    werror("Failed to open file\n");
    exit(1);
}

// Write line by line
for (int i = 1; i <= 10; i++) {
    file->write("Line %d\n", i);
}

file->close();
```

---

## Line-by-Line Processing

### Reading Lines

```pike
//-----------------------------
// Recipe: Process file line by line
//-----------------------------

Stdio.File file = Stdio.File("data.txt", "r");

if (!file) {
    werror("Cannot open file\n");
    exit(1);
}

// Method 1: Using line_iterator()
foreach(file->line_iterator();; string line) {
    line = String.trim_whites(line);
    if (sizeof(line)) {
        write("Processing: %s\n", line);
    }
}

// Method 2: Manual line reading
file->seek(0);  // Reset to beginning
string line;
while ((line = file->gets())) {
    if (sizeof(String.trim_whites(line))) {
        write("Processing: %s\n", line);
    }
}

file->close();
```

### Buffered Line Reading

```pike
//-----------------------------
// Recipe: Use buffered I/O for lines
//-----------------------------

// Stdio.FILE provides buffered line reading
Stdio.FILE file = Stdio.FILE();

if (!file->open("data.txt", "r")) {
    werror("Cannot open file\n");
    exit(1);
}

// gets() reads a line (removes newline)
string line;
while ((line = file->gets())) {
    write("Line: %s\n", String.trim_whites(line));
}

file->close();
```

---

## File Position and Seeking

### Random Access

```pike
//-----------------------------
// Recipe: Jump to specific file position
//-----------------------------

Stdio.File file = Stdio.File("data.bin", "r");

if (!file) {
    werror("Cannot open file\n");
    exit(1);
}

// Get current position
int pos = file->tell();
write("Current position: %d\n", pos);

// Seek to beginning
file->seek(0);

// Seek to end
file->seek(0, SEEK_END);
int file_size = file->tell();
write("File size: %d bytes\n", file_size);

// Seek to middle
file->seek(file_size / 2);

// Read from current position
string data = file->read(1024);
write("Read %d bytes from middle\n", sizeof(data));

file->close();
```

---

## Binary File Operations

### Read Binary Data

```pike
//-----------------------------
// Recipe: Read binary file
//-----------------------------

Stdio.File file = Stdio.File("image.png", "r");

if (!file) {
    werror("Cannot open file\n");
    exit(1);
}

// Read specific number of bytes
string header = file->read(8);
write("Header: %O\n", header);

// Check PNG signature
if (header == "\x89PNG\r\n\x1a\n") {
    write("This is a PNG file\n");
}

// Read rest of file
string image_data = file->read();
write("Image data size: %d bytes\n", sizeof(image_data));

file->close();
```

### Write Binary Data

```pike
//-----------------------------
// Recipe: Write binary file
//-----------------------------

// Create binary data
string binary_data = "\x89PNG\r\n\x1a\n";
binary_data += sprintf("%4c", 13, 14, 15, 16);  // Write 4 bytes

// Write to file
Stdio.File file = Stdio.File("output.bin", "wc");

if (!file) {
    werror("Cannot create file\n");
    exit(1);
}

file->write(binary_data);
file->close();
```

---

## Temporary Files

### Create Temporary File

```pike
//-----------------------------
// Recipe: Create safe temporary file
//-----------------------------

Stdio.File fh;
string name;

// Try until we find an unused name
do {
    name = "/tmp/" + MIME.encode_base64(random_string(10));
    fh = Stdio.File(name, "rwcx");
} while (!fh);

write("Created temp file: %s\n", name);

// Use the file
fh->write("Temporary data\n");

// Set up cleanup on exit
atexit(lambda() {
    fh->close();
    rm(name);
});
```

### In-Memory File

```pike
//-----------------------------
// Recipe: Use FakeFile for in-memory operations
//-----------------------------

// FakeFile behaves like a file but lives in memory
Stdio.FakeFile memfile = Stdio.FakeFile();

memfile->write("Line 1\n");
memfile->write("Line 2\n");
memfile->write("Line 3\n");

// Reset to beginning
memfile->seek(0);

// Read back
foreach(memfile->line_iterator();; string line) {
    write("Read: %s", line);
}
```

---

## File Information

### Get File Metadata

```pike
//-----------------------------
// Recipe: Get file statistics
//-----------------------------

string path = __FILE__;  // Current script
object stat = file_stat(path);

if (stat) {
    write("File: %s\n", path);
    write("Size: %d bytes\n", stat->size);
    write("Modified: %s\n", ctime(stat->mtime));
    write("Permissions: %o\n", stat->mode);
    write("Is directory: %s\n", stat->isdir ? "yes" : "no");
    write("Is regular file: %s\n", stat->isreg ? "yes" : "no");

    // Human-readable size
    int kilosize = stat->size / 1024;
    write("Size: %d KB\n", kilosize);
}
```

---

## Error Handling

### Proper Error Checking

```pike
//-----------------------------
// Recipe: Handle file errors gracefully
//-----------------------------

string path = "/path/to/file.txt";

// Method 1: Check return value
string content = Stdio.read_file(path);
if (!content) {
    werror("Failed to read %s\n", path);
    exit(1);
}

// Method 2: Use catch()
mixed error = catch {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) {
        error("Failed to open file\n");
    }

    // ... process file ...

    file->close();
};

if (error) {
    werror("Error: %s\n", describe_error(error));
    exit(1);
}

// Method 3: Detailed error with errno
Stdio.File file = Stdio.File(path, "r");
if (!file) {
    werror("Cannot open %s: %s\n", path, strerror(errno()));
    exit(1);
}
```

---

## Practical Examples

### Count Lines in File

```pike
//-----------------------------
// Recipe: Count lines efficiently
//-----------------------------

int count_lines(string path) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return 0;

    int count = 0;
    foreach(file->line_iterator();; string line) {
        count++;
    }

    file->close();
    return count;
}

write("Lines: %d\n", count_lines("/etc/passwd"));
```

### Find and Replace in File

```pike
//-----------------------------
// Recipe: Replace text in file
//-----------------------------

void replace_in_file(string path, string search, string replace) {
    string content = Stdio.read_file(path);
    if (!content) {
        werror("Cannot read file\n");
        return;
    }

    // Replace all occurrences
    string new_content = String.replace(content, search, replace);

    // Write back
    Stdio.write_file(path, new_content);
}

// Usage
replace_in_file("config.txt", "old_value", "new_value");
```

### Process CSV File

```pike
//-----------------------------
// Recipe: Parse CSV data
//----------------------------/

void process_csv(string path) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) {
        werror("Cannot open CSV\n");
        return;
    }

    // Skip header
    file->gets();

    // Process data rows
    int row_num = 1;
    foreach(file->line_iterator();; string line) {
        row_num++;

        // Split by comma
        array(string) fields = String.split(line, ",");

        if (sizeof(fields) >= 3) {
            string name = String.trim_whites(fields[0]);
            int age = (int)fields[1];
            string city = String.trim_whites(fields[2]);

            write("Row %d: %s, %d, %s\n", row_num, name, age, city);
        }
    }

    file->close();
}

// Usage
// process_csv("data.csv");
```

### Copy File

```pike
//-----------------------------
// Recipe: Copy file with progress
//----------------------------/

int copy_file(string src, string dst) {
    Stdio.File source = Stdio.File(src, "r");
    if (!source) {
        werror("Cannot open source\n");
        return 0;
    }

    Stdio.File dest = Stdio.File(dst, "wc");
    if (!dest) {
        werror("Cannot create destination\n");
        source->close();
        return 0;
    }

    // Copy in chunks
    int chunk_size = 65536;  // 64KB
    int total = 0;
    string chunk;

    while ((chunk = source->read(chunk_size))) {
        dest->write(chunk);
        total += sizeof(chunk);

        if (total % (1024 * 1024) == 0) {
            write("Copied %d MB\n", total / (1024 * 1024));
        }
    }

    source->close();
    dest->close();

    write("Copied %d bytes total\n", total);
    return 1;
}
```

---

## See Also

- [File Contents](/docs/files/file-contents) - Advanced file processing
- [Directories](/docs/files/directories) - Directory operations
- [Database Access](/docs/files/database-access) - Database integration
- [Strings](/docs/basics/strings) - Text processing
