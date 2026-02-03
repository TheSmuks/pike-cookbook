---
id: file-contents
title: File Contents
sidebar_label: File Contents
---

# File Contents

## Introduction

Processing file contents efficiently is crucial for data manipulation, parsing, and transformation tasks. This section covers advanced techniques for reading, processing, and writing file data in Pike 8.

**What this covers:**
- Reading files with continuation characters
- Counting lines, paragraphs, and records
- Processing files word-by-word and backwards
- Handling binary files and random access
- Working with configuration files

**Why use it:**
- Process large files efficiently without loading everything into memory
- Parse structured data formats (CSV, JSON, XML)
- Transform and analyze text data
- Build data processing pipelines

:::tip
For basic file operations, see [File Access](/docs/files/file-access). This section focuses on advanced content processing.
:::

---

## Reading Lines with Continuation Characters

### Continuation Line Processing

```pike
//-----------------------------
// Recipe: Process lines with backslash continuations
//-----------------------------

// Read file and merge continuation lines
array(string) read_continued_lines(string path) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) {
        werror("Cannot open file\n");
        return ({});
    }

    array(string) result = ({});
    string current_line = "";

    foreach(file->line_iterator();; string raw_line) {
        // Trim whitespace
        string line = String.trim_whites(raw_line);

        // Check if line ends with backslash continuation
        if (sizeof(line) && line[-1] == '\\') {
            // Remove backslash and accumulate
            current_line += line[0..sizeof(line)-2];
        } else {
            // Add current accumulated line + this line
            current_line += line;
            result += ({current_line});
            current_line = "";
        }
    }

    file->close();
    return result;
}

// Usage
array(string) lines = read_continued_lines("config.txt");
foreach(lines; int i; string line) {
    write("Line %d: %s\n", i+1, line);
}
```

---

## Counting Lines (or Paragraphs or Records) in a File

### Line Counter with Empty Line Handling

```pike
//-----------------------------
// Recipe: Count lines or paragraphs accurately
//-----------------------------

int count_lines(string path, void|bool count_paragraphs) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return 0;

    int count = 0;

    if (count_paragraphs) {
        // Count non-empty paragraphs (separated by blank lines)
        int in_paragraph = 0;

        foreach(file->line_iterator();; string line) {
            string trimmed = String.trim_whites(line);

            if (sizeof(trimmed)) {
                if (!in_paragraph) {
                    count++;
                    in_paragraph = 1;
                }
            } else {
                in_paragraph = 0;
            }
        }
    } else {
        // Count all lines including empty ones
        foreach(file->line_iterator();; string line) {
            count++;
        }
    }

    file->close();
    return count;
}

// Usage
int lines = count_lines("data.txt");
int paragraphs = count_lines("data.txt", true);
write("Lines: %d, Paragraphs: %d\n", lines, paragraphs);
```

:::note
Using `line_iterator()` automatically handles different line ending styles (\n, \r\n, \r).
:::

---

## Processing Every Word in a File

### Word-by-Word Processing

```pike
//-----------------------------
// Recipe: Process each word in a file
//-----------------------------

void process_words(string path, function(string:void) callback) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return;

    foreach(file->line_iterator();; string line) {
        // Split line into words (whitespace-separated)
        array(string) words = String.normalize_space(line) / " ";

        foreach(words; string word) {
            // Skip empty strings
            if (sizeof(word)) {
                callback(word);
            }
        }
    }

    file->close();
}

// Usage: word frequency counter
mapping(string:int) word_freq = ([]);

process_words("text.txt", lambda(string word) {
    word = lower_case(word);
    word_freq[word]++;
});

// Display top 10 words
array(string) sorted_words = indices(word_freq);
sort(word_freq[*], sorted_words);
sorted_words = reverse(sorted_words);

write("Top 10 words:\n");
foreach(sorted_words[0..9]; int i; string word) {
    write("%2d. %s: %d\n", i+1, word, word_freq[word]);
}
```

---

