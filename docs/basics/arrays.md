---
id: arrays
title: Arrays
sidebar_label: Arrays
---

# Arrays

## Introduction

Arrays in Pike are ordered collections of values. They're one of the most fundamental and frequently used data structures in Pike programming.

:::tip
Pike arrays are **dynamic** - they can grow and shrink as needed. Unlike C arrays, you don't need to declare the size upfront.
:::

### Creating Arrays

```pike
//-----------------------------
// Basic array syntax
//-----------------------------

// Simple array of strings
array(string) fruits = ({"apple", "banana", "cherry"});

// Array of integers
array(int) numbers = ({1, 2, 3, 4, 5});

// Mixed types (using 'mixed' type)
array(mixed) mixed = ({"text", 42, 3.14, true});

// Nested arrays (arrays within arrays)
array(string|array(string)) nested = ({
    "first",
    "second",
    ({"nested", "array"})
});
```

### Accessing Array Elements

```pike
//-----------------------------
// Array indexing (0-based)
//-----------------------------

array tune = ({"The", "Star-Spangled", "Banner"});

// Access by index
write("%s\n", tune[0]);  // "The"
write("%s\n", tune[1]);  // "Star-Spangled"
write("%s\n", tune[2]);  // "Banner"

// Negative indices count from the end
write("%s\n", tune[-1]); // "Banner" (last element)
write("%s\n", tune[-2]); // "Star-Spangled"
```

### Type-Safe Arrays

```pike
//-----------------------------
// Using type annotations for safety
//-----------------------------

// Only strings allowed in this array
array(string) words = ({"this", "that", "the", "other"});

// Only integers allowed
array(int) primes = ({2, 3, 5, 7, 11});

// Array that can contain strings OR arrays of strings
array(string|array(string)) flexible = ({
    "simple string",
    ({"nested", "array", "of", "strings"})
});

// Array where first level only contains arrays
array(array(int)) matrix = ({
    ({1, 2, 3}),
    ({4, 5, 6}),
    ({7, 8, 9})
});
```

:::note
Using type annotations like `array(string)` helps catch errors early when using `#pragma strict_types`.
:::

---

## Specifying a List in Your Program

### Creating Arrays from Different Sources

```pike
//-----------------------------
// Recipe: Creating arrays from various sources
//-----------------------------

// Method 1: Direct literal
array(string) a = ({"quick", "brown", "fox"});

// Method 2: Split a string into words
array(string) words = "Why are you teasing me?" / " ";
// Result: ({"Why", "are", "you", "teasing", "me?"})

// Method 3: Split multiline text into lines
array(string) lines = #"The boy stood on the burning deck,
It was as hot as glass." / "\n";

// Method 4: Read from file
array(string) file_lines = Stdio.read_file("data.txt") / "\n";

// Method 5: Range operator
array(int) range = ({1, 2, 3, 4, 5});  // Manual
array(int) auto_range = Array.range(1, 6);  // Using Array module

// Important: Proper Unicode string handling
array(string) ships = ({"Niña", "Pinta", "Santa María"});  // ✓ Correct
// NOT: array ships = "Niña Pinta Santa María"/" ";        // ✗ Wrong - splits incorrectly
```

:::warning
When splitting strings with spaces, be careful with Unicode characters. Always use array literals when you have exact values.
:::

### Practical Example: Word Processing

```pike
//-----------------------------
// Recipe: Process text word by word
//-----------------------------

string text = "The quick brown fox jumps over the lazy dog";

// Split into words
array(string) words = text / " ";

// Count words
int word_count = sizeof(words);
write("Word count: %d\n", word_count);  // 9

// Find words longer than 4 characters
array(string) long_words = filter(words, lambda(string w) {
    return sizeof(w) > 4;
});

write("Long words: %s\n", long_words * ", ");
// Output: quick, brown, jumps, over, lazy
```

---

## Printing a List with Commas

:::tip
Properly formatting lists for display is a common task. This recipe shows how to handle lists of any size with proper grammar.
:::

### The Problem

```pike
//-----------------------------
// Recipe: Proper comma-separated lists
//-----------------------------

// Simple join - always uses commas
array(string) items = ({"apple", "banana", "cherry"});
write("%s\n", items * ", ");
// Output: "apple, banana, cherry"

// But what about different list sizes?
// 1 item: "apple"
// 2 items: "apple and banana"
// 3+ items: "apple, banana, and cherry"
```

### The Solution

```pike
//-----------------------------
// Recipe: Grammatically correct list formatting
//-----------------------------

string commify_list(array(string) list) {
    switch(sizeof(list)) {
        case 0:
            return "";
        case 1:
            return list[0];
        case 2:
            return sprintf("%s and %s", list[0], list[1]);
        default:
            // Use semicolons if items contain commas
            string separator = ",";
            foreach(list;; string item) {
                if (search(item, ",") != -1) {
                    separator = ";";
                    break;
                }
            }

            // Join all but last with separator
            string all_but_last = list[..sizeof(list)-2] * (separator + " ");
            return sprintf("%s, and %s", all_but_last, list[-1]);
    }
}

// Test it
write("%s\n", commify_list(({"just one thing"}));
// Output: "just one thing"

write("%s\n", commify_list(({"Mutt", "Jeff"}));
// Output: "Mutt and Jeff"

write("%s\n", commify_list(({"Peter", "Paul", "Mary"}));
// Output: "Peter, Paul, and Mary"

write("%s\n", commify_list(({"recycle tired, old phrases",
                            "ponder big, happy thoughts"}));
// Output: "recycle tired, old phrases; and ponder big, happy thoughts"
```

---

## Changing Array Size

### Understanding Array Operations

```pike
//-----------------------------
// Recipe: Array size operations
//-----------------------------

void what_about_that_array(array list) {
    write("The array now has %d elements.\n", sizeof(list));
    write("The index of the last element is %d.\n", sizeof(list)-1);
    if (sizeof(list) > 3) {
        write("Element #3 is %O.\n", list[3]);
    }
}

array people = ({"Crosby", "Stills", "Nash", "Young"});
what_about_that_array(people);
// The array now has 4 elements.
// The index of the last element is 3.
// Element #3 is "Young"

// Removing elements (slicing)
people = people[..sizeof(people)-2];  // Remove last element
what_about_that_array(people);
// The array now has 3 elements.
// The index of the last element is 2.

// Growing arrays
people += allocate(10001 - sizeof(people));
what_about_that_array(people);
// The array now has 10001 elements.

// IMPORTANT: Cannot assign to non-existent index
// people[10000] = "value";  // ERROR! Index out of range
```

