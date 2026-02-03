---
id: autodoc-format
title: AutoDoc Format Guide
sidebar_label: AutoDoc Format
---

# AutoDoc Format Guide

## Introduction

AutoDoc is Pike's built-in documentation system that allows you to write documentation directly in your source code. It's a powerful markup system that extracts documentation comments and converts them into structured XML, which can then be transformed into HTML, PDF, or other formats.

**Why use AutoDoc?**
- Documentation lives alongside your code
- Automatic extraction and generation
- Consistent formatting and structure
- Integrated with Pike's build system
- Supports both C and Pike source files

## Basic Syntax

### Line Orientation

AutoDoc is line-oriented. Long lines can be broken using the `@` character at the end of a line:

```pike
//! @variable thisVariableNameIsSoLong@
//! YouJustCantBelieveIt
```

This will be parsed as:
```pike
//! @variable thisVariableNameIsSoLongYouJustCantBelieveIt
```

### Comment Markers

**For Pike files:**
```pike
//! This is a comment
//! Another line of comment
```

**For C files:**
```c
/*! This is a comment */
/*! Another line of comment */
```

Blank lines within comments create paragraph breaks:

```pike
//! - I love you, said Danny.
//!
//! - You have no right to come here after what you did to
//! my little dog, screamed Penny in despair.
```

## Keyword Types

AutoDoc has four types of keywords:

### 1. Meta Keywords
Must stand alone on one line. These define what is being documented.

```pike
//! @decl int myFunction(int x)
//! @class MyClass
//! @module MyModule
```

### 2. Delimiter Keywords
Start a section inside a block. They end when the next delimiter keyword is found.

```pike
//! @param x
//!   The horizontal coordinate
//! @param y
//!   The vertical coordinate
```

### 3. Block/Endblock Keywords
Open or close a structured block.

```pike
//! @dl
//! @item Item 1
//!   Description 1
//! @item Item 2
//!   Description 2
//! @enddl
```

### 4. Short Markup Keywords
Used inline for formatting text.

```pike
//! This is @i{italic@} and @b{bold@} text.
//! See @ref{function_name@} for more info.
```

## Common Tags

### @param - Document function parameters

```pike
//! Calculate the distance between two points.
//! @param x
//!   The horizontal coordinate
//! @param y
//!   The vertical coordinate
//! @returns
//!   The distance from origin
float distance(int x, int y)
{
    return sqrt(x*x + y*y);
}
```

### @return / @returns - Document return values

```pike
//! @returns
//!   The sum of all elements in the array
//! @throws
//!   DivisionByZeroError if the array is empty
int sum_array(array(int) arr)
{
    if (!sizeof(arr)) {
        error("DivisionByZeroError");
    }
    return Array.sum(arr);
}
```

### @throws - Document exceptions

```pike
//! Open a file and return a file descriptor.
//! @param filename
//!   Path to the file to open
//! @throws
//!   SystemError if file doesn't exist
//! @throws
//!   PermissionError if no read access
int open_file(string filename)
{
    Stdio.File f = Stdio.File();
    if (!f->open(filename, "r")) {
        error("Failed to open file: %s", filename);
    }
    return f->fd();
}
```

### @seealso - Related references

```pike
//! Parse XML data into a Pike object.
//! @seealso
//!   @[Parser.XML.Parser] for parsing XML
//! @seealso
//!   @[encode_xml()] for creating XML
//! @seealso
//!   @[validate_xml()] for validation
mixed parse_xml(string xml_data);
```

### @example - Usage examples

```pike
//! @example
//! // Basic usage
//! mapping config = load_config("config.txt");
//! @example
//! // With default values
//! mapping config = load_config("config.txt",
//!                             (["debug": 0, "verbose": 0]));
mapping load_config(string file, mapping defaults);
```

### @note - Important notes

```pike
//! @note
//!   This function modifies the input array in-place.
//! @note
//!   Make sure to call @[cleanup()] when done processing
void process_array(array data);
```

### @deprecated - Deprecation warnings

```pike
//! @deprecated
//!   Use @[new_function()] instead. This function will be removed
//!   in version 8.1
//! @deprecated
//!   Consider using @[json_encode()] for better performance
string old_function(mixed data);
```

### @bugs - Known issues

```pike
//! @bugs
//!   May crash with very large files (>2GB)
//! @bugs
//!   Race condition possible with concurrent access
//! @bugs
//!   Memory leak when called recursively
void problematic_function();
```

## Code Examples

### Simple Function Documentation

```pike
//! Calculate the factorial of a number.
//! @param n
//!   Non-negative integer to calculate factorial for
//! @returns
//!   Factorial of n
//! @throws
//!   Error if n is negative
int factorial(int n)
{
    if (n < 0) {
        error("Factorial not defined for negative numbers");
    }
    return n <= 1 ? 1 : n * factorial(n-1);
}
```

### Function with Multiple Parameters