## Reading a File Backwards by Line or Paragraph

### Reverse Line Reading

```pike
//-----------------------------
// Recipe: Read file from end to beginning
//-----------------------------

array(string) read_file_backwards(string path) {
    // Read entire file into array
    array(string) lines = Stdio.read_file(path) / "\n";

    // Remove trailing empty line if present
    if (sizeof(lines) && !sizeof(lines[-1])) {
        lines = lines[0..sizeof(lines)-2];
    }

    // Reverse the array
    return reverse(lines);
}

// Memory-efficient version for large files
void process_backwards_efficient(string path, function(string:void) callback) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return;

    // Store lines in array (for memory efficiency, use temp file)
    array(string) lines = ({});

    foreach(file->line_iterator();; string line) {
        lines += ({line});
    }

    file->close();

    // Process in reverse order
    for (int i = sizeof(lines) - 1; i >= 0; i--) {
        callback(lines[i]);
    }
}

// Usage
process_backwards_efficient("log.txt", lambda(string line) {
    write("%s\n", line);
});
```

---

## Trailing a Growing File

### Tail Implementation (Like Unix `tail -f`)

```pike
//-----------------------------
// Recipe: Monitor file for new lines (tail -f)
//-----------------------------

void tail_file(string path, void|function(string:void) callback) {
    if (!callback) {
        callback = lambda(string line) { write("%s\n", line); };
    }

    Stdio.File file = Stdio.File(path, "r");
    if (!file) {
        werror("Cannot open file\n");
        return;
    }

    // Seek to end of file
    file->seek(0, SEEK_END);

    write("Monitoring %s (Ctrl+C to stop)...\n", path);

    while (1) {
        string line = file->gets();
        if (line) {
            callback(line);
        } else {
            // No new data, wait a bit
            sleep(0.1);
        }
    }

    file->close();
}

// Enhanced version with line count limit
void tail_file_n(string path, int n_lines) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return;

    array(string) last_n = ({});

    foreach(file->line_iterator();; string line) {
        last_n += ({line});
        if (sizeof(last_n) > n_lines) {
            last_n = last_n[1..];  // Keep only last N lines
        }
    }

    file->close();

    // Output last N lines
    foreach(last_n; string line) {
        write("%s\n", line);
    }
}
```

---

## Picking a Random Line from a File

### Random Line Selection

```pike
//-----------------------------
// Recipe: Select random line from file
//-----------------------------

string random_line(string path) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return 0;

    string selected = 0;
    int count = 0;

    // Reservoir sampling - pick one line uniformly at random
    foreach(file->line_iterator();; string line) {
        count++;
        // Replace selected line with probability 1/count
        if (random(count) == 0) {
            selected = line;
        }
    }

    file->close();
    return selected;
}

// Select N random lines without duplicates
array(string) random_lines(string path, int n) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return ({});

    array(string) reservoir = ({});
    int count = 0;

    foreach(file->line_iterator();; string line) {
        count++;

        if (sizeof(reservoir) < n) {
            reservoir += ({line});
        } else {
            // Replace with probability n/count
            int replace_at = random(count);
            if (replace_at < n) {
                reservoir[replace_at] = line;
            }
        }
    }

    file->close();
    return reservoir;
}

// Usage
string quote = random_line("quotes.txt");
write("Random quote: %s\n", quote);

array(string) five_quotes = random_lines("quotes.txt", 5);
foreach(five_quotes; int i; string quote) {
    write("%d. %s\n", i+1, quote);
}
```

---

## Randomizing All Lines

### Shuffle File Lines

