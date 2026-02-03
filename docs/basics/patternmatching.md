---
id: patternmatching
title: Pattern Matching
sidebar_label: Pattern Matching
---

## Introduction

```pike
// Pattern Matching with Pike 8
// Modern implementation using String.pmod and Regexp
// Comprehensive pattern matching solutions

// Modern string imports for advanced pattern matching
import String;
import Array;

// String utilities for modern pattern matching
constant Buffer = __builtin.Buffer;
constant Iterator = __builtin.string_iterator;
constant SplitIterator = __builtin.string_split_iterator;
constant fuzzymatch = String.fuzzymatch;
constant levenshtein_distance = String.levenshtein_distance;
constant soundex = String.soundex;
constant common_prefix = String.common_prefix;
```

## Copying and Substituting Simultaneously

```pike
// Recipe 6.1: Simple Substitution - Modern Approach
//-----------------------------
string src = "This is a test string";
string dst;

// Method 1: Using String.replace() - more efficient than regex for simple cases
dst = replace(src, (["test": "replacement"]));
// "This is a replacement string"

// Method 2: Using Regexp for complex pattern matching
dst = Regexp("this")->replace(src, "that");
// "that is a test string" (case-sensitive)

// Method 3: Case-insensitive replacement with Regexp
dst = Regexp("(?i)this")->replace(src, "that");
// "that is a test string" (case-insensitive)

//-----------------------------
// Recipe 6.2: Extract Basename (Strip Directory)
//-----------------------------
string path = "/home/user/document.txt";

// Modern approach: Using String manipulation (more efficient)
array(string) parts = path"/";
string basename = parts[-1];
// "document.txt"

// Alternative: Using regex for complex path patterns
string basename_regex = Regexp("^.*/")->replace(path, "");
// "document.txt"

//-----------------------------
// Recipe 6.3: Capitalize Words with Callback
//-----------------------------
string capword = Regexp("[a-z]+")->replace
        ("foo.bar",
            lambda(string c) {
                return capitalize(c);
            } );
// "Foo.Bar"

// Using String.pmod function for better word capitalization
string title_case = sillycaps("foo bar");
// "Foo Bar"

//-----------------------------
```

## Matching Letters

```pike
// Recipe 6.4: Matching Letters (Character Classes)
//-----------------------------

string text = "Hello World 123!";

// Extract all letters (alphabetic characters)
string letters = Regexp("[a-zA-Z]+")->match(text);
// "HelloWorld" (first match)

// Find all letters using split and filter
array(string) all_letters = filter(text"", lambda(string c) {
    return c >= 'a' && c <= 'z' ||
           c >= 'A' && c <= 'Z';
}*"";

// "HelloWorld"

//-----------------------------
// Recipe 6.5: Matching Words with Word Boundaries
//-----------------------------

string sentence = "The quick brown fox jumps over the lazy dog";

// Find words starting with 'q'
array(string) q_words = Regexp("\bq\w*")->match(sentence);
// ({ "quick" }) (first match)

// Extract all words using modern string splitting
array(string) words = normalize_space(sentence)/" ";
// ({ "The", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog" })

// Find words with specific patterns
array(string) long_words = filter(words, lambda(string word) {
    return sizeof(word) > 4;
});
// ({ "quick", "brown", "jumps" })

//-----------------------------
```

## Pattern Matching with Fuzzy Logic

```pike
// Recipe 6.6: Fuzzy String Matching
//-----------------------------

string target = "programming";
array(string) candidates = ({
    "programming", "programing", "progamming",
    "codding", "development", "writing"
});

// Calculate similarity scores using fuzzymatch
array(int) scores = map(candidates, lambda(string candidate) {
    return fuzzymatch(target, candidate);
});

// Find matches above threshold (80% similarity)
array(string) good_matches = filter(candidates, lambda(string candidate, int index) {
    return scores[index] >= 80;
});

// Sort by similarity score
array(string) sorted_matches = sort(good_matches, lambda(string a, string b) {
    return fuzzymatch(target, b) - fuzzymatch(target, a);
});

//-----------------------------
// Recipe 6.7: Phonetic Matching with Soundex
//-----------------------------

array(string) names = ({
    "Robert", "Rupert", "Rubin",
    "Smith", "Smythe", "Smyth"
});

// Group names by Soundex code
mapping(string:array(string)) soundex_groups = ([]);
foreach (names, string name) {
    string code = soundex(name);
    if (!soundex_groups[code])
        soundex_groups[code] = ({});
    soundex_groups[code] += ({name});
}

// Output Soundex groups
foreach (soundex_groups; string code; array(string) group) {
    write("Soundex %s: %s\n", code, implode_nicely(group));
}
// Soundex R163: Robert, Rupert, Rubin
// Soundex S530: Smith, Smythe, Smyth

//-----------------------------
```

