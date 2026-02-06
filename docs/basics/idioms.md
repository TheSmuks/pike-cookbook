---
id: idioms
title: Pike Idioms
sidebar_label: Pike Idioms
---

# Pike Idioms

A curated collection of the most common and distinctive Pike programming idioms. These patterns appear throughout real-world Pike code and distinguish experienced Pike programmers from beginners porting habits from other languages.

:::tip
Every example here uses verified Pike 8.0 APIs. When in doubt, prefer these patterns over translated idioms from C, Python, or Perl.
:::

---

## String Idioms

### Split and Join with Operators

Pike's most distinctive string idiom: the division operator splits strings, and the multiplication operator joins arrays.

```pike
// Split a string into an array
array(string) words = "hello world foo bar" / " ";
// words == ({"hello", "world", "foo", "bar"})

// Join an array into a string
string csv = ({"apple", "banana", "cherry"}) * ", ";
// csv == "apple, banana, cherry"

// Split into fixed-width fields
array(string) pairs = "aabbccdd" / 2;
// pairs == ({"aa", "bb", "cc", "dd"})

// Split lines
array(string) lines = content / "\n";

// Rejoin lines
string output = lines * "\n";
```

### String Search and Testing

```pike
// Check if a string contains a substring
if (has_value(text, "needle")) { ... }

// Check prefix/suffix
if (has_prefix(filename, "/tmp/")) { ... }
if (has_suffix(filename, ".pike")) { ... }

// Find position of substring
int pos = search(text, "target");
if (pos >= 0) {
    write("Found at position %d\n", pos);
}
```

### Parsing with sscanf

`sscanf` is Pike's Swiss Army knife for structured string parsing — often more readable than regex.

```pike
// Parse key=value pairs
string key, value;
if (sscanf(line, "%s=%s", key, value) == 2) {
    config[key] = value;
}

// Parse a log line
string ip, method, path;
int status, size;
sscanf(log_line, "%s - - [%*s] \"%s %s HTTP/%*s\" %d %d",
       ip, method, path, status, size);

// Parse binary data
int magic, version, count;
sscanf(header, "%4c%4c%4c", magic, version, count);

// Extract numbers from text
int year, month, day;
sscanf(date_str, "%d-%d-%d", year, month, day);
```

### String Trimming and Transformation

```pike
// Trim whitespace
string clean = String.trim_whites(input);

// Normalize whitespace (collapse runs of whitespace to single space)
string normalized = String.normalize_space(text);

// Case conversion
string upper = upper_case(text);
string lower = lower_case(text);
string capitalized = String.capitalize(text);

// Multi-replacement with mapping (single pass)
string escaped = replace(html, ([
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;"
]));
```

### Efficient String Building

For building strings in loops, `String.Buffer` avoids O(n²) concatenation.

```pike
String.Buffer buf = String.Buffer();
foreach(data;; string item) {
    buf->add(item, "\n");
}
string result = buf->get();
```

---

## Array Idioms

### Array Literals and Construction

```pike
// Array literal
array(int) nums = ({1, 2, 3, 4, 5});

// Empty typed array
array(string) empty = ({});

// Generate a range with enumerate
array(int) range = enumerate(10);           // ({0,1,2,...,9})
array(int) from_one = enumerate(5, 1, 1);   // ({1,2,3,4,5})
array(int) evens = enumerate(5, 2, 0);      // ({0,2,4,6,8})

// Allocate with default value
array(int) zeros = allocate(100, 0);
```

### Functional Array Operations

```pike
// Filter elements
array(int) evens = filter(numbers, lambda(int n) { return n % 2 == 0; });

// Transform elements
array(string) upper = map(words, upper_case);

// Sort (modifies in place, returns the array)
sort(names);

// Sort with parallel arrays (sort values by keys)
array(string) names = ({"Charlie", "Alice", "Bob"});
array(int) ages = ({30, 25, 28});
sort(names, ages);
// names is now ({"Alice", "Bob", "Charlie"})
// ages is now ({25, 28, 30})

// Custom sort with Array.sort_array
array(string) by_length = Array.sort_array(words,
    lambda(string a, string b) { return sizeof(a) > sizeof(b); });
```

### Set Operations with Array Arithmetic

Pike arrays support set operations directly with arithmetic operators.

```pike
array(int) a = ({1, 2, 3, 4, 5});
array(int) b = ({3, 4, 5, 6, 7});

array(int) both = a & b;       // Intersection: ({3, 4, 5})
array(int) combined = a | b;   // Union: ({1, 2, 3, 4, 5, 6, 7})
array(int) only_a = a - b;     // Difference: ({1, 2})
array(int) unique = a ^ b;     // Symmetric difference: ({1, 2, 6, 7})

// Add elements
a += ({6, 7});

// Remove elements
a -= ({3, 4});
```

