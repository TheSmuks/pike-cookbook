---
id: intro
title: Welcome to the Pike Cookbook
sidebar_label: Introduction
---

# Welcome to the Pike Cookbook

A comprehensive collection of practical recipes and examples for programming in [Pike 8.0](https://pike.lysator.liu.se/).

## What is Pike?

**Pike** is a dynamic programming language with a syntax similar to C and Java. It combines the simplicity of scripting languages with the performance of compiled languages.

### Why Choose Pike?

- **High-level** - Fast development with powerful abstractions
- **Fast execution** - Compiled to bytecode, runs efficiently
- **Simple to learn** - Clean syntax, easy to read and write
- **Type safety** - Optional strict typing with `#pragma strict_types`
- **Built-in data types** - Advanced string, array, and mapping support
- **Native concurrency** - Built-in threading and async I/O
- **Rich standard library** - HTTP, SQL, crypto, and more

:::tip
Pike is particularly well-suited for network programming, text processing, and rapid application development. Its efficient memory management and concurrent execution make it ideal for server applications.
:::

---

## How to Use This Cookbook

This cookbook is organized into four main sections, each building on the previous:

### Basic Recipes
**Foundation skills for Pike programming**

Start here if you're new to Pike or need a refresher:
- [Strings](/docs/basics/strings) - Text processing and manipulation
- [Numbers](/docs/basics/numbers) - Mathematical operations and numeric types
- [Arrays](/docs/basics/arrays) - Lists, sequences, and array operations
- [Hashes](/docs/basics/hashes) - Mappings, dictionaries, and key-value stores
- [Dates](/docs/basics/dates) - Date and time handling
- [Pattern Matching](/docs/basics/pattern-matching) - Regular expressions and text matching
- [Subroutines](/docs/basics/subroutines) - Functions, closures, and lambda expressions

### File Operations
**Working with files and persistent data**

Learn to read, write, and manage files:
- [File Access](/docs/files/file-access) - Opening, reading, and writing files
- [File Contents](/docs/files/file-contents) - Processing file data efficiently
- [Directories](/docs/files/directories) - Directory traversal and management
- [Database Access](/docs/files/database-access) - SQL database integration

### Network & Web
**Network programming and web automation**

Build networked applications and web tools:
- [Sockets](/docs/network/sockets) - TCP/UDP socket programming
- [CGI Programming](/docs/network/cgi-programming) - Web scripting and CGI
- [Web Automation](/docs/network/web-automation) - HTTP clients and web scraping
- [Internet Services](/docs/network/internet-services) - Email, FTP, and other protocols

### Advanced Topics
**Advanced Pike programming patterns**

Master Pike's powerful features:
- [Classes and Objects](/docs/advanced/classes) - OOP and class design
- [Modules](/docs/advanced/modules) - Code organization and libraries
- [References](/docs/advanced/references) - Advanced data structures
- [Processes](/docs/advanced/processes) - Process management and IPC
- [User Interfaces](/docs/advanced/user-interfaces) - GUI programming

---

## About the Examples

Each recipe in this cookbook includes:

### **Working Code**
Copy and paste directly into your projects. All examples are tested and functional.

### **Modern Pike 8**
Uses current best practices and the latest Pike 8 features:
- `#pragma strict_types` for type safety
- Modern module imports
- Concurrent.Future for async operations
- Proper error handling patterns

### **Practical Solutions**
Real-world problems you'll actually encounter:
- Text parsing and data extraction
- File processing and transformation
- Network clients and servers
- Database integration
- Web automation and APIs

### **Clear Explanations**
- **What it does** - Brief description of the problem solved
- **How it works** - Explanation of the code
- **Why use this** - When to apply this pattern
- **See also** - Related recipes and topics

:::note
Examples use `#pragma strict_types` for better error detection. You can omit this for quick scripts, but it's recommended for production code.
:::

---

## Getting Started with Pike

### Installation

```bash
# On most Linux systems (using package manager)
sudo apt-get install pike8              # Debian/Ubuntu
sudo yum install pike8                  # RHEL/CentOS
sudo pacman -S pike8                    # Arch Linux

# On macOS (using Homebrew)
brew install pike

# From source
git clone https://github.com/pikelang/pike
cd pike
./configure && make && sudo make install
```

### Your First Pike Program

Create a file `hello.pike`:

```pike
#!/usr/bin/env pike
#pragma strict_types

int main() {
    write("Hello, World!\n");
    return 0;
}
```

Run it:

```bash
pike hello.pike
# Or make it executable and run directly
chmod +x hello.pike
./hello.pike
```

### Interactive Pike Shell

Experiment with Pike in the REPL:

```bash
pike
> 2 + 2
Result: 4
> array(string) fruits = ({"apple", "banana", "cherry"});
> fruits * ", "
Result: "apple, banana, cherry"
> exit
```

---

## Quick Examples

### Hello World with Modern Features

```pike
#!/usr/bin/env pike
#pragma strict_types

int main(int argc, array(string) argv) {
    // Command-line arguments
    string name = argc > 1 ? argv[1] : "World";

    // String formatting
    write(sprintf("Hello, %s!\n", name));

    // Using Array module
    import Array;
    array(string) words = ({"Hello", "from", "Pike"});
    write("%s\n", words * " ");

    return 0;
}
```

### File Processing

```pike
#!/usr/bin/env pike
#pragma strict_types

int main() {
    // Read entire file
    string content = Stdio.read_file("input.txt");

    // Process lines
    array(string) lines = content / "\n";

    foreach(lines;; string line) {
        // Skip empty lines and comments
        if (!sizeof(line) || line[0] == '#')
            continue;

        // Process non-empty lines
        write("Processing: %s\n", String.trim_whites(line));
    }

    return 0;
}
```

### HTTP Request

```pike
#!/usr/bin/env pike
#pragma strict_types
#require constant(Protocols.HTTP)

int main() {
    // Simple HTTP GET request
    Protocols.HTTP.Query q = Protocols.HTTP.get_url("https://example.com");

    if (q->status == 200) {
        write("Success! Received %d bytes\n", sizeof(q->data()));
        write("Content-Type: %s\n", q->headers["content-type"]);
    } else {
        werror("HTTP Error: %d %s\n", q->status, q->status_desc);
        return 1;
    }

    return 0;
}
```

---

## Common Patterns

### Error Handling

```pike
// Use catch() for error handling
mixed err = catch {
    Stdio.File f = Stdio.File("nonexistent.txt", "r");
};

if (err) {
    werror("Error: %s\n", err[0]);
}
```

### Working with Arrays

```pike
// Create and manipulate arrays
array(int) numbers = ({1, 2, 3, 4, 5});

// Add elements
numbers += ({6, 7, 8});

// Filter with map
array(int) evens = filter(numbers, lambda(int n) { return n % 2 == 0; });

// Sort
sort(numbers);

// Join into string
string csv = (string)numbers * ", ";
```

### Working with Mappings (Hashes)

```pike
// Create a mapping
mapping(string:mixed) person = ([
    "name": "Alice",
    "age": 30,
    "city": "New York"
]);

// Access values
string name = person->name;
int age = person["age"];

// Check if key exists
if (has_index(person, "email")) {
    write("Email: %s\n", person->email);
}

// Iterate
foreach(person; string key; mixed value) {
    write("%s: %O\n", key, value);
}
```

---

## Resources

### Official Documentation

- [Pike Homepage](https://pike.lysator.liu.se/) - Official website and news
- [Pike Reference Manual](https://pike.lysator.liu.se/docs/) - Complete language reference
- [Pike GitHub Repository](https://github.com/pikelang/pike) - Source code and issues
- [Pike Autodoc](https://pike.lysator.liu.se/docs/refdoc/) - Module documentation

### Community

- [Pike User Mailing List](https://pike.lysator.liu.se/lists/) - Get help from other Pike users
- [Pike IRC Channel](irc://irc.freenode.net/pike) - Real-time chat

---

## Contributing

Found a bug? Have a recipe to share? We welcome contributions!

### How to Contribute

1. **Report Issues** - Use [GitHub Issues](https://github.com/smuks/pike-cookbook/issues)
2. **Submit Recipes** - Fork, add your recipe, and send a pull request
3. **Improve Docs** - Fix typos, clarify explanations, add examples
4. **Share Feedback** - Tell us what's useful and what's missing

:::tip
When contributing recipes, follow the existing style:
- Use `#pragma strict_types`
- Include `#require` directives for modules
- Add clear comments explaining the code
- Provide practical, working examples
- Cross-reference related recipes
:::

---

## License

This cookbook is licensed under the same terms as Pike itself. See the [LICENSE](https://github.com/smuks/pike-cookbook/blob/main/LICENSE) file for details.

---

**Ready to start?** Begin with [Basic Recipes](/docs/basics/strings) or jump to any topic that interests you!
