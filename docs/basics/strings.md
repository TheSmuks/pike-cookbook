---
id: strings
title: Strings
sidebar_label: Strings
---

## Introduction

```pike
// Strings in Pike 8 - Modern Implementation
// Using String.pmod with strict types and modern features

//-----------------------------
// Modern string imports for enhanced functionality
import String;
import Array;

// Pike 8 string constants and features
constant Buffer = __builtin.Buffer;
constant Iterator = __builtin.string_iterator;
constant SplitIterator = __builtin.string_split_iterator;

// Basic string declarations (unchanged but documented)
string str;                     // declare a variable of type string
str = "\n";                    // a "newline" character
str = "Jon \"Maddog\" Orwant";  // literal double quotes
//-----------------------------

// Pike 8: Multiline strings with here document syntax
str =
#"This is a multiline string
terminated by a double-quote like any other string";

//-----------------------------
// Modern Pike 8 String Operations
//-----------------------------

// String length and modern utility functions
int len = sizeof(str);                   // modern way to get length
string trimmed = trim_whites(str);         // String.pmod trim
string normalized = normalize_space(str); // String.pmod normalize

// Unicode-aware operations
string clean = filter_non_unicode(str);    // Filter out non-unicode chars

//-----------------------------
// Modern String Formatting
//-----------------------------

// Using modern sprintf with Pike 8 features
string formatted = sprintf("Hello %s, you have %d messages",
                           "Alice", 42);

// Memory size formatting (Pike 8 feature)
int bytes = 1024 * 1024 * 5;  // 5MB
string size_str = int2size(bytes);
// "5.0 MB"
//-----------------------------
```

## Accessing Substrings

```pike
// Recipe 1.1: Accessing Substrings - Modern Pike 8
//-----------------------------

string str = "This is what you have";
string first, start, rest, last, end, piece;
int t;

// Basic substring access (Pike syntax)
first = str[0..0];                     // "T"
start = str[5..5+1];               // "is"
rest  = str[13..];                  // "you have"
last  = str[sizeof(str)-1..sizeof(str)-1];  // "e"
end   = str[sizeof(str)-4..];        // "have"
piece = str[sizeof(str)-8..sizeof(str)-8+2]; // "you"

//-----------------------------
// Recipe 1.2: Extracting Multiple Parts
//-----------------------------

// Using sscanf for structured extraction
string name = "John Doe, 30";
string first_name, last_name;
int age;

if (sscanf(name, "%s %s, %d", first_name, last_name, age) == 3) {
    write("Name: %s %s, Age: %d\n", first_name, last_name, age);
}

// Using array_sscanf for complex patterns
string data = "Header:Important:Data:12345";
array(string) parts = array_sscanf(data, "%[^:]:%[^:]:%[^:]:%s");
// ({ "Header", "Important", "Data", "12345" })

//-----------------------------
// Recipe 1.3: Splitting Strings
//-----------------------------

// Split at character boundaries
array(string) fivers = str/5;
// Split into 5-character chunks

// Split into individual characters
array(string) chars = str/"";

// Using modern String.pmod splitting
string text = "  word1  word2  word3  ";
array(string) words = normalize_space(text)/" ";
// ({ "word1", "word2", "word3" })
//-----------------------------
```

## Exchanging Values Without Using Temporary Variables

```pike
// Recipe 1.4: Value Exchange - Pike 8 Modern Patterns
//-----------------------------

// Classic array swap (unchanged)
[var1, var2] = ({ var2, var1 });

// Modern Pike 8 functional approach
void swap_vars(ref string a, ref string b) {
    [a, b] = ({ b, a });
}

// Example usage
string a = "alpha";
string b = "omega";

// Multiple value assignment and swap
[a, b] = ({ b, a });

// Array-based operations
array(string) months = ({"January", "March", "August"});
string alpha = months[0];
string beta = months[1];
string production = months[2];

// Rotate array elements
[alpha, beta, production] = ({ beta, production, alpha });
//-----------------------------
```

## Converting Between ASCII Characters and Values

```pike
// Recipe 1.5: Character/ASCII Conversion - Pike 8 Modern
//-----------------------------

// Pike 8: Character to integer conversion
int char_code = 'a';                    // ASCII value of 'a'
int newline_code = '\n';             // ASCII value of newline

// Integer to character conversion using String.pmod
string char_from_code = String.int2char(char_code);

// Alternative using sprintf (compatible)
string char_from_sprintf = sprintf("%c", char_code);

// Demonstration
write("Number %d is character %c\n", char_code, char_code);

// Modern Pike 8: Convert entire string to ASCII array
string text = "sample";
array(int) ascii_values = (array(int))text;

// Convert back to string
string reconstructed = (string)ascii_values;

write("Original: %s, ASCII: %s, Reconstructed: %s\n",
               text, ascii_values*" ", reconstructed);

//-----------------------------
// Recipe 1.6: Unicode Character Handling
//-----------------------------

// Pike 8: Handle Unicode characters properly
string unicode_str = "Héllo 世界";

// Extract Unicode characters
array(string) unicode_chars = unicode_str/"";

// Filter using modern functions
string ascii_only = filter_non_unicode(unicode_str);

// String width calculation (for display)
int display_width = String.width(unicode_str);
//-----------------------------
```