```pike
//! Connect to a database and return a connection object.
//! @param host
//!   Database host address
//! @param port
//!   Database port number
//! @param username
//!   Database username
//! @param password
//!   Database password
//! @param database
//!   Database name to connect to
//! @returns
//!   Database connection object
//! @throws
//!   ConnectionError if connection fails
//! @throws
//!   AuthenticationError if credentials are invalid
Sql.Sql connect_to_database(string host, int port,
                           string username, string password,
                           string database)
{
    return Sql.Sql()->set_database(database)
                   ->set_host(host)
                   ->set_port(port)
                   ->set_user(username)
                   ->set_password(password);
}
```

### Class Documentation

```pike
//! A logger class with different severity levels.
//! @note
//!   Log messages are written to stderr by default
//! @seealso
//!   @[FileLogger] for file-based logging
//! @deprecated
//!   Use @[AdvancedLogger] instead
class Logger
{
    //! @param level
    //!   Minimum log level to display (DEBUG, INFO, WARN, ERROR)
    void create(string level) { /* ... */ }

    //! Log a debug message.
    //! @param message
    //!   Debug message to log
    void debug(string message) { /* ... */ }

    //! Log an error message.
    //! @param message
    //!   Error message to log
    //! @param error
    //!   Error object (optional)
    void error(string message, mixed|void error) { /* ... */ }
}
```

### Module Documentation

```pike
//! Image processing utilities for Pike.
//!
//! This module provides functions for loading, manipulating, and saving
//! various image formats including PNG, JPEG, and GIF.
//!
//! @example
//! // Load and resize an image
//! Stdio.Image img = Image.load("input.jpg");
//! img = Image.resize(img, 800, 600);
//! Image.save(img, "output.png");
//!
//! @note
//!   Image formats support varies by system
//! @bugs
//!   Some transparency modes not supported in JPEG
//! @seealso
//!   @[Image.load()], @[Image.save()], @[Image.resize()]
//! @deprecated
//!   Use the new Graphics.Image module for better performance
//!
//! @module Image
```

## Best Practices

### Style Guidelines

1. **Consistent Formatting**: Use consistent indentation and spacing
2. **Complete Sentences**: Write complete sentences for descriptions
3. **Parameter Order**: Document parameters in the same order they appear
4. **Return Value**: Always document what the function returns
5. **Error Handling**: Document all possible exceptions

### Grouping Related Parameters

```pike
//! @param x
//! @param y
//!   The coordinates of the point
//! @param z
//!   The z-coordinate (optional, defaults to 0)
```

### Using @decl for Multiple Functions

```pike
//! @decl float circle_area(float radius)
//! @decl float circle_circumference(float radius)
//! @returns
//!   For circle_area(): Area of the circle
//!   For circle_circumference(): Circumference of the circle
//! @param radius
//!   Radius of the circle
```

### Proper Paragraph Breaks

```pike
//! This is the first paragraph of the description.
//! It explains the main purpose of the function.
//!
//! This is the second paragraph. It provides additional
//! context or usage notes that don't fit in the first paragraph.
//! @param x
//!   Parameter documentation here
```

## Quick Reference

### Meta Keywords
| Keyword | Description | Usage |
|---------|------------|-------|
| `@decl` | Declare function/variable | `@decl function_name(type)` |
| `@class` | Start class documentation | `@class Classname` |
| `@endclass` | End class documentation | `@endclass Classname` |
| `@module` | Start module documentation | `@module ModuleName` |
| `@endmodule` | End module documentation | `@endmodule ModuleName` |

### Common Tags
| Tag | Description | Example |
|-----|-------------|---------|
| `@param` | Document parameters | `@param name Description` |
| `@return` | Document return value | `@returns Description` |
| `@throws` | Document exceptions | `@throws Exception Description` |
| `@seealso` | Related references | `@seealso other_func` |
| `@example` | Usage examples | `@example // code` |
| `@note` | Important notes | `@note Important note` |
| `@deprecated` | Deprecation warnings | `@deprecated Use new_func` |
| `@bugs` | Known issues | `@bugs Issue description` |

### Short Markup Keywords
| Keyword | Description | Example |
|---------|-------------|---------|
| `@i{...@}` | Italic text | `@i{italic@}` |
| `@b{...@}` | Bold text | `@b{bold@}` |
| `@tt{...@}` | Teletype/monospace | `@tt{code@}` |
| `@ref{...@}` | Reference to Pike entity | `@ref{function@}` |
| `@xml{...@}` | Raw XML content | `@xml{<br/>@}` |

### Block Keywords
| Keyword | Description | Example |
|---------|-------------|---------|
| `@dl` / `@enddl` | Description list | `@dl @item ... @enddl` |
| `@mapping` / `@endmapping` | Mapping documentation | `@mapping @member ... @endmapping` |
| `@array` / `@endarray` | Array documentation | `@array @item ... @endarray` |

## Conclusion

AutoDoc is a powerful documentation system that keeps your documentation close to your code. By following these guidelines and using the provided examples, you can create comprehensive and maintainable documentation for your Pike projects.

Remember: Good documentation saves time and reduces confusion for both yourself and other developers who work with your code.