### Automap with `[*]`

The automap operator applies an operation to every element of an array.

```pike
// Multiply every element
array(int) doubled = values[*] * 2;

// Call a function on every element
array(string) trimmed = String.trim_whites(lines[*]);

// Split every line
array(array(string)) fields = lines[*] / ":";

// Call a method on every element
complain(bad_users[*]);  // Calls complain() for each element
```

### Reduction with Backtick Operators

```pike
// Sum all elements
int total = `+(@numbers);
// equivalent to: numbers[0] + numbers[1] + ... + numbers[n]

// Join strings (alternative to * operator)
string joined = `+(@strings);

// Find min/max
int minimum = min(@numbers);
int maximum = max(@numbers);
```

### Extracting Columns

```pike
// Extract a field from an array of mappings
array(mapping) users = ({
    (["name": "Alice", "age": 25]),
    (["name": "Bob", "age": 30])
});
array names = column(users, "name");
// names == ({"Alice", "Bob"})
```

---

## Mapping Idioms

### Mapping Literals and Access

```pike
// Mapping literal
mapping(string:int) age = ([
    "Alice": 25,
    "Bob": 30,
    "Charlie": 35
]);

// Access with bracket notation (any key type)
int a = age["Alice"];

// Access with arrow notation (string keys that are valid identifiers)
int b = age->Bob;

// Safe access — check for key existence
if (!zero_type(age["Dave"])) {
    write("Dave's age: %d\n", age["Dave"]);
}
```

### Key Existence with zero_type

`zero_type()` is THE Pike idiom for distinguishing "key exists with value 0" from "key does not exist".

```pike
mapping(string:int) scores = (["Alice": 100, "Bob": 0]);

// WRONG: This fails when value is 0
if (scores["Bob"]) { ... }  // false! Bob has score 0

// CORRECT: Use zero_type
if (!zero_type(scores["Bob"])) {
    write("Bob's score: %d\n", scores["Bob"]);  // "Bob's score: 0"
}

// Alternative for simple existence checks
if (has_index(scores, "Bob")) { ... }
```

### Mapping Operations

```pike
// Get all keys and values
array(string) keys = indices(age);
array(int) vals = values(age);

// Delete a key
m_delete(age, "Charlie");

// Merge mappings (right side wins on conflicts)
mapping merged = defaults | overrides;
mapping merged2 = defaults + overrides;

// Create mapping from parallel arrays
mapping(string:int) rebuilt = mkmapping(keys, vals);

// Invert a mapping (swap keys and values)
mapping(int:string) by_age = mkmapping(values(age), indices(age));

// Iterate with three-arg foreach
foreach(age; string name; int years) {
    write("%s is %d years old\n", name, years);
}
```

---

## Multiset Idioms

Multisets provide O(1) membership testing — use them instead of arrays for lookup sets.

```pike
// Create a multiset
multiset(string) visited = (<>);

// Add members
visited["http://example.com"] = 1;

// Test membership
if (visited["http://example.com"]) {
    write("Already visited\n");
}

// Create from literal
multiset(string) keywords = (< "if", "else", "for", "while", "return" >);

// Convert array to multiset for fast lookups
multiset(string) word_set = (multiset)words;
```

---

## Type System Idioms

### Strict Types and Nullable

```pike
#pragma strict_types

// Nullable types with void union
string|void find_user(int id) {
    if (has_index(users, id)) return users[id];
    // implicitly returns UNDEFINED
}

// Check the result
string|void user = find_user(42);
if (user) {
    write("Found: %s\n", user);
}

// Type guards with type-checking functions
void process(mixed data) {
    if (stringp(data)) {
        write("String: %s\n", data);
    } else if (intp(data)) {
        write("Integer: %d\n", data);
    } else if (mappingp(data)) {
        foreach(data; mixed key; mixed val) {
            write("%O: %O\n", key, val);
        }
    } else if (arrayp(data)) {
        write("Array with %d elements\n", sizeof(data));
    }
}
```

### Type Checking Functions

```pike
// All Pike type-checking predicates:
stringp(x)    // Is x a string?
intp(x)       // Is x an integer?
floatp(x)     // Is x a float?
arrayp(x)     // Is x an array?
mappingp(x)   // Is x a mapping?
multisetp(x)  // Is x a multiset?
objectp(x)    // Is x an object?
functionp(x)  // Is x a function?
programp(x)   // Is x a program (class)?
```

---

## Error Handling Idioms

### The catch Block