:::warning
**Gotcha**: You cannot assign to an array index that doesn't exist. Arrays don't auto-expand on assignment. Use `+=` or array operations to add elements.
:::

### Adding and Removing Elements

```pike
//-----------------------------
// Recipe: Adding and removing elements
//-----------------------------

array(string) list = ({"a", "b", "c"});

// Add single element
list += ({"d"});
// Result: ({"a", "b", "c", "d"})

// Add multiple elements
list += ({"e", "f", "g"});
// Result: ({"a", "b", "c", "d", "e", "f", "g"})

// Remove first element
list = list[1..];
// Result: ({"b", "c", "d", "e", "f", "g"})

// Remove last element
list = list[..sizeof(list)-2];
// Result: ({"b", "c", "d", "e", "f"})

// Insert element at position
list = list[..1] + ({"X"}) + list[2..];
// Result: ({"b", "c", "X", "d", "e", "f"})
```

### Using ADT for Queue/Stack Operations

```pike
//-----------------------------
// Recipe: Using ADT.Queue for FIFO operations
//-----------------------------

// ADT.Queue is more efficient for queue operations
ADT.Queue queue = ADT.Queue();

// Add elements
queue->write("first");
queue->write("second");
queue->write("third");

// Remove elements (FIFO)
mixed item;
while (item = queue->read()) {
    write("Got: %O\n", item);
}
// Output:
// Got: "first"
// Got: "second"
// Got: "third"

//-----------------------------
// Recipe: Using ADT.Stack for LIFO operations
//-----------------------------

ADT.Stack stack = ADT.Stack();

stack->push("bottom");
stack->push("middle");
stack->push("top");

// Pop elements (LIFO)
while (stack->peek()) {
    write("Popped: %O\n", stack->pop());
}
// Output:
// Popped: "top"
// Popped: "middle"
// Popped: "bottom"
```

---

## Doing Something with Every Element in a List

### Iterating with foreach

```pike
//-----------------------------
// Recipe: Iterating over arrays
//-----------------------------

// Basic iteration
array(string) users = ({"alice", "bob", "charlie"});

foreach(users;; string user) {
    write("User: %s\n", user);
}

// Iteration with index
foreach(users; int i; string user) {
    write("User #%d: %s\n", i, user);
}

// Iterating over environment variables
foreach(sort(indices(getenv()));; string var) {
    write("%s=%s\n", var, getenv(var));
}

// Process file line by line
Stdio.File file = Stdio.File("data.txt", "r");
foreach(file->line_iterator();; string line) {
    if (sizeof(String.trim_whites(line))) {
        write("Processing: %s\n", line);
    }
}
file->close();
```

### Practical Examples

```pike
//-----------------------------
// Recipe: Filter and process arrays
//-----------------------------

// Example 1: Find large files
array(string) filenames = ({"file1.txt", "file2.log", "file3.dat"});
array(int) sizes = ({1024, 2048, 512});

foreach(sizes; int i; int size) {
    if (size > 1024) {
        write("%s is large (%d bytes)\n", filenames[i], size);
    }
}

// Example 2: Process command output
object pipe = Stdio.File();
Process.create_process(({"who"}), (["stdout": pipe->pipe()]));

foreach(pipe->line_iterator();; string line) {
    if (search(line, "root") != -1) {
        write("Root user logged in: %s\n", line);
    }
}

// Example 3: Transform array elements
array(int) numbers = ({1, 2, 3, 4, 5});
array(int) doubled = map(numbers, lambda(int n) { return n * 2; });
write("Doubled: %s\n", (string)doubled);
// Output: Doubled: ({2, 4, 6, 8, 10})
```

### Using Automap for Concise Code

```pike
//-----------------------------
// Recipe: Pike's powerful automap feature
//-----------------------------

// Automap applies an operation to every element
array(string) files = ({"file1.txt", "file2.txt", "file3.txt"});

// Call function on each element
object stat = files->file_stat();  // Returns array of stat objects

// Get file sizes
array(int) sizes = map(files, Stdio.file_stat, Stdio.STAT_SIZE);

// Method chaining with automap
array(string) trimmed = String.trim_whites(files[*]);

// Nested operations
array(array(string)) matrix = (({({"a", "b"}, {"c", "d"}, {"e", "f"})}));
array(string) flattened = matrix[*] * "";
// Result: ({"ab", "cd", "ef"})
```

:::tip
The `[*]` syntax (automap) is Pike's way of applying an operation to every element. It's concise and efficient!
:::

### Modifying Elements In-Place

```pike
//-----------------------------
// Recipe: Modifying array elements
//-----------------------------

// WRONG: This doesn't modify the array
array(int) nums = ({1, 2, 3, 4, 5});
foreach(nums;; int item) {
    item--;  // This only modifies the local variable
}
write("%{%d %}\n", nums);  // Still: 1 2 3 4 5

// RIGHT: Use index to modify
array(int) nums = ({1, 2, 3, 4, 5});
foreach(nums; int index;) {
    nums[index]--;
}
write("%{%d %}\n", nums);  // Now: 0 1 2 3 4

// OR: Use map to create new array
array(int) nums = ({1, 2, 3, 4, 5});
array(int) decremented = map(nums, lambda(int n) { return n - 1; });
```

---

## Extracting Unique Elements from a List

### Finding Unique Values

```pike
//-----------------------------
// Recipe: Remove duplicates from array
//-----------------------------

array(mixed) list = ({"a", "b", "a", "c", "b", "d"});

// Method 1: Using mapping (most efficient)
mapping seen = ([]);
array(mixed) uniq = ({});

foreach(list;; mixed item) {
    if (!seen[item]) {
        seen[item] = 1;
        uniq += ({item});
    }
}
write("Unique: %s\n", (string)uniq);
// Output: ({"a", "b", "c", "d"})

// Method 2: Using indices of multiset
mapping seen = ([]);
foreach(list;; mixed item) {
    seen[item]++;
}
array(mixed) uniq = indices(seen);

// Method 3: Using multiset directly
array(mixed) uniq = indices(({ list[*], 1 }));

// Method 4: Preserving order
array(mixed) uniq = list & indices(({ list[*], 1 }));
```

### Practical Example: Count User Logins

