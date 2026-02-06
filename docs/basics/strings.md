---
id: strings
title: Strings
sidebar_label: Strings
---

# Strings

## Introduction

Strings in Pike are sequences of characters used for text processing. Pike provides powerful string manipulation capabilities with full Unicode support.

:::tip
Pike strings are **immutable** - operations that "modify" strings actually create new strings. For efficient string building, use `String.Buffer`.
:::

### Basic String Syntax

```pike
//-----------------------------
// String declarations and basic syntax
//-----------------------------

// Declare string variable
string str;

// String literals
str = "Hello, World!";
str = "\n";                      // Newline character
str = "Jon \"Maddog\" Orwant";   // Escaped quotes
str = "C:\\Users\\Documents";    // Escaped backslashes
str = "Line 1\nLine 2\nLine 3";  // Multiple lines with \n

// Multiline strings using #" syntax
str = #"This is a multiline string
that spans multiple lines
without needing escape characters";

// Raw strings (no escape processing)
str = #'Raw\nString\t';
// Contains literal: R a w \ n S t r i n g \ t
```

### String Length and Size

```pike
//-----------------------------
// Getting string length
//-----------------------------

string text = "Hello, World!";

// Number of characters
int char_count = sizeof(text);
write("Characters: %d\n", char_count);  // 13

// Number of bytes (important for UTF-8)
int byte_count = String.width(text);
write("Bytes: %d\n", byte_count);
```

---

## Accessing Substrings

:::note
Pike uses **0-based indexing** with range syntax `[start..end]` where both ends are inclusive.
:::

### Basic Substring Operations

```pike
//-----------------------------
// Recipe: Extract parts of strings
//-----------------------------

string str = "This is what you have";

// Single character
string first = str[0..0];      // "T"
string last = str[-1];         // last character: "e"

// Substrings
string start = str[5..6];      // "is"
string rest = str[13..];       // "you have" (from index 13 to end)
string end = str[sizeof(str)-4..];    // "have" (last 4 chars)

// Negative indices count from end
string piece = str[sizeof(str)-8..sizeof(str)-8+2];  // "you"
```

### Practical Examples

```pike
//-----------------------------
// Recipe: Parse structured data
//-----------------------------

// Parse "John Doe, 30"
string name = "John Doe, 30";
string first_name, last_name;
int age;

if (sscanf(name, "%s %s, %d", first_name, last_name, age) == 3) {
    write("Name: %s %s, Age: %d\n", first_name, last_name, age);
}

// Parse complex string with array_sscanf
string data = "Header:Important:Data:12345";
array(string) parts = array_sscanf(data, "%[^:]:%[^:]:%[^:]:%s");
// Result: ({"Header", "Important", "Data", "12345"})
```

### Splitting Strings

```pike
//-----------------------------
// Recipe: Split strings into parts
//-----------------------------

string text = "word1 word2 word3";

// Split by whitespace
array(string) words = text / " ";
// Result: ({"word1", "word2", "word3"})

// Split into individual characters
array(string) chars = text / "";

// Split into chunks of n characters
string data = "abcdefghij";
int n = 3;
array(string) chunks = data / n;
// Result: ({"abc", "def", "ghi", "j"})

// Split with normalize_space for robust whitespace handling
string messy = "  word1   word2  word3  ";
array(string) clean = String.normalize_space(messy) / " ";
// Result: ({"word1", "word2", "word3"})
```

---

## Exchanging Values Without Using Temporary Variables

:::tip
Pike's destructuring assignment makes swapping values elegant.
:::

```pike
//-----------------------------
// Recipe: Swap variables without temp
//-----------------------------

string a = "alpha";
string b = "omega";

// Swap using array destructuring
[a, b] = ({b, a});
write("a: %s, b: %s\n", a, b);
// Output: a: omega, b: alpha

// Multiple variable assignment
array(string) months = ({"January", "March", "August"});
string alpha = months[0];
string beta = months[1];
string production = months[2];

// Rotate values
[alpha, beta, production] = ({beta, production, alpha});
write("%s, %s, %s\n", alpha, beta, production);
// Output: March, August, January
```

---

## Converting Between ASCII Characters and Values

