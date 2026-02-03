# Pike Cookbook

[![Documentation Status](https://img.shields.io/badge/docs-latest-blue)](https://thesmuks.github.io/pike-cookbook/)
[![Build Status](https://img.shields.io/github/actions/workflow/status/TheSmuks/pike-cookbook/deploy.yml?branch=main)](https://github.com/TheSmuks/pike-cookbook/actions)
[![License](https://img.shields.io/badge/license-ISC-blue)](LICENSE)

Complete Pike 8.0 programming cookbook with practical recipes, examples, and best practices.

## About

This cookbook provides practical solutions for common programming tasks in Pike 8, a dynamic programming language with a syntax similar to C and C++. Each recipe includes working code examples, explanations, and cross-references to related topics.

**View the full documentation:** [https://thesmuks.github.io/pike-cookbook/](https://thesmuks.github.io/pike-cookbook/)

## Topics Covered

### Basics
- Arrays and mappings
- String manipulation and processing
- Numbers and math operations
- Control flow and iteration
- Functions and lambdas

### File Operations
- Reading and writing files
- Directory traversal and manipulation
- File system monitoring
- Path handling and operations

### Network Programming
- TCP/UDP sockets
- HTTP clients and REST APIs
- CGI programming
- DNS, FTP, and email protocols

### Advanced Topics
- Object-oriented programming with classes
- Process management and IPC
- Module system and organization
- User interfaces (terminal and GUI)
- Concurrency and threading

## Quick Start

```pike
// Simple HTTP GET request
import Protocols.HTTP;

string url = "https://api.example.com/data";
Protocols.HTTP.Query query = Protocols.HTTP.get_url(url);

if (query->status == 200) {
    write("Response: %s\n", query->data());
} else {
    werror("Request failed: %d\n", query->status);
}
```

## Documentation Structure

- **Intro** - Getting started with Pike
- **Basics** - Fundamental language features
- **Files** - File and directory operations
- **Network** - Network and web programming
- **Advanced** - OOP, processes, modules

## Development

```bash
# Install dependencies
bun install

# Start development server
bun start

# Build for production
bun run build

# Serve production build
bun run serve
```

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

All contributors must sign the Contributor License Agreement (CLA) before their pull requests can be merged.

## License

ISC License - see [LICENSE](LICENSE) for details.

## Resources

- [Pike Homepage](https://pike.lysator.liu.se/)
- [Pike Reference Manual](https://pike.lysator.liu.se/docs/)
- [Pike GitHub](https://github.com/pikelang/Pike)