```pike
//-----------------------------
// Recipe: Count unique users from 'who' output
//-----------------------------

object pipe = Stdio.File();
Process.create_process(({"who"}), (["stdout": pipe->pipe()]));

mapping(string:int) user_count = ([]);

foreach(pipe->line_iterator();; string line) {
    // First word is username
    array(string) parts = line / " ";
    string user = parts[0];
    user_count[user]++;
}

array(string) users = sort(indices(user_count));
write("Unique users logged in: %d\n", sizeof(users));
write("Users: %s\n", users * ", ");

foreach(users;; string user) {
    write("  %s: %d sessions\n", user, user_count[user]);
}
```

---

## Finding Elements in One Array but Not Another

:::tip
Pike's set operators make this incredibly easy!
:::

### Set Difference

```pike
//-----------------------------
// Recipe: Find elements only in first array
//-----------------------------

array A = ({1, 2, 3, 4, 5});
array B = ({3, 4, 5, 6, 7});

// Elements in A but not in B
array a_only = A - B;
write("Only in A: %s\n", (string)a_only);
// Output: ({1, 2})

// Elements in B but not in A
array b_only = B - A;
write("Only in B: %s\n", (string)b_only);
// Output: ({6, 7})

// Elements in both
array both = A & B;
write("In both: %s\n", (string)both);
// Output: ({3, 4, 5})

// All unique elements (union)
array all = A | B;
write("All: %s\n", (string)all);
// Output: ({1, 2, 3, 4, 5, 6, 7})

// Elements in either but not both (symmetric difference)
array xor = A ^ B;
write("XOR: %s\n", (string)xor);
// Output: ({1, 2, 6, 7})
```

### Practical Example: Missing Files

```pike
//-----------------------------
// Recipe: Find which required files are missing
//-----------------------------

array(string) required = ({"config.txt", "data.db", "cache.bin", "index.idx"});
array(string) existing = ({"config.txt", "cache.bin"});

// Find missing files
array(string) missing = required - existing;

if (sizeof(missing)) {
    werror("Missing required files:\n");
    foreach(missing;; string file) {
        werror("  - %s\n", file);
    }
    exit(1);
}
```

---

## Computing Union, Intersection, or Difference of Unique Lists

### Set Operations

```pike
//-----------------------------
// Recipe: Mathematical set operations
//-----------------------------

array(int) a = ({1, 3, 5, 6, 7, 8});
array(int) b = ({2, 3, 5, 7, 9});

// Union: all elements from both arrays
array(int) union = a | b;
write("Union: %s\n", (string)union);
// Output: ({1, 3, 5, 6, 7, 8, 2, 9})

// Intersection: elements common to both
array(int) intersection = a & b;
write("Intersection: %s\n", (string)intersection);
// Output: ({3, 5, 7})

// Difference: elements in a but not in b
array(int) difference = a - b;
write("Difference: %s\n", (string)difference);
// Output: ({1, 6, 8})

// Symmetric difference: elements in either but not both
array(int) symdiff = a ^ b;
write("Symmetric difference: %s\n", (string)symdiff);
// Output: ({1, 6, 8, 2, 9})
```

### Practical Example: Tag Management

```pike
//-----------------------------
// Recipe: Managing blog post tags
//-----------------------------

// User's current tags
array(string) user_tags = ({"pike", "programming", "tutorial"});

// Suggested related tags
array(string) suggested = ({"programming", "web", "pike", "database"});

// Tags user already has (don't suggest again)
array(string) already_has = user_tags & suggested;
write("You already have: %s\n", (string)already_has);
// Output: ({"programming", "pike"})

// New tags to suggest
array(string) new_suggestions = suggested - user_tags;
write("New suggestions: %s\n", (string)new_suggestions);
// Output: ({"web", "database"})

// All tags combined
array(string) all_tags = user_tags | suggested;
write("All related tags: %s\n", (string)all_tags);
// Output: ({"pike", "programming", "tutorial", "web", "database"})
```

---

## Appending One Array to Another

### Joining Arrays

```pike
//-----------------------------
// Recipe: Combining arrays
//-----------------------------

array(string) members = ({"Time", "Flies"});
array(string) initiates = ({"An", "Arrow"});

// Append arrays
members += initiates;
write("%s\n", members * " ");
// Output: "Time Flies An Arrow"

// Insert at specific position
members = members[..1] + ({"Like"}) + members[2..];
write("%s\n", members * " ");
// Output: "Time Flies Like An Arrow"

// Replace elements
members[0] = "Fruit";
members = members[..sizeof(members)-3] + ({"A", "Banana"});
write("%s\n", members * " ");
// Output: "Fruit Flies Like A Banana"
```

### Performance Considerations

```pike
//-----------------------------
// Recipe: Efficient array building
//-----------------------------

// Method 1: Building array incrementally
// (Less efficient for large arrays)
array(int) result = ({});
for (int i = 0; i < 1000; i++) {
    result += ({i});  // Creates new array each time
}

// Method 2: Pre-allocate when size is known
// (More efficient)
array(int) result = allocate(1000);
for (int i = 0; i < 1000; i++) {
    result[i] = i;
}

// Method 3: Use Array.range for sequences
array(int) result = Array.range(0, 1000);
```

:::note
In Pike, arrays are immutable. Operations like `+=` create a new array. For very large arrays, consider using ADT data structures or pre-allocation.
:::

---

## Reversing an Array

### Reversing Arrays

```pike
//-----------------------------
// Recipe: Reverse array order
//-----------------------------

array(string) arr = ({"first", "second", "third", "fourth"});

// Create reversed copy
array(string) reversed = reverse(arr);
write("Reversed: %s\n", (string)reversed);
// Output: ({"fourth", "third", "second", "first"})

// Reverse in-place (modifies original)
arr = reverse(arr);
```

### Practical Examples

```pike
//-----------------------------
// Recipe: Useful reversal patterns
//-----------------------------

// Example 1: Process lines in reverse order
array(string) lines = Stdio.read_file("log.txt") / "\n";
foreach(reverse(lines);; string line) {
    write("%s\n", line);
}

// Example 2: Sort descending
array(string) users = ({"alice", "bob", "charlie", "david"});
array(string) descending = reverse(sort(users));
write("Descending: %s\n", (string)descending);
// Output: ({"david", "charlie", "bob", "alice"})

// Example 3: Reverse with custom comparison
array(string) names = ({"Alice", "bob", "Charlie", "david"});

// Case-insensitive descending sort
array(string) sorted = Array.sort_array(names, lambda(string a, string b) {
    return lower_case(a) > lower_case(b);
});
```