```pike
//-----------------------------
// Recipe: Character/ASCII conversion
//-----------------------------

// Character to ASCII code
int char_code = 'a';           // 97
int newline_code = '\n';       // 10

// ASCII code to character
string char_from_code = sprintf("%c", 97);  // "a"

// Convert string to ASCII array
string text = "sample";
array(int) ascii_values = (array(int))text;
// Result: ({115, 97, 109, 112, 108, 101})

// Convert ASCII array back to string
string reconstructed = (string)ascii_values;
write("Original: %s, Reconstructed: %s\n", text, reconstructed);
```

---

## String Trimming and Cleaning

:::tip
- Use `String.trim_whites()` for basic trimming
- Use `String.trim_all_whites()` to remove all internal whitespace
- Use `String.normalize_space()` to normalize multiple spaces to single
:::

```pike
//-----------------------------
// Recipe: Clean up string whitespace
//-----------------------------

string messy = "  Hello   World!  \t\n";

// Basic trim (remove leading/trailing)
string trimmed = String.trim_whites(messy);
// Result: "Hello   World!"

// Trim all whitespace (internal too)
string no_spaces = String.trim_all_whites(messy);
// Result: "HelloWorld!"

// Normalize multiple spaces to single space
string normalized = String.normalize_space(messy);
// Result: "Hello World!"
```

---

## Case Manipulation

```pike
//-----------------------------
// Recipe: Change string case
//-----------------------------

string text = "Hello World 123";

// Convert to uppercase
string upper = upper_case(text);
// Result: "HELLO WORLD 123"

// Convert to lowercase
string lower = lower_case(text);
// Result: "hello world 123"

// Capitalize first character
string title = String.capitalize(text);
// Result: "Hello World 123"

// Case-insensitive comparison
string s1 = "hello";
string s2 = "Hello";
bool same = lower_case(s1) == lower_case(s2);  // true
```

---

## String Searching

```pike
//-----------------------------
// Recipe: Find text within strings
//-----------------------------

string text = "The quick brown fox jumps over the lazy dog";

// Find substring (returns index or -1)
int pos = search(text, "fox");
write("Found 'fox' at position: %d\n", pos);  // 16

// Check if contains (has_value)
bool has_fox = has_value(text, "fox");  // true

// Find last occurrence
int last_space = rsearch(text, " ");
write("Last space at: %d\n", last_space);

// Find all occurrences
array(int) positions = ({});
int search_pos = 0;
string needle = "o";
while ((search_pos = search(text, needle, search_pos)) != -1) {
    positions += ({search_pos});
    search_pos++;
}
write("Found '%s' at positions: %s\n", needle, (string)positions);
```

---

## String Replacement

```pike
//-----------------------------
// Recipe: Replace text in strings
//-----------------------------

string text = "The quick brown fox jumps over the lazy dog";

// Simple replacement
string replaced = replace(text, "fox", "cat");
// Result: "The quick brown cat jumps over the lazy dog"

// Multiple replacements using mapping
mapping replacements = ([
    "quick": "fast",
    "brown": "red",
    "lazy": "sleeping"
]);

string result = text;
foreach(indices(replacements);; string key) {
    result = replace(result, key, replacements[key]);
}
write("Multiple replacements: %s\n", result);
```

---

## Pattern Matching with Regex

```pike
//-----------------------------
// Recipe: Use regular expressions
//-----------------------------

// Email validation
string email = "user@example.com";
object email_re = Regexp.SimpleRegexp("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$");

if (email_re->match(email)) {
    write("Valid email\n");
}

// Extract with capture groups
string log_entry = "2023-01-15 14:30:25 INFO: User login successful";
string date, time, level, message;

if (sscanf(log_entry, "%s %s %[^:]: %s", date, time, level, message) == 4) {
    write("Date: %s, Level: %s\n", date, level);
}

// URL extraction
string html = '<a href="https://example.com">Link</a>';
object url_re = Regexp.SimpleRegexp("href=\"([^\"]+)\"");
array(string) urls = url_re->match(html);
if (urls) {
    write("URL: %s\n", urls[1]);  // Capture group 1
}
```

:::tip
Use `sscanf()` for simple patterns and `Regexp.SimpleRegexp()` for complex regex matching.
:::

---

## String Building with Buffers

:::warning
- **DON'T**: Build large strings with repeated `+=` in a loop (slow)
- **DO**: Use `String.Buffer` for efficient string building
:::