Pike uses `catch` blocks instead of try/catch.

```pike
// Basic catch — returns 0 on success, error array on failure
mixed err = catch {
    Stdio.File f = Stdio.File("data.txt", "r");
    string content = f->read();
    f->close();
};

if (err) {
    werror("Error: %s\n", describe_error(err));
}
```

### Two-Phase File Open

`Stdio.File()` constructor throws on failure. For fallible opens, use the two-phase pattern.

```pike
// Constructor throws — use catch or two-phase open
Stdio.File file = Stdio.File();
if (!file->open(path, "r")) {
    werror("Cannot open %s: %s\n", path, strerror(file->errno()));
    return;
}
// file is now open and usable
string data = file->read();
file->close();
```

### Error Description

```pike
mixed err = catch { risky_operation(); };
if (err) {
    // Format error message
    werror("Error: %s\n", describe_error(err));

    // Full backtrace
    werror("%s\n", describe_backtrace(err));
}
```

---

## I/O Idioms

### Simple File Operations

```pike
// Read entire file at once
string content = Stdio.read_file("input.txt");

// Write entire file at once
Stdio.write_file("output.txt", content);

// Append to a file
Stdio.append_file("log.txt", "New entry\n");

// Check file existence
if (Stdio.exist(path)) { ... }

// Check if path is a directory
if (Stdio.is_dir(path)) { ... }
```

### Line-by-Line Reading

```pike
// Using line_iterator (preferred for Stdio.File)
Stdio.File file = Stdio.File();
if (file->open("data.txt", "r")) {
    foreach(file->line_iterator();; string line) {
        write("Line: %s\n", line);
    }
    file->close();
}

// Using Stdio.FILE (buffered) with gets()
Stdio.FILE f = Stdio.FILE("data.txt", "r");
string line;
while ((line = f->gets())) {
    write("%s\n", line);
}
f->close();
```

### Formatted Output

```pike
// write() to stdout
write("Hello %s, you are %d years old\n", name, age);

// werror() to stderr
werror("Warning: %s\n", message);

// sprintf() for string formatting
string msg = sprintf("%-20s %5d %8.2f\n", name, count, price);

// Debug output with %O (Pike value representation)
write("Data: %O\n", complex_data);
```

---

## Foreach Idioms

### Three Forms of foreach

```pike
// Two-arg form: iterate array values
foreach(items, string item) {
    write("%s\n", item);
}

// Three-arg form: iterate with index
foreach(items; int index; string item) {
    write("[%d] %s\n", index, item);
}

// Three-arg on mappings: iterate key-value pairs
foreach(config; string key; mixed value) {
    write("%s = %O\n", key, value);
}

// Skip index with empty slot
foreach(items;; string item) {
    process(item);
}
```

---

## Functional Idioms

### Lambda and Closures

```pike
// Lambda expression
function(int:int) double = lambda(int x) { return x * 2; };

// Closure capturing outer variable
int threshold = 10;
function(int:int) is_above = lambda(int x) { return x > threshold; };

// Immediately invoked
int result = lambda(int a, int b) { return a + b; }(3, 4);
// result == 7
```

### Function References

```pike
// Pass built-in functions as values
array(string) upper = map(words, upper_case);
array(string) trimmed = map(lines, String.trim_whites);

// Sort with a comparison function
array sorted = Array.sort_array(items, `<);
```

### Currying

```pike
// Create a partially applied function
function(int:int) add5 = Function.curry(lambda(int a, int b) {
    return a + b;
})(5);

write("%d\n", add5(3));  // 8
```

### Splat Operator

```pike
// Expand array into function arguments
void log(string fmt, mixed ... args) {
    write(fmt + "\n", @args);
}

// Spread into array construction
array combined = ({@first, @second});
```

---

## Concurrency Idioms

### Event Loop with return -1

The canonical Pike idiom for keeping the event loop running.

```pike
int main() {
    Stdio.Port port = Stdio.Port();
    port->bind(8080, accept_callback);
    return -1;  // Keep the Pike backend event loop running
}
```

### Non-blocking I/O

```pike
// Set up callbacks for non-blocking socket
sock->set_nonblocking(
    read_callback,   // Called when data is available
    write_callback,  // Called when write buffer is empty
    close_callback   // Called on connection close
);
```

### Promise/Future Pattern

```pike
Concurrent.Promise promise = Concurrent.Promise();

// Resolve asynchronously
Thread.Thread(lambda() {
    mixed result = expensive_computation();
    promise->success(result);
});