### Iterating in Reverse

```pike
//-----------------------------
// Recipe: Iterate array backwards
//-----------------------------

array(int) numbers = ({1, 2, 3, 4, 5});

// Method 1: foreach with reverse
foreach(reverse(numbers);; int n) {
    write("%d\n", n);
}

// Method 2: Traditional for loop
for (int i = sizeof(numbers) - 1; i >= 0; i--) {
    write("%d\n", numbers[i]);
}
```

---

## Processing Multiple Elements of an Array

### Working with Array Slices

```pike
//-----------------------------
// Recipe: Process array chunks
//-----------------------------

array(int) arr = ({0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
int n = 3;

// Get first n elements
array(int) front = arr[..n-1];
write("Front: %s\n", (string)front);
// Output: ({0, 1, 2})

// Get elements after first n
arr = arr[n..];
write("Rest: %s\n", (string)arr);
// Output: ({3, 4, 5, 6, 7, 8, 9})

// Get last n elements
array(int) back = arr[sizeof(arr)-n..];
write("Back: %s\n", (string)back);
// Output: ({7, 8, 9})

// Remove last n elements
arr = arr[..sizeof(arr)-(n+1)];
write("Remaining: %s\n", (string)arr);
// Output: ({3, 4, 5, 6})
```

### Using ADT for Queue Operations

```pike
//-----------------------------
// Recipe: Efficient queue with ADT.CircularList
//-----------------------------

ADT.CircularList list = ADT.CircularList(({"Peter", "Paul", "Mary", "Jim", "Tim"}));

// Shift2: Remove and return first 2 elements
array shift2(ADT.CircularList list) {
    return ({list->pop_front(), list->pop_front()});
}

array(string) first_two = shift2(list);
write("First two: %s\n", (string)first_two);
// Output: ({"Peter", "Paul"})
// Remaining: ({"Mary", "Jim", "Tim"})

// Pop2: Remove and return last 2 elements
array pop2(ADT.CircularList list) {
    return reverse(({list->pop_back(), list->pop_back()});
}

array(string) last_two = pop2(list);
write("Last two: %s\n", (string)last_two);
// Output: ({"Jim", "Tim"})
// Remaining: ({"Mary"})
```

### Circular List Rotation

```pike
//-----------------------------
// Recipe: Rotate circular list
//-----------------------------

ADT.CircularList processes = ADT.CircularList(({1, 2, 3, 4, 5}));

mixed grab_and_rotate(ADT.CircularList list) {
    mixed element = list->pop_front();
    list->push_back(element);  // Move to end
    return element;
}

// Round-robin processing
while (1) {
    int process = grab_and_rotate(processes);
    write("Handling process %d\n", process);
    sleep(1);
}
```

---

## Finding the First List Element That Passes a Test

### Searching Arrays

```pike
//-----------------------------
// Recipe: Find elements matching criteria
//-----------------------------

array(string) arr = ({"apple", "banana", "cherry", "date", "elderberry"});

// Method 1: Using search() for exact match
int pos = search(arr, "cherry");
if (pos != -1) {
    write("Found at index %d: %s\n", pos, arr[pos]);
}

// Method 2: Using Array.search_array() with predicate
string test(string element) {
    return sizeof(element) == 5;
}

int match_pos = Array.search_array(arr, test);
if (match_pos != -1) {
    write("First 5-letter word: %s\n", arr[match_pos]);
    // Output: "apple"
}

// Method 3: Using filter() to get all matches
array(string) long_words = filter(arr, lambda(string word) {
    return sizeof(word) > 5;
});
write("Long words: %s\n", (string)long_words);
// Output: ({"banana", "cherry", "elderberry"})

// Method 4: Using has_value() for multiset lookup
if (has_value(arr, "date")) {
    write("Found 'date' in array\n");
}
```

### Practical Example: User Lookup

```pike
//-----------------------------
// Recipe: Find user by property
//-----------------------------

array(mapping(string:mixed)) users = ({
    (["name": "Alice", "id": 1, "active": true]),
    (["name": "Bob", "id": 2, "active": false]),
    (["name": "Charlie", "id": 3, "active": true])
});

// Find first active user
mapping(string:mixed)|zero active_user = Array.search_array(
    users,
    lambda(mapping u) { return u->active; }
);

if (active_user) {
    write("Found active user: %s (ID: %d)\n",
          active_user->name, active_user->id);
}
```

---

## Finding All Elements in an Array Matching Certain Criteria

### Filtering Arrays

```pike
//-----------------------------
// Recipe: Filter array by condition
//-----------------------------

array(int) numbers = ({1, 2, 3, 4, 5, 6, 7, 8, 9, 10});

// Method 1: Using filter()
array(int) evens = filter(numbers, lambda(int n) {
    return n % 2 == 0;
});
write("Even numbers: %s\n", (string)evens);
// Output: ({2, 4, 6, 8, 10})

// Method 2: Using map and subtract
array(int) odds = map(numbers, lambda(int n) {
    return n % 2 ? n : 0;
}) - ({0});

// Method 3: Manual iteration
array(int) primes = ({});
foreach(numbers;; int n) {
    if (is_prime(n)) {
        primes += ({n});
    }
}
```

### Complex Filtering

```pike
//-----------------------------
// Recipe: Filter with multiple conditions
//-----------------------------

array(mapping(string:mixed)) products = ({
    (["name": "Laptop", "price": 999, "stock": 5]),
    (["name": "Mouse", "price": 29, "stock": 50]),
    (["name": "Keyboard", "price": 79, "stock": 0]),
    (["name": "Monitor", "price": 299, "stock": 12])
});

// Find affordable, in-stock items
array(mapping) affordable = filter(products, lambda(mapping p) {
    return p->price < 100 && p->stock > 0;
});

write("Affordable items:\n");
foreach(affordable;; mapping item) {
    write("  - %s: $%d (%d in stock)\n",
          item->name, item->price, item->stock);
}
```

---

## Sorting an Array Numerically

### Sorting Numbers

```pike
//-----------------------------
// Recipe: Sort arrays of numbers
//-----------------------------

// Integers and floats are sorted numerically by default
array(int) unsorted = ({42, 7, 13, 99, 1, 23});
array(int) sorted = sort(unsorted);
write("Sorted: %s\n", (string)sorted);
// Output: ({1, 7, 13, 23, 42, 99})

// Note: sort() is destructive - modifies original
array(int) numbers = ({5, 2, 8, 1, 9});
sort(numbers);
write("After sort(): %s\n", (string)numbers);
// Output: ({1, 2, 5, 8, 9})

// To preserve original, copy first
array(int) original = ({5, 2, 8, 1, 9});
array(int) sorted = copy_value(original);
sort(sorted);
```