```pike
//-----------------------------
// Recipe: Efficient string building
//-----------------------------

// WRONG: Inefficient
string result = "";
for (int i = 0; i < 1000; i++) {
    result += sprintf("Line %d\n", i);  // Creates new string each time!
}

// RIGHT: Efficient with Buffer
String.Buffer buffer = String.Buffer();

// Pre-allocate for better performance (optional)
buffer->set_preallocate(1024);

for (int i = 0; i < 1000; i++) {
    buffer->add(sprintf("Line %d\n", i));
}

string result = buffer->get();  // Get final string

// Add different types
buffer = String.Buffer();
buffer->add("Numbers: ");
buffer->add(42);      // Automatically converted to string
buffer->add(", ");
buffer->add(3.14);
write("%s\n", buffer->get());
// Output: "Numbers: 42, 3.14"
```

---

## String Formatting

```pike
//-----------------------------
// Recipe: Format strings with sprintf
//-----------------------------

string name = "Alice";
int age = 30;
float pi = 3.14159;

// Basic formatting
string formatted = sprintf("Name: %s, Age: %d", name, age);

// Float precision
string pi_str = sprintf("Pi: %.2f", pi);  // "Pi: 3.14"

// Field width
string padded = sprintf("Name: %-10s | Age: %3d", name, age);
// Output: "Name: Alice      | Age:  30"

// Multiple values from array
array(string) fruits = ({"apple", "banana", "cherry"});
string joined = sprintf("%{%s, %}", fruits);
// Output: "apple, banana, cherry"
```

---

## Splitting and Joining

```pike
//-----------------------------
// Recipe: Split and join strings
//-----------------------------

// CSV parsing
string csv = "name,age,city\nJohn,30,New York\nJane,25,London";
array(string) lines = csv / "\n";

foreach(lines;; string line) {
    if (!sizeof(line)) continue;
    array(string) fields = line / ",";
    write("%s is %d years old\n", fields[0], (int)fields[1]);
}

// Join with custom separator
array(string) parts = ({"2024", "01", "15"});
string date = parts * "-";  // "2024-01-15"

// HTML list generation
array(string) items = ({"Apple", "Banana", "Cherry"});
string html = "<ul>\n" +
               ({"  <li>", items[*], "</li>\n"}) * "" +
               "</ul>";
```

---

## Reversing Strings

```pike
//-----------------------------
// Recipe: Reverse strings
//-----------------------------

string text = "Hello, World!";

// Character-level reversal
string reversed = String.reverse(text);
// Result: "!dlroW ,olleH"

// Word-level reversal
array(string) words = text / " ";
array(string) reversed_words = reverse(words);
string word_reversed = reversed_words * " ";
// Result: "World! Hello,"
```

---

## Practical Examples

### Validate Input

```pike
//-----------------------------
// Recipe: Validate user input
//-----------------------------

// Email validation
bool is_valid_email(string email) {
    object re = Regexp.SimpleRegexp("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$");
    return re->match(email);
}

// Sanitize input (remove HTML)
string sanitize_html(string text) {
    text = replace(text, "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    return text;
}
```

### Generate Slugs

```pike
//-----------------------------
// Recipe: Create URL-friendly slugs
//-----------------------------

string make_slug(string text) {
    // Convert to lowercase
    string slug = lower_case(text);

    // Replace non-alphanumeric with hyphens
    slug = Regexp.SimpleRegexp("[^a-z0-9]+")->replace(slug, "-");

    // Remove leading/trailing hyphens
    slug = String.trim_whites(slug);

    // Limit length
    if (sizeof(slug) > 50) {
        slug = slug[0..49];
    }

    return slug;
}

write("%s\n", make_slug("Hello World!"));
// Output: "hello-world"
```

### Text Statistics

```pike
//-----------------------------
// Recipe: Analyze text
//-----------------------------

mapping analyze_text(string text) {
    array(string) words = String.normalize_space(text) / " ";
    array(string) sentences = text / "." - ({""});
    array(string) lines = text / "\n";

    return ([
        "word_count": sizeof(words),
        "sentence_count": sizeof(sentences),
        "line_count": sizeof(lines),
        "char_count": sizeof(text),
        "avg_word_length": sizeof(text) / sizeof(words)
    ]);
}
```

---

## See Also

- [Arrays](/docs/basics/arrays) - Working with lists
- [Pattern Matching](/docs/basics/pattern-matching) - Advanced regex patterns
- [File Access](/docs/files/file-access) - Reading/writing text files
- [Web Automation](/docs/network/web-automation) - Processing HTML and HTTP