```pike
//-----------------------------
// Recipe: Randomize line order in file
//-----------------------------

void shuffle_file(string input_path, string output_path) {
    // Read all lines
    string content = Stdio.read_file(input_path);
    array(string) lines = content / "\n";

    // Remove trailing empty line if present
    if (sizeof(lines) && !sizeof(lines[-1])) {
        lines = lines[0..sizeof(lines)-2];
    }

    // Shuffle using Fisher-Yates algorithm
    for (int i = sizeof(lines) - 1; i > 0; i--) {
        int j = random(i + 1);
        // Swap lines[i] and lines[j]
        string temp = lines[i];
        lines[i] = lines[j];
        lines[j] = temp;
    }

    // Write shuffled lines
    Stdio.write_file(output_path, lines * "\n" + "\n");
    write("Shuffled %d lines from %s to %s\n",
          sizeof(lines), input_path, output_path);
}
```

---

## Reading a Particular Line in a File

### Direct Line Access

```pike
//-----------------------------
// Recipe: Read specific line by number
//-----------------------------

string|zero read_line_number(string path, int line_num) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return 0;

    int current = 0;
    string result = 0;

    foreach(file->line_iterator();; string line) {
        current++;
        if (current == line_num) {
            result = line;
            break;
        }
    }

    file->close();
    return result;
}

// Read multiple lines by range
array(string) read_line_range(string path, int start, int end) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return ({});

    array(string) result = ({});
    int current = 0;

    foreach(file->line_iterator();; string line) {
        current++;
        if (current >= start && current <= end) {
            result += ({line});
        }
        if (current > end) break;
    }

    file->close();
    return result;
}

// Usage
string line_10 = read_line_number("data.txt", 10);
if (line_10) {
    write("Line 10: %s\n", line_10);
}

array(string) lines_5_to_10 = read_line_range("data.txt", 5, 10);
write("Lines 5-10:\n%s\n", lines_5_to_10 * "\n");
```

---

## Processing Variable-Length Text Fields

### Fixed-Width Field Parsing

```pike
//-----------------------------
// Recipe: Parse fixed-width text fields
//-----------------------------

mapping parse_fixed_width(string line, array(int) widths) {
    mapping result = ([]);
    int pos = 0;

    foreach(widths; int i; int width) {
        string field = line[pos..pos+width-1];
        result[i] = String.trim_whites(field);
        pos += width;
    }

    return result;
}

// Example: Parse a data file with fixed-width columns
void process_fixed_width_file(string path) {
    // Define column widths
    array(int) widths = ({10, 20, 15, 10});  // Name, Email, Phone, City

    Stdio.File file = Stdio.File(path, "r");
    if (!file) return;

    // Skip header
    file->gets();

    foreach(file->line_iterator();; string line) {
        mapping fields = parse_fixed_width(line, widths);
        write("Name: %s, Email: %s, Phone: %s, City: %s\n",
              fields[0], fields[1], fields[2], fields[3]);
    }

    file->close();
}
```

---

## Removing the Last Line of a File

### Efficient Last Line Removal

```pike
//-----------------------------
// Recipe: Remove last line from file
//-----------------------------

void remove_last_line(string path) {
    string content = Stdio.read_file(path);
    array(string) lines = content / "\n";

    // Remove last element (empty string from trailing newline or actual last line)
    if (sizeof(lines)) {
        lines = lines[0..sizeof(lines)-2];
    }

    // Write back
    Stdio.write_file(path, lines * "\n");
}

// Memory-efficient version for large files
void remove_last_line_efficient(string path) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return;

    array(string) all_but_last = ({});
    string prev_line = "";

    // Read all lines, keeping track of previous
    string line;
    while ((line = file->gets())) {
        if (sizeof(prev_line)) {
            all_but_last += ({prev_line});
        }
        prev_line = line;
    }

    file->close();

    // Write all but last line
    Stdio.write_file(path, all_but_last * "\n" + "\n");
}
```

---

## Processing Binary Files

### Binary Data Operations