### Sorting Strings by Numeric Value

```pike
//-----------------------------
// Recipe: Sort strings by embedded numbers
//-----------------------------

array(string) unsorted = ({"123asdf", "3poiu", "23qwert", "3ayxcv"});

// Extract numbers and sort by them
array(int) numeric = map(unsorted, lambda(string s) {
    return (int)array_sscanf(s, "%d")[0];
});

sort(numeric, unsorted);
write("Sorted numerically: %s\n", (string)unsorted);
// Output: ({"3poiu", "3ayxcv", "23qwert", "123asdf"})
```

---

## Sorting a List by Computable Field

### Custom Sorting

```pike
//-----------------------------
// Recipe: Sort by computed field
//-----------------------------

// Method 1: Using Array.sort_array with comparison function
array(mapping) employees = ({
    (["name": "Alice", "salary": 50000, "age": 30]),
    (["name": "Bob", "salary": 60000, "age": 25]),
    (["name": "Charlie", "salary": 45000, "age": 35])
});

// Sort by name
array sorted_by_name = Array.sort_array(
    employees,
    lambda(mapping a, mapping b) {
        return a->name > b->name;
    }
);

// Sort by salary (descending)
array sorted_by_salary = Array.sort_array(
    employees,
    lambda(mapping a, mapping b) {
        return a->salary < b->salary;
    }
);

// Method 2: Pre-compute sort keys (more efficient)
array compute(array items, string field) {
    return map(items, lambda(mapping m) { return m[field]; });
}

array keys = compute(employees, "age");
sort(keys, employees);
write("Sorted by age: %s\n", employees->name * ", ");
```

### Practical Example: Multi-Field Sort

```pike
//-----------------------------
// Recipe: Sort by multiple fields
//-----------------------------

array(mapping) users = ({
    (["name": "Alice", "age": 30]),
    (["name": "Bob", "age": 25]),
    (["name": "Alice", "age": 25]),
    (["name": "Charlie", "age": 30])
});

// Sort by name first, then age
array sorted = Array.sort_array(users, lambda(mapping a, mapping b) {
    if (a->name != b->name)
        return a->name > b->name;
    return a->age < b->age;  // If names equal, sort by age
});
```

---

## Implementing a Circular List

### Using ADT.CircularList

```pike
//-----------------------------
// Recipe: Rotate through elements
//-----------------------------

ADT.CircularList circular = ADT.CircularList(({"a", "b", "c", "d"}));

// Rotate: move first element to end
circular->push_back(circular->pop_front());

// Rotate: move last element to front
circular->push_front(circular->pop_back());

// Round-robin processing
mixed grab_and_rotate(ADT.CircularList list) {
    mixed element = list->pop_front();
    list->push_back(element);  // Move to back of queue
    return element;
}

ADT.CircularList processes = ADT.CircularList(({1, 2, 3, 4, 5}));
while (1) {
    int process = grab_and_rotate(processes);
    write("Handling process %d\n", process);
    sleep(1);
}
```

:::tip
Use `ADT.CircularList` for round-robin scheduling, buffer management, or any scenario where you need to cycle through elements.
:::

---

## Randomizing an Array

### Shuffling Arrays

```pike
//-----------------------------
// Recipe: Randomize array order
//-----------------------------

// Method 1: Using Array.shuffle() (Fisher-Yates)
array(int) cards = Array.range(1, 53);  // Deck of cards
Array.shuffle(cards);
write("Shuffled: %s\n", (string)cards[0..5]);

// Method 2: Manual shuffle (for learning)
void naive_shuffle(array list) {
    for (int i = 0; i < sizeof(list); i++) {
        int j = random(sizeof(list));
        [list[i], list[j]] = ({list[j], list[i]});
    }
}

// Method 3: Using multiset
array set_shuffle(array list) {
    multiset elements = (multiset)list;
    array result = ({});

    while (sizeof(elements)) {
        mixed pick = random(elements);
        result += ({pick});
        elements[pick]--;
    }

    return result;
}
```

---

## Program: Words

### Columnated Output

```pike
#!/usr/bin/env pike
#pragma strict_types

// words - gather lines, present in columns

int main() {
    // Read all input
    array(string) words = Stdio.stdin.read() / "\n";

    // Find maximum word length
    int maxlen = sort(sizeof(words[*]))[-1];
    maxlen++;

    // Calculate columns based on terminal width
    int cols = Stdio.stdout->tcgetattr()->columns / maxlen;
    int rows = (sizeof(words) / cols) + 1;

    // Create format string
    string mask = "%{%-" + maxlen + "s%}\n";

    // Transpose and display
    words = Array.transpose(words / rows);
    write(mask, words[*]);

    return 0;
}
```

---

## Program: Permute

### Generate Permutations

```pike
#!/usr/bin/env pike
#pragma strict_types

// permute - generate all permutations of input

int factorial(int n) {
    int s = 1;
    while (n) s *= n--;
    return s;
}

void permute(array items, array|void perms) {
    if (!perms) perms = ({});
    if (!sizeof(items)) {
        write("%s\n", perms * " ");
    } else {
        foreach(items; int i;) {
            array newitems = items[..i-1] + items[i+1..];
            array newperms = items[i..i] + perms;
            permute(newitems, newperms);
        }
    }
}

int main() {
    string line;
    while (line = Stdio.stdin->gets()) {
        permute(line / " ");
    }
    return 0;
}
```

---

## See Also

- [Hashes](/docs/basics/hashes) - Key-value data structures
- [Strings](/docs/basics/strings) - Text processing
- [Pattern Matching](/docs/basics/pattern-matching) - Finding patterns in data
- [Subroutines](/docs/basics/subroutines) - Functions and lambdas


## Specifying a List In Your Program

```pike
// list
array(string) a = ({ "quick", "brown", "fox" });
// words
array(string) a = "Why are you teasing me?"/" ";
// lines
array(string) lines = #"The boy stood on the burning deck,
It was as hot as glass."/"\n";
// file
array(string) bigarray = Stdio.read_file("mydatafile")/"\n";
// the quoting issues do not apply.
array(string) ships = "Niña Pinta Santa María"/" ";         // wrong
array(string) ships = ({ "Niña", "Pinta", "Santa María" }); // right
```