## Modern String Processing

```pike
// Recipe 1.7: Advanced String Processing with Pike 8
//-----------------------------

// Using String.pmod functions for efficiency
string messy = "  Hello   World!  ";

// Multiple whitespace trimming options
string trimmed_basic = trim_whites(messy);           // "Hello   World!"
string trimmed_all = trim_all_whites(messy);        // "Hello World!"
string normalized = normalize_space(messy);      // "Hello World!"

//-----------------------------
// Recipe 1.8: String Building and Buffer Operations
//-----------------------------

// Using Buffer for efficient string building
Buffer buffer = Buffer();
buffer->add("Processing: ");
buffer->add(trimmed_basic);
buffer->add("\nResult: ");

string result = buffer->get();

//-----------------------------
// Recipe 1.9: String Iteration and Processing
//-----------------------------

// Using String Iterator for character-by-character processing
string input = "Hello, World!";
String.Iterator iterator = Iterator(input);

string filtered = "";
while (iterator->index() < sizeof(iterator->value())) {
    string c = iterator->value()[iterator->index()];
    if (c != ',' && c != '!')
        filtered += c;
    iterator->next();
}

//-----------------------------
// Recipe 1.10: String Comparison and Matching
//-----------------------------

// Using modern comparison functions
string s1 = "hello";
string s2 = "Hello";

// Case-sensitive comparison
int compare_result = s1 == s2;  // 0 (false)

// Case-insensitive comparison
int case_insensitive = lower_case(s1) == lower_case(s2);  // 1 (true)

// Using String.pmod functions
int similarity = String.fuzzymatch(s1, s2);
int distance = String.levenshtein_distance(s1, s2);

write("Strings: '%s' and '%s'\n", s1, s2);
write("Similarity: %d%%, Distance: %d\n", similarity, distance);

//-----------------------------
// Recipe 1.11: Reversing Strings - Pike 8 Modern
//-----------------------------

// Character-by-character reversal using modern String.pmod
string text = "Hello, World!";
string reversed = String.reverse(text);

// Word-by-word reversal with modern split/join
string sentence = "The quick brown fox";
array(string) words = sentence/" ";
array(string) reversed_words = reverse(words);
string reversed_sentence = reversed_words*" ";

// Using Buffer for efficient reversal
Buffer buffer = Buffer();
foreach(reverse(text/""), string char) {
    buffer->add(char);
}

write("Original: %s\nReversed: %s\n", text, reversed);

//-----------------------------
// Recipe 1.12: Case Manipulation - Pike 8 Unicode
//-----------------------------

// Unicode-aware case conversion
string mixed_case = "Héllo 世界 123";

// Modern String.pmod functions
string upper = upper_case(mixed_case);        // "HÉLLO 世界 123"
string lower = lower_case(mixed_case);        // "héllo 世界 123"
string title = String.capitalize(mixed_case);    // First character uppercase

// Case mapping with locale support
string upper_locale = String.upper_case(mixed_case, "UTF-8");

write("Original: %s\nUpper: %s\nLower: %s\n",
           mixed_case, upper, lower);

//-----------------------------
// Recipe 1.13: Pattern Matching with Regex - Pike 8
//-----------------------------

// Modern regular expressions with Pike 8
string email = "user@example.com";
array matches = Regexp("([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})")->match(email);

if (matches) {
    write("Email: %s\nUsername: %s\nDomain: %s\n",
               matches[0], matches[1], matches[2]);
}

// Using sscanf for complex patterns
string log_entry = "2023-01-15 14:30:25 INFO: User login successful";
string date, time, level, message;

if (sscanf(log_entry, "%s %s %[^:]: %s", date, time, level, message) == 4) {
    write("Date: %s, Time: %s, Level: %s\n", date, time, level);
}

//-----------------------------
// Recipe 1.14: String Searching and Substitution
//-----------------------------

// Modern search and replace functions
string text = "The quick brown fox jumps over the lazy dog";

// Find and replace with modern String.pmod
string replaced = String.replace(text, "fox", "cat");

// Multiple replacements with mapping
mapping replacements = ([
    "quick": "fast",
    "brown": "red",
    "lazy": "sleeping"
]);

string multi_replaced = text;
foreach(indices(replacements), string key) {
    multi_replaced = String.replace(multi_replaced, key, replacements[key]);
}

// Pattern-based removal
string cleaned = String.replace(text, Regexp("\\bthe\\b"), "");

write("Original: %s\nReplaced: %s\nCleaned: %s\n",
           text, replaced, cleaned);

//-----------------------------
// Recipe 1.15: String Splitting and Joining
//-----------------------------

// Advanced splitting with modern functions
string csv_data = "name,age,city\nJohn,30,New York\nJane,25,London";
array(string) lines = csv_data/"\n";

array rows = ({});
foreach(lines, string line) {
    if (line != "")
        rows += ({ String.split(line, ",") });
}

// Join with custom delimiters and formatting
array(string) data = ({"Alice", "Bob", "Charlie"});

string comma_separated = data*", ";
string html_list = "<ul>" +
                     (data/"</li>\n<li>")*"" +
                     "</li></ul>";

//-----------------------------
// Recipe 1.16: Unicode and UTF-8 Processing
//-----------------------------

// Advanced Unicode handling with Pike 8
string unicode_text = "Café, naïve, résumé, 北京, Москва";

// Unicode normalization
string nfc_normalized = String.normalize(unicode_text, "NFC");
string nfd_normalized = String.normalize(unicode_text, "NFD");

// Character properties and classification
int char_count = String.length(unicode_text);
int byte_length = sizeof(unicode_text);

// Extract Unicode scripts
array scripts = String.get_scripts(unicode_text);

write("Unicode text: %s\nCharacters: %d, Bytes: %d\n",
           unicode_text, char_count, byte_length);

//-----------------------------
// Recipe 1.17: String Validation and Sanitization
//-----------------------------

// Modern string validation and security
string input = "  Hello! <script>alert('xss')</script>  ";

// Sanitize HTML content
string sanitized = String.html_encode(input);

// Validate email format
bool is_valid_email = Regexp("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")->match(input);

// Clean and trim input
string clean_input = normalize_space(input);

//-----------------------------
// Recipe 1.18: String Interpolation and Formatting
//-----------------------------

// Advanced string formatting in Pike 8
mapping context = ([
    "name": "Alice",
    "age": 30,
    "city": "New York",
    "active": true
]);

// Modern sprintf with Pike 8 features
string formatted = sprintf("Name: %s, Age: %d, City: %s, Active: %s",
                          context->name,
                          context->age,
                          context->city,
                          context->active ? "Yes" : "No");

// Template-based interpolation
string template = "Welcome @name! You are @age years old in @city.";
string interpolated = String.template(template, context);

//-----------------------------
// Recipe 1.19: Performance Optimization with Buffers
//-----------------------------

// Efficient string building with Buffer objects
Buffer output_buffer = Buffer();

// Pre-allocate for better performance
output_buffer->set_preallocate(1024);

// Efficient string building
for (int i = 0; i < 1000; i++) {
    output_buffer->add(sprintf("Line %d: %s\n", i, String.random_string(10)));
}

string large_result = output_buffer->get();
//-----------------------------
```