```pike
//-----------------------------
// Recipe: Read and process binary files
//-----------------------------

// Read binary data with specific structure
void process_binary_file(string path) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) {
        werror("Cannot open binary file\n");
        return;
    }

    // Read header
    string magic = file->read(4);
    write("Magic: %O\n", magic);

    // Read 32-bit integer (big-endian)
    string int_bytes = file->read(4);
    int value = 0;
    for (int i = 0; i < 4; i++) {
        value = (value << 8) | int_bytes[i];
    }
    write("Value: %d\n", value);

    // Read null-terminated string
    array(string) str_parts = ({});
    string ch;
    while ((ch = file->read(1)) != "\0") {
        str_parts += ({ch});
    }
    string str = str_parts * "";
    write("String: %s\n", str);

    file->close();
}

// Copy file with progress
void copy_file_with_progress(string src, string dst) {
    Stdio.File input = Stdio.File(src, "r");
    Stdio.File output = Stdio.File(dst, "wc");

    if (!input || !output) {
        werror("Cannot open files\n");
        return;
    }

    int total = 0;
    int chunk_size = 65536;  // 64KB
    string chunk;

    while ((chunk = input->read(chunk_size))) {
        output->write(chunk);
        total += sizeof(chunk);

        if (total % (1024 * 1024) == 0) {
            write("Copied %d MB\n", total / (1024 * 1024));
        }
    }

    write("Total copied: %d bytes\n", total);

    input->close();
    output->close();
}
```

---

## Using Random-Access I/O

### Direct File Positioning

```pike
//-----------------------------
// Recipe: Random access to file positions
//-----------------------------

void demo_random_access(string path) {
    Stdio.File file = Stdio.File(path, "r");
    if (!file) return;

    // Get file size
    file->seek(0, SEEK_END);
    int file_size = file->tell();
    write("File size: %d bytes\n", file_size);

    // Read first 100 bytes
    file->seek(0);
    string header = file->read(100);
    write("Header: %O...\n", header[0..50]);

    // Read last 100 bytes
    file->seek(-100, SEEK_END);
    string trailer = file->read(100);
    write("Trailer: %O\n", trailer);

    // Jump to middle and read
    file->seek(file_size / 2);
    string middle = file->read(100);
    write("Middle: %O\n", middle);

    file->close();
}

// Replace bytes at specific position
void patch_binary(string path, int pos, string new_data) {
    Stdio.File file = Stdio.File(path, "rw");
    if (!file) {
        werror("Cannot open file\n");
        return;
    }

    file->seek(pos);
    file->write(new_data);

    write("Patched %d bytes at position %d\n", sizeof(new_data), pos);

    file->close();
}
```

---

## Reading Configuration Files

### INI-Style Config Parser

```pike
//-----------------------------
// Recipe: Parse INI configuration files
//-----------------------------

mapping(string:mapping(string:string)) parse_ini(string path) {
    string content = Stdio.read_file(path);
    array(string) lines = content / "\n";

    mapping(string:mapping(string:string)) config = ([]);
    string current_section = "default";

    foreach(lines; string line) {
        string trimmed = String.trim_whites(line);

        // Skip empty lines and comments
        if (!sizeof(trimmed) || trimmed[0] == '#' || trimmed[0] == ';')
            continue;

        // Section header [section]
        if (trimmed[0] == '[' && trimmed[-1] == ']') {
            current_section = trimmed[1..sizeof(trimmed)-2];
            config[current_section] = ([]);
            continue;
        }

        // Key = Value
        int eq_pos = search(trimmed, '=');
        if (eq_pos > 0) {
            string key = String.trim_whites(trimmed[0..eq_pos-1]);
            string value = String.trim_whites(trimmed[eq_pos+1..]);

            if (!config[current_section])
                config[current_section] = ([]);

            config[current_section][key] = value;
        }
    }

    return config;
}

// Usage
mapping config = parse_ini("config.ini");

if (config["database"]) {
    write("Database host: %s\n", config["database"]["host"]);
    write("Database name: %s\n", config["database"]["name"]);
}
```

---

## See Also

- [File Access](/docs/files/file-access) - Basic file operations
- [Directories](/docs/files/directories) - Directory management
- [Strings](/docs/basics/strings) - Text processing functions
- [Pattern Matching](/docs/basics/pattern-matching) - Advanced text parsing