## Printing a List with Commas

```pike
// download the following standalone program
#!/usr/bin/pike
// chapter 4.2
// commify_series - show proper comma insertion in list output
array(array(string)) lists =
({
({ "just one thing" }),
({ "Mutt", "Jeff" }),
({ "Peter", "Paul", "Mary" }),
({ "To our parents", "Mother Theresa", "God" }),
({ "pastrami", "ham and cheese", "peanut butter and jelly", "tuna" }),
({ "recycle tired, old phrases", "ponder big, happy thoughts" }),
({ "recycle tired, old phrases",
"ponder big, happy thoughts",
"sleep and dream peacefully" }),
});
void main()
{
write("The list is: %s.\n", commify_list(lists[*])[*]);
}
string commify_list(array(string) list)
{
switch(sizeof(list))
{
case 1: return list[0];
case 2: return sprintf("%s and %s", @list);
default:
string seperator=",";
int count;
while(count<sizeof(list) && search(list[count], seperator)==-1)
count++;
if(count<sizeof(list))
seperator=";";
return sprintf("%{%s"+seperator+" %}and %s",
list[..sizeof(list)-2], list[-1]);
}
}
```


## Changing Array Size

```pike
void what_about_that_array(array list)
{
write("The array now has %d elements.\n", sizeof(list));
write("The index of the last element is %d.\n", sizeof(list)-1);
write("Element #3 is %O.\n", list[3]);
}
array people = ({ "Crosby", "Stills", "Nash", "Young" });
what_about_that_array(people);
// The array now has 4 elements.
// The index of the last element is 3.
// Element #3 is "Young".
people=people[..sizeof(people)-2];
what_about_that_array(people);
// The array now has 3 elements.
// The index of the last element is 2.
// Index 3 is out of array range -3..2.
people+=allocate(10001-sizeof(people));
what_about_that_array(people);
// The array now has 10001 elements.
// The index of the last element is 10000.
// Element #3 is 0.
array people = ({ "Crosby", "Stills", "Nash", "Young" }); // resetting the array
people[10000]=0;
// Index 10000 is out of array range -4..3.
// accessing a nonexisting index is always an error.
// arrays can not be enlarged this way.
```


## Doing Something with Every Element in a List

```pike
foreach(list; int index; mixed item)
{
// do something with item (and possibly index)
}
foreach(bad_users;; object user)
{
complain(user);
}
// for such simple cases pike provides a convenient automap feature:
complain(bad_users[*]);
// will do the same as the foreach above.
foreach(sort(indices(getenv()));; string var)
{
write("%s=%s\n", var, getenv(var));
}
// if you don't need an assurance that the indices are sorted (they most likely
// are sorted anyways) you may use:
foreach(getenv(); string var; string value)
{
write("%s=%s\n", var, value);
}
foreach(all_users;; string user)
{
int disk_space = get_usage(user);
if(disk_space > MAX_QUOTA)
complain(user);
}
// continue; to jump to the next
// break; to stop the loop
// redo can be done by doing a loop with the proper checks in the block
object pipe=Stdio.File();
Process.create_process(({ "who" }), ([ "stdout":pipe->pipe() ]));
foreach(pipe->line_iterator();; string line)
{
if(search(line, "tchrist")>-1)
write(line+"\n");
}
object fh=Stdio.File("somefile");
foreach(fh->line_iterator(); int linenr; string line)
{
foreach(Process.split_quoted_string(line);; string word)//split on whitespace
{
write(reverse(word));
}
}
array(int) list = ({ 1,2,3 });
foreach(list;; int item)
{
item--;
}
write("%{%d %}\n", list);
// Result: 1 2 3
// we can still use foreach instead of for,
// because foreach gives us the index as well:
foreach(list; int index;)
{
list[index]--;
}
write("%{%d %}\n", list);
// Result: 0 1 2
array a = ({ 0.5, 3 });
array b = ({ 0, 1 });
// foreach handles only one array so there is nothing to gain here.
// better use automap:
array a_ = a[*]*7;
array b_ = b[*]*7;
write("%{%O %}\n", a_+b_);
// 3.500000 21 0 7
string scalar = " abc ";
array(string) list = ({ " a ", " b " });
mapping(mixed:string) hash = ([ "a":" a ", "b":" b " ]);
scalar = String.trim_whites(scalar);
list = String.trim_whites(list[*]);
foreach(hash; int key;)
{
hash[key]=String.trim_whites(hash[key]);
}
```


## Iterating Over an Array by Reference

```pike
// pike does not distinguish between arrays and array references
// (they are all references anyways) so this section does not apply
```


## Extracting Unique Elements from a List

```pike
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
if(!seen[item])
seen[item] = 1;
else
uniq += ({ item });
}
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
if(!seen[item]++)
uniq += ({ item });
}
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
if(!seen[item]++)
some_func(item);
}
// the following is probably the most natural for pike
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
seen[item]++;
}
uniq = indices(seen);
// not necessarily faster but shorter:
array uniq = indices(({ list[*],1 }));
// also short, and preserving the originaal order:
array uniq = list&indices(({ list[*],1 }));
object pipe = Stdio.File();
Process.create_process(({ "who" }), ([ "stdout":pipe->pipe() ]));
mapping ucnt = ([]);
foreach(pipe->line_iterator();; string line)
{
ucnt[(line/" ")[0]]++;
}
array users = sort(indices(ucnt));
write("users logged in: %s\n", users*" ");
```


## Finding Elements in One Array but Not Another

```pike
// one of pikes strenghts are operators.
// the following are the only idiomatic solutions to the problem
array A = ({ 1, 2, 3 });
array B = ({ 2, 3, 4 });
array aonly = A-B;
// Result: ({ 1 });
```


## Computing Union, Intersection, or Difference of Unique Lists

```pike
array a = ({ 1, 3, 5, 6, 7, 8 });
array b = ({ 2, 3, 5, 7, 9 });
// union:
array union = a|b;
// ({ 1, 3, 5, 6, 7, 8, 2, 9 })
// intersection
array intersection = a&b;
// ({ 3, 5, 7 })
// difference
array difference = a-b;
// ({ 1, 6, 8 })
// symetric difference
array symdiff= a^b;
// ({ 1, 6, 8, 2, 9 })
```


## Appending One Array to Another