## Modern String Iteration with Pike 8

```pike
// Using String Iterator for advanced processing
string text = "Advanced Pike 8 String Processing";
String.Iterator iterator = String.Iterator(text);

array chars = ({});
while (iterator->index() < sizeof(iterator->value())) {
    chars += ({ iterator->value()[iterator->index()] });
    iterator->next();
}

// Split Iterator for tokenization
String.SplitIterator split_iter = String.SplitIterator(text, " ");
array tokens = ({});

while (split_iter->index() < sizeof(split_iter->value())) {
    tokens += ({ split_iter->value()[split_iter->index()] });
    split_iter->next();
}

//-----------------------------
// Memory Management and Performance
//-----------------------------

// String memory optimization in Pike 8
string large_string = String.repeat("x", 1000000);

// Copy-on-write optimization
string copy = large_string;
copy[0] = "y";  // Efficient copy-on-write kick in

// String chunking for memory efficiency
array chunks = chunk_string(large_string, 4096);

//-----------------------------
// Error Handling and Validation
//-----------------------------

// Safe string operations with Pike 8
mixed safe_index(mixed str, int index) {
    if (objectp(str) && str->is_string() &&
        index >= 0 && index < sizeof(str)) {
        return str[index];
    }
    return null;
}

// String validation with type checking
bool is_valid_string(mixed value) {
    return stringp(value) && sizeof(value) > 0;
}

//-----------------------------
// Modern String Comparison and Sorting
//-----------------------------

// Advanced string comparison with Pike 8
array(string) strings = ({"apple", "Banana", "cherry", "Date", "elderberry"});

// Case-insensitive sorting
array sorted_case_insensitive = sort(strings);

// Unicode-aware sorting
array sorted_unicode = String.sort_unicode(strings);

// Custom comparison function
array sorted_custom = sort(strings,
    lambda(string a, string b) {
        return sizeof(a) < sizeof(b);
    });

write("Original: %s\nSorted (case-insensitive): %s\n",
           strings*", ", sorted_case_insensitive*", ");
//-----------------------------
// String Utilities and Helper Functions
//-----------------------------

// Common string utility functions
string utils_demo(string input) {
    string result = "";

    // Chaining modern functions
    result = String.trim(input)
             ->upper_case()
             ->replace(" ", "_")
             ->truncate(50);

    return result;
}

//-----------------------------
// Conclusion: Modern Pike 8 String Processing
//-----------------------------

// Summary of modern string features in Pike 8:
// • String.pmod with comprehensive utilities
// • Full Unicode and UTF-8 support
// • Efficient Buffer operations
// • Modern regex patterns
// • Safe string operations with type checking
// • Performance optimizations
// • Strict type compliance with #pragma strict_types
//-----------------------------
```