// Use the future
Concurrent.Future f = promise->future();
f->on_success(lambda(mixed result) {
    write("Got result: %O\n", result);
});
```

---

## Pike-Specific Constructs

### The gauge Block

Measure execution time of a code block.

```pike
float elapsed = gauge {
    // code to benchmark
    for (int i = 0; i < 1000000; i++) {
        result += i;
    }
};
write("Elapsed: %.3f seconds\n", elapsed);
```

### Version and Feature Detection

```pike
// Declare Pike version compatibility
#pike 8.0

// Require a specific module at compile time
#require constant(Protocols.HTTP)

// Check for optional features
#if constant(SSL.File)
    // SSL support available
#endif
```

### The predef Namespace

Access global functions when shadowed by local definitions.

```pike
class Logger {
    void write(string msg) {
        // Call the global write(), not this method
        predef::write("[LOG] %s\n", msg);
    }
}
```

### copy_value for Deep Copy

```pike
// Pike's built-in recursive deep copy
mapping original = (["a": ({1, 2, 3}), "b": (["nested": "data"])]);
mapping deep = copy_value(original);

// Modifying deep does NOT affect original
deep["a"] += ({4});
// original["a"] is still ({1, 2, 3})
```

### Formatting with sprintf

```pike
// Pad and align
sprintf("%-20s", name);       // Left-align in 20 chars
sprintf("%020d", number);     // Zero-pad to 20 digits
sprintf("%+.2f", price);      // Force sign, 2 decimal places

// Binary/octal/hex
sprintf("%b", 42);            // "101010"
sprintf("%o", 42);            // "52"
sprintf("%x", 42);            // "2a"
sprintf("%08x", 42);          // "0000002a"

// Pike value representation (debugging)
sprintf("%O", any_value);     // Human-readable Pike representation
```

---

## Common Anti-Patterns to Avoid

### Don't Use These

```pike
// WRONG: String.split() does not exist
array parts = String.split(line, ",");
// CORRECT: Use the division operator
array parts = line / ",";

// WRONG: String.replace() does not exist as a function
string fixed = String.replace(text, "old", "new");
// CORRECT: Use the global replace()
string fixed = replace(text, "old", "new");

// WRONG: Stdio.File constructor returns null on failure
Stdio.File f = Stdio.File("missing.txt", "r");
if (!f) { ... }  // DEAD CODE — constructor throws, never returns null
// CORRECT: Use catch or two-phase open
mixed err = catch { Stdio.File f = Stdio.File("missing.txt", "r"); };

// PREFER: Use Stdio.FILE for line-by-line reading (buffered, more efficient)
Stdio.FILE f = Stdio.FILE("data.txt", "r");
string line = f->gets();  // Stdio.FILE provides buffered gets()
// ALSO GOOD: Use line_iterator() on Stdio.File
Stdio.File f2 = Stdio.File();
f2->open("data.txt", "r");
foreach(f2->line_iterator();; string line) { ... }

// WRONG: float() and int() as callable constructors
float x = float("3.14");
// CORRECT: Use casts
float x = (float)"3.14";

// WRONG: Regexp with PCRE features (SimpleRegexp doesn't support \d, \w, etc.)
Regexp("\\d+")->match(text);
// CORRECT: Use Regexp.PCRE for advanced patterns
Regexp.PCRE("\\d+")->match(text);

// WRONG: sort() with comparison function
sort(items, my_compare_func);
// CORRECT: sort() takes parallel arrays; use Array.sort_array for custom comparison
Array.sort_array(items, my_compare_func);
```

---

## Quick Reference Card

| Task | Pike Idiom |
|------|-----------|
| Split string | `str / delimiter` |
| Join array | `arr * separator` |
| Check substring | `has_value(str, sub)` |
| Check prefix | `has_prefix(str, prefix)` |
| Trim whitespace | `String.trim_whites(str)` |
| Parse structured | `sscanf(str, fmt, vars...)` |
| Read file | `Stdio.read_file(path)` |
| Write file | `Stdio.write_file(path, data)` |
| File exists | `Stdio.exist(path)` |
| Key exists | `!zero_type(map[key])` |
| Delete key | `m_delete(map, key)` |
| Deep copy | `copy_value(original)` |
| Sum array | `` `+(@arr) `` |
| Array range | `enumerate(n)` |
| Set intersection | `a & b` |
| Set difference | `a - b` |
| Error handling | `catch { ... }` |
| Format string | `sprintf(fmt, args...)` |
| Debug print | `sprintf("%O", value)` |
| Keep event loop | `return -1;` |
| Automap | `func(arr[*])` |
| Measure time | `gauge { ... }` |

---

:::note
These idioms are verified against Pike 8.0. For the full API reference, see the [Pike documentation](https://pike.lysator.liu.se/docs/).
:::