```pike
// join arrays
// appending to an array will always create a new array and pike is designed to
// handle this efficiently.
array members = ({ "Time", "Flies" });
array initiates = ({ "An", "Arrow" });
members += initiates;
// members is now ({ "Time", "Flies", "An", "Arrow" })
members = members[..1]+({ "Like" })+members[2..];
write("%s\n", members*" ");
members[0] = "Fruit";
members = members[..sizeof(members)-3]+({ "A", "Banana" });
write("%s\n", members*" ");
// Time Flies Like An Arrow
// Fruit Flies Like A Banana
```


## Reversing an Array

```pike
// almost any operation you do on the elements will add more overhead than
// reversing the array, if there is any possible optimization, pike will do it
// for you.
array reversed = reverse(arr);
// unless you were going to use for anyways then foreach(reverse( ...)) is
// preferable.
foreach(reverse(arr);; mixed item)
{
// do something with item
}
for(int i=sizeof(arr)-1; i<=0; i--)
{
// so something with arr[i]
}
array ascending = sort(users);
array descending = reverse(sort(users));
// reverse(sort()) is faster by a magnitude
array descending = Array.sort_array(users, lambda(mixed a, mixed b)
{
return a<b;
}
);
```


## Processing Multiple Elements of an Array

```pike
array arr = ({ 0,1,2,3,4,5,6,7,8,9 });
int n=3;
array front = arr[..n-1];
arr = arr[n..];
array back = arr[sizeof(arr)-n..];
arr = arr[..sizeof(arr)-(n+1)];
// since new arrays are created if elements are added or removed
// shift and pop are not usefull here.
// if you need shift and pop capabilities use the ADT classes:
array shift2(ADT.Queue queue)
{
return ({ queue->read(), queue->read() });
}
ADT.Queue friends = ADT.Queue("Peter", "Paul", "Mary", "Jim", "Tim");
string this, that;
[this, that] = shift2(friends);
// this contains Peter, that has Paul, and
// friends has Mary, Jim, and Tim
ADT.Stack beverages = ADT.Stack();
beverages->set_stack(({ "Dew", "Jolt", "Cola", "Sprite", "Fresca" }));
array pair = beverages->pop(2); // implementing pop2 would gain nothing here
// pair[0] contains Sprite, pair[1] has Fresca,
// and beverages has (Dew, Jolt, Cola)
// to be able to shift and pop on the same list use the following:
array shift2(ADT.CircularList list)
{
return ({ list->pop_front(), list->pop_front() });
}
array pop2(ADT.CircularList list)
{
return reverse( ({ list->pop_back(), list->pop_back() }) );
}
ADT.CircularList friends = ADT.CircularList( ({"Peter", "Paul", "Mary", "Jim", "Tim"}) );
string this, that;
[this, that] = shift2(friends);
// this contains Peter, that has Paul, and
// friends has Mary, Jim, and Tim
ADT.CircularList beverages = ADT.CircularList( ({ "Dew", "Jolt", "Cola", "Sprite", "Fresca" }) );
array pair = pop2(beverates);
// pair[0] contains Sprite, pair[1] has Fresca,
// and beverages has (Dew, Jolt, Cola)
```


## Finding the First List Element That Passes a Test

```pike
mixed match = search(arr, element);
int test(mixed element)
{
if(sizeof(element)==5)
return 1;
else
return 0;
}
mixed match = Array.search_array(arr, test);
if(match != -1)
{
// do something with arr[match]
}
else
{
// do something else
}
// another convenient way if you do many tests on the same list,
// and you do not care for the position is:
if( (multiset)arr[element] )
{
// found
}
else
{
// not found
}
```


## Finding All Elements in an Array Matching Certain Criteria

```pike
array matching=({});
foreach(list;; mixed element)
{
if(test(element))
matching+=({ element });
}
array matching = map(list, test)-({ 0 });
array matching = test(list[*])-({ 0 });
// apply test() on each element in list, collect the results, and remove
// results that are 0.
```


## Sorting an Array Numerically

```pike
// since pike has different types for strings and numbers, ints and floats are
// of course sorted numerically
// (sort() is destructive, the original array is changed)
array(int) unsorted = ...;
array(int) sorted = sort(unsorted);
// but suppose you want to sort an array of strings by their numeric value then
// things get a bit more interresting:
array(string) unsorted = ({ "123asdf", "3poiu", "23qwert", "3ayxcv" });
sort((array(int))unsorted, unsorted);
// unsorted is now sorted.
```


## Sorting a List by Computable Field

```pike
array unordered;
int compare(mixed a, mixed b)
{
// return comparison of a and b
}
array ordered = Array.sort_array(unordered, compare);
//-------------------------------------------------------------
int compute(mixed element)
{
// return computation from element
}
array precomputed = map(unordered, compute);
sort(precomputed, unordered); // will destructively sort unordered in the same
array ordered = unordered;    // manner as precomputed.
//-------------------------------------------------------------
sort(map(unordered, compute), unordered); // without a temp variable
sort(compute(unordered[*]), unordered);   // using the automap operator
// both get compiled to the same code
//-------------------------------------------------------------
array ordered = sort(employees, lambda(mixed a, mixed b)
{
return a->name > b->name;
}
);
//-------------------------------------------------------------
foreach(Array.sort_array(employees,
lambda(mixed a, mixed b){ return a->name > b->name; })
;; mixed employee)
{
write("%s earns $%d\n", employee->name, employee->salary);
}
//-------------------------------------------------------------
array ordered_employees =
Array.sort_array(employees,
lambda(mixed a, mixed b){ return a->name > b->name; });
foreach(ordered_employees;; mixed employee)
{
write("%s earns $%d\n", employee->name, employee->salary);
}
mapping bonus;
foreach(ordered_employees;; mixed employee)
{
// you are not supposed to use the social security number as an id
if(bonus[employee->id])
write("%s got a bonus!\n", employee->name);
}
//-------------------------------------------------------------
array sorted = Array.sort_array(employees,
lambda(mixed a, mixed b)
{
if(a->name!=b->name)
return (a->name < b->name)
return (b->age < a->age);
}
);
//-------------------------------------------------------------
array(array) users = System.get_all_users();
sort(users);
// System.get_all_users() returns an array of arrays, with the name as the
// first element in each inner array, sort handles multidimensional arrays, so
// we can skip creating our own sort function.
// if we wanted to sort on something else one could rearrange the array:
array user;
while(user=System.getpwent())
{
users += ({ user[2], user });
}
System.endpwent();
sort(users);  // now we are sorting by uid.
// alternative:
array(array) users = System.get_all_users();
sort(users[*][2], users);
write(users[*][0]*"\n");
write("\n");
//-------------------------------------------------------------
array names;
array sorted = Array.sort_array(names, lambda(mixed a, mixed b)
{
return a[1] < b[1];
}
);
// faster:
sort(names[*][1], names);
sorted=names;
//-------------------------------------------------------------
array strings;
array sorted = Array.sort_array(strings, lambda(mixed a, mixed b)
{
return sizeof(a) < sizeof(b);
}
);
// faster:
sort(sizeof(strings[*]), strings);
sorted=strings;
//-------------------------------------------------------------
array strings;
array temp = map(strings, sizeof);
sort(temp, strings);
array sorted = strings;
//-------------------------------------------------------------
array strings;
sort(map(strings, sizeof), strings);   // pick one
sort(sizeof(strings[*]), strings);
sorted=strings;
//-------------------------------------------------------------
array fields;
array temp = map(fields, array_sscanf, "%*s%d%*s");
sort(temp, fields);
array sorted_fields=fields;
//-------------------------------------------------------------
sort(array_sscanf(fields[*], "%*s%d%*s"), fields);
array sorted_fields=fields;
//-------------------------------------------------------------
array passwd_lines = (Stdio.read_file("/etc/passwd")/"\n")-({""});
array(array) passwd = passwd_lines[*]/":";
int compare(mixed a, mixed b)
{
if(a[3]!=b[3])
return (int)a[3]<(int)b[3];
if(a[2]!=b[2])
return (int)a[2]<(int)b[2];
return a[0]<b[0];
}
array sorted_passwd = Array.sort_array(passwd, compare);
// alternatively the following uses the builtin sort
sort( passwd[*][0], passwd);
sort( ((array(int))passwd[*][2]), passwd);
sort( ((array(int))passwd[*][3]), passwd);
```