## Regular Expression Advanced Features

```pike
// Recipe 6.8: Matching Multiple Lines
//-----------------------------

string multiline_text = "First line\nSecond line\nThird line";

// Extract lines containing specific pattern
array(string) matching_lines = Regexp("line.*\n")->match(multiline_text);
// ({ "First line\n", "Second line\n", "Third line" })

// Process line by line using modern iteration
array(string) processed_lines = map(multiline_text"\n", lambda(string line) {
    return if(Regexp("line")->match(line),
              capitalize(line),
              line);
});

//-----------------------------
// Recipe 6.9: Greedy and Non-Greedy Matches
//-----------------------------

string html = "<div>Content</div><div>More content</div>";

// Greedy match (default)
array(string) greedy_matches = Regexp("<div>.*</div>")->match(html);
// ({ "<div>Content</div><div>More content</div>" })

// Non-greedy match
array(string) nongreedy_matches = Regexp("<div>.*?</div>")->match(html);
// ({ "<div>Content</div>", "<div>More content</div>" })

//-----------------------------
// Recipe 6.10: Capturing Groups
//-----------------------------

string log_entry = "192.168.1.1 - - [01/Jan/2023:12:00:00 +0000] \"GET /index.html HTTP/1.1\" 200 1024";

// Extract IP address and timestamp using capturing groups
array(string) matches = Regexp("^(\d+\.\d+\.\d+\.\d+).*\[([^\]]+)\].*\"(\w+) (.*) HTTP")->match(log_entry);

if (matches && sizeof(matches) > 3) {
    string ip = matches[1];
    string timestamp = matches[2];
    string method = matches[3];
    string path = matches[4];

    write("IP: %s, Method: %s, Path: %s\n", ip, method, path);
}
// IP: 192.168.1.1, Method: GET, Path: /index.html

//-----------------------------
```

## Pattern Matching Utilities

```pike
// Recipe 6.11: Common Prefix Finding
//-----------------------------

array(string) strings = ({
    "apple", "apricot", "april", "apology"
});

string prefix = common_prefix(strings);
// "ap"

//-----------------------------
// Recipe 6.12: String Distance and Similarity
//-----------------------------

string s1 = "kitten";
string s2 = "sitting";

// Calculate Levenshtein distance
int distance = levenshtein_distance(s1, s2);
// 3 (kitten → sitten → sittin → sitting)

// Calculate similarity percentage
int similarity = fuzzymatch(s1, s2);
// 73 (based on normalized distance)

//-----------------------------
// Recipe 6.13: Pattern Validation
//-----------------------------

bool validate_email(string email) {
    return Regexp("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
           ->match(email) != 0;
}

bool validate_url(string url) {
    return Regexp("^https?://[^\s/$.?#].[^\s]*$")
           ->match(url) != 0;
}

// Test validation functions
write("Email valid: %d\n", validate_email("test@example.com"));
write("URL valid: %d\n", validate_url("https://pike.ida.liu.se"));

//-----------------------------
// Recipe 6.14: Advanced String Processing
//-----------------------------

// Using String iterators for efficient processing
string text = "Hello, world!";
String.Iterator it = Iterator(text);

string result = "";
while (it->index() < sizeof(it->value())) {
    string c = it->value()[it->index()];
    if (c != ',' && c != '!')
        result += c;
    it->next();
}

// Using Buffer for efficient string building
Buffer buf = Buffer();
buf->add("Processed: ");
buf->add(result);

write("%s\n", buf->get());
// "Processed: Hello world"

//-----------------------------
```