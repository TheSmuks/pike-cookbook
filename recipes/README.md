# PLEAC Pike Cookbook - Modern Pike 8 Recipes

This directory contains complete, modern Pike 8 implementations for the PLEAC cookbook.

## Organization

Recipes are organized by chapter:
- `strings/` - String manipulation
- `numbers/` - Numeric operations
- `arrays/` - Array handling
- `hashes/` - Hash/dictionary operations
- `patternmatching/` - Regular expressions
- `fileaccess/` - File system operations
- `filecontents/` - File content processing
- `directories/` - Directory operations
- `subroutines/` - Functions and closures
- `references/` - References and data structures
- `packages/` - Modules and libraries
- `classes/` - Object-oriented programming
- `database/` - Database access
- `process/` - Process management
- `network/` - Network programming
- `cgi/` - Web/CGI programming

Each recipe should be:
1. Complete and runnable
2. Well-commented
3. Following Pike 8 best practices
4. Demonstrate modern idioms
5. Include error handling where appropriate

## Pike 8 Idioms to Use

- Type annotations: `string(0..255)`, `int(0..)`, etc.
- Modern module syntax: `Stdio.File`, `Protocols.HTTP.Query`
- Val.null for SQL NULL values
- String.Buffer for efficient string building
- Array.* and ADT.* for data structures
- Modern async patterns where applicable