## Implementing a Circular List

```pike
ADT.CircularList circular;
circular->push_front(circular->pop_back());
circular->push_back(circular->pop_front());
//-------------------------------------------------------------
mixed grab_and_rotate(ADT.CircularList list)
{
mixed element = list->pop_front();
list->push_back(element);
return element;
}
ADT.CircularList processes = ADT.CircularList( ({ 1, 2, 3, 4, 5 }) );
while(1)
{
int process = grab_and_rotate(processes);
write("Handling process %d\n", process);
sleep(1);
}
```


## Randomizing an Array

```pike
array arr;
Array.shuffle(arr);  // this uses the fisher-yates shuffle
//-------------------------------------------------------------
// being creative with the algorithm, this is not as memory efficient,
// but it shows the utility of multisets.
array set_shuffle(array list)
{
multiset elements=(multiset)list;
list=({});                     // reset the list
while(sizeof(elements))        // while we still have elements left
{
mixed pick=random(elements); // pick a random element
list+=({ pick });            // add it to the new list
elements[pick]--;            // remove the element we picked
}
return list;
}
array list;
list=set_shuffle(list);
//-------------------------------------------------------------
inherit "mjd_permute";
int permutations = factorial(sizeof(list));
array shuffle = list[n2perm(random(permutations)+1, sizeof(list))[*]];
//-------------------------------------------------------------
void naive_shuffle(array list)
{
for(int i=0; i<sizeof(list); i++)
{
int j=random(sizeof(list)-1);
[ list[i], list[j] ] = ({ list[j], list[i] });
}
}
```


## Program: words

```pike
// download the following standalone program
#!/usr/bin/pike
// section 4.18 example 4.2
// words - gather lines, present in columns
void main()
{
array words=Stdio.stdin.read()/"\n";   // get all input
int maxlen=sort(sizeof(words[*]))[-1]; // sort by size and pick the largest
maxlen++;                              // add space
// get boundaries, this should be portable
int cols = Stdio.stdout->tcgetattr()->columns/maxlen;
int rows = (sizeof(words)/cols) + 1;
string mask="%{%-"+maxlen+"s%}\n";     // compute format
words=Array.transpose(words/rows);     // split into groups as large as the
// number of rows and then transpose
write(mask, words[*]);                 // apply mask to each group
}
```


## Program: permute

```pike
int factorial(int n)
{
int s=1;
while(n)
s*=n--;
return s;
}
write("%d\n", factorial(500));
// Using Array.permute() to generate all permutations
// -------------------------------------------------------------
// Example: Generate all permutations of an array using Array.permute()
// Note: Array.permute() returns all possible orderings of array elements
import Array;
// Simple permutation example
array(string) fruits = ({"apple", "banana", "cherry"});
array(array(string)) perms = permute(fruits);
foreach(perms, array(string) p)
{
write("%s\n", p*", ");
}
// Output:
// apple, banana, cherry
// apple, cherry, banana
// banana, apple, cherry
// banana, cherry, apple
// cherry, apple, banana
// cherry, banana, apple
//-------------------------------------------------------------
// download the following standalone program
#!/usr/bin/pike
void main()
{
string line;
while(line=Stdio.stdin->gets())
{
permute(line/" ");
}
}
void permute(array items, array|void perms)
{
if(!perms)
perms=({});
if(!sizeof(items))
write((perms*" ")+"\n");
else
{
foreach(items; int i;)
{
array newitems=items[..i-1]+items[i+1..];
array newperms=items[i..i]+perms;
permute(newitems, newperms);
}
}
}
//-------------------------------------------------------------
// download the following standalone program
#!/usr/bin/pike
mapping fact=([ 1:1 ]);
int factorial(int n)
{
if(!fact[n])
fact[n]=n*factorial(n-1);
return fact[n];
}
array n2pat(int N, int len)
{
int i=1;
array pat=({});
while(i <= len)
{
pat += ({ N%i });
N/=i;
i++;
}
return pat;
}
array pat2perm(array pat)
{
array source=indices(pat);
array perm=({});
while(sizeof(pat))
{
perm += ({ source[pat[-1]] });
source = source[..pat[-1]-1]+source[pat[-1]+1..];
pat=pat[..sizeof(pat)-2];
}
return perm;
}
array n2perm(int N, int len)
{
return pat2perm(n2pat(N, len));
}
void main()
{
array data;
while(data=Stdio.stdin->gets()/" ")
{
int num_permutations = factorial(sizeof(data));
for(int i; i<num_permutations; i++)
{
array permutation = data[n2perm(i, sizeof(data))[*]];
write(permutation*" "+"\n");
}
}
}
```

