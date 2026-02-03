---
sidebar_position: 1
---

# String Manipulation

Learn how to work with strings in Pike, from basic operations to advanced text processing.

## Basic String Operations

### Creating Strings

```pike
// String literals
string str1 = "Hello, World!";
string str2 = "Pike"; // Can use double quotes
string str3 = 'Single quotes also work';

// Multiline strings
string multiline = #"
This is a
multiline string
in Pike
";
```

### String Concatenation

```pike
string first = "Hello";
string last = "World";

// Using + operator
string result = first + ", " + last + "!"; // "Hello, World!"

// Using sprintf for formatted strings
string formatted = sprintf("%s, %s!", first, last);
```

### String Length

```pike
string text = "Pike Programming";
int length = sizeof(text); // 18
```

## String Searching and Matching

### Finding Substrings

```pike
string text = "The quick brown fox";

// Check if substring exists
if (has_value(text, "quick")) {
    write("Found 'quick' in the text\n");
}

// Find position
int pos = search(text, "brown"); // Returns 10
```

### Replacing Substrings

```pike
string text = "Hello, World!";
string replaced = replace(text, "World", "Pike");
// Result: "Hello, Pike!"
```

## String Case Conversion

```pike
string text = "Pike Programming";

// Convert to uppercase
string upper = upper_case(text); // "PIKE PROGRAMMING"

// Convert to lowercase
string lower = lower_case(text); // "pike programming"

// Capitalize first letter
string capitalized = String.capitalize(text); // "Pike programming"
```

## Splitting and Joining Strings

```pike
string text = "apple,banana,cherry";

// Split by delimiter
array parts = text / ","; // ({"apple", "banana", "cherry"})

// Join array into string
array fruits = ({"apple", "banana", "cherry"});
string joined = fruits * ", "; // "apple, banana, cherry"
```

## Best Practices

1. **Use sizeof() for length**: Always use `sizeof(string)` instead of manual length functions
2. **Prevent SQL injection**: Use parameterized queries when building database queries
3. **Normalize case**: When comparing strings case-insensitively, use `lower_case()` on both
4. **Avoid excessive concatenation**: Use `sprintf()` for complex string building

## Related Recipes

- [Array Operations](/docs/basics/arrays) - Working with Pike arrays
- [Mapping Operations](/docs/basics/mapping) - Key-value data structures
