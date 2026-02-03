---
id: modules
title: Modules and Packages
sidebar_label: Modules and Packages
---

# Modules and Packages

## Introduction

**What this covers**
- Creating and organizing Pike 8 modules with `.pmod` files
- Hierarchical module structures and namespaces
- AutoDoc documentation system with `//!` comments
- Dynamic module loading with `master()->resolv()`
- Public vs private module symbols and visibility control
- Standard library modules (ADT, Sql, Protocols, Parser)

**Why use it**
Modules are the foundation of code organization in Pike 8. They allow you to create reusable libraries, manage namespace conflicts, and build maintainable applications through proper separation of concerns. Pike's module system provides both compile-time safety with `#pragma strict_types` and runtime flexibility with dynamic loading.

:::tip Key Concept
Pike modules are stored in files with the `.pmod` extension. They can contain functions, classes, constants, and even nested submodules. Use `import` to bring symbols into scope, or access modules directly via their fully qualified names.
:::

```pike
// Importing standard modules
import Array; // Import Array module
import ADT; // Import ADT module (Abstract Data Types)
import ADT.Struct; // Import specific submodule
import Sql.sql; // Import SQL interface

// Using imported functions
array arr = Array.shuffle(({1, 2, 3, 4, 5}));
mapping m = ADT.Struct.map(...);

// Qualified access without import
array arr2 = Array.uniq(({1, 2, 2, 3}));
object table = ADT.Table.table(...);
```

---

## Defining a Module's Interface

Creating modules in Pike 8 involves defining `.pmod` files with clear public interfaces. Use `//!` AutoDoc comments to document your interface.

```pike
//-----------------------------
// Recipe: Create a simple utility module
//-----------------------------
// File: MathTools.pmod
//! Mathematical utility functions.
//! This module provides common mathematical operations
//! beyond the built-in arithmetic functions.

#pragma strict_types
#require constant(Constants.VERSION)

// Public constants
constant PI = 3.141592653589793;
constant E = 2.718281828459045;
constant VERSION = "1.0.0";

//! Calculate the factorial of a number.
//! @param n
//! Non-negative integer to calculate factorial for
//! @returns
//! Factorial of n (n!)
//! @throws
//! Error if n is negative or not an integer
int(0..) factorial(int(0..) n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

//! Calculate greatest common divisor using Euclidean algorithm.
//! @param a
//! First positive integer
//! @param b
//! Second positive integer
//! @returns
//! Greatest common divisor of a and b
int(1..) gcd(int(1..) a, int(1..) b) {
    while (b != 0) {
        int temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

//! Check if a number is prime.
//! @param n
//! Integer to check for primality
//! @returns
//! True if n is prime, false otherwise
bool is_prime(int n) {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;

    for (int i = 3; i * i <= n; i += 2) {
        if (n % i == 0) return false;
    }
    return true;
}
```

Using the Module:

```pike
//-----------------------------
// Recipe: Import and use a custom module
//-----------------------------
// File: test_math.pike
#pragma strict_types

import MathTools;

int main() {
    write("5! = %d\n", factorial(5));        // 120
    write("GCD(48, 18) = %d\n", gcd(48, 18)); // 6
    write("is_prime(17) = %s\n", is_prime(17) ? "true" : "false");
    write("PI = %.10f\n", PI);

    return 0;
}
```

:::note
Always use `#pragma strict_types` at the top of your module files. This enables Pike's type system to catch errors at compile time rather than runtime, making your code more reliable and easier to debug.
:::

---

## Creating Hierarchical Modules

Pike 8 supports nested module hierarchies using directories and submodules. Organize related functionality into logical groups.

```pike
//-----------------------------
// Recipe: Build a nested module structure
//-----------------------------

// Directory structure:
// MyApp/
//   MyApp.pmod
//   Utils.pmod/
//     String.pmod
//     Math.pmod
//   Database/
//     Connection.pmod
//     Query.pmod

// File: MyApp.pmod
#pragma strict_types

//! Main application module.
constant VERSION = "2.0.0";

// This makes Utils and Database available as MyApp.Utils and MyApp.Database
import .Utils;
import .Database;
```

```pike
// File: MyApp/Utils/String.pmod
#pragma strict_types

//! String manipulation utilities.

//! Convert string to title case.
string title_case(string s) {
    return String.capitalize(lower_case(s));
}

//! Truncate string to maximum length with ellipsis.
string truncate(string s, int max_len) {
    if (sizeof(s) <= max_len) return s;
    return s[0..max_len-3] + "...";
}
```

```pike
//-----------------------------
// Recipe: Use hierarchical modules
//-----------------------------
#pragma strict_types

import MyApp.Utils.String;
import MyApp.Database.Connection;

int main() {
    string title = title_case("hello world");
    write("%s\n", title);  // "Hello World"

    // Or use fully qualified names
    string text = MyApp.Utils.String.truncate("This is a very long string", 10);

    return 0;
}
```

:::tip
Organize modules by feature, not by type. For example, put all user-related functionality (models, validators, handlers) in a `User` submodule rather than separating models, handlers, and validators into different top-level modules.
:::

---

## Dynamic Module Loading with master()->resolv()

Pike's master object provides dynamic module resolution through `master()->resolv()`. This allows loading modules at runtime based on string names.

```pike
//-----------------------------
// Recipe: Load modules dynamically at runtime
//-----------------------------
#pragma strict_types

//! Load a module dynamically by name.
//! @param module_name
//! Name of module to load (e.g., "ADT.Struct")
//! @returns
//! The loaded module or 0 if not found
mixed load_module(string module_name) {
    mixed module = master()->resolv(module_name);

    if (!module) {
        werror("Warning: Module '%s' not found\n", module_name);
    }

    return module;
}

//! Call a function from a dynamically loaded module.
mixed call_module_func(string module_name, string func_name, mixed... args) {
    mixed module = load_module(module_name);

    if (!module) {
        return 0;
    }

    if (!has_prefix(func_name, "_") && has_value(indices(module), func_name)) {
        return module[func_name](@args);
    }

    return 0;
}

int main() {
    // Load Array module dynamically
    object array_mod = load_module("Array");
    if (array_mod) {
        array result = Array.uniq(({1, 2, 2, 3, 3, 3}));
        write("Uniq: %{%d, %}\n", result);
    }

    // Call function dynamically
    mixed result = call_module_func("Array", "shuffle", ({1, 2, 3, 4, 5}));
    if (result) {
        write("Shuffled: %{%d, %}\n", result);
    }

    // Load from nested module
    object struct_mod = load_module("ADT.Struct");
    if (struct_mod) {
        write("ADT.Struct loaded successfully\n");
    }

    return 0;
}
```

:::warning
Dynamic module loading is powerful but bypasses compile-time checking. Use it sparingly and always check the return value. For most cases, static imports (`import Module`) are preferable as they catch errors at compile time.
:::

---

## Making Variables Private to a Module

Pike 8 uses lexical scoping and naming conventions to control visibility. Variables starting with underscore (`_`) are conventionally private.

```pike
//-----------------------------
// Recipe: Use protected for module privacy
//-----------------------------
// File: Auth.pmod
#pragma strict_types

// Private constants (convention: underscore prefix)
protected constant _MAX_ATTEMPTS = 3;
protected constant _TOKEN_EXPIRY = 3600;  // seconds

// Private variables (use protected for module-level privacy)
protected mapping(string:int) _login_attempts = ([]);

//! Public: Check authentication credentials.
bool authenticate(string username, string password) {
    if (_is_locked_out(username)) {
        werror("Account locked: %s\n", username);
        return false;
    }

    bool success = _verify_password(username, password);

    if (success) {
        _login_attempts[username] = 0;
    } else {
        _login_attempts[username]++;
    }

    return success;
}

// Private helper function
protected bool _is_locked_out(string username) {
    return _login_attempts[username] >= _MAX_ATTEMPTS;
}

// Private helper function
protected bool _verify_password(string username, string password) {
    // In real implementation, check against database
    return password != "password123";  // Simplified
}
```

Using Private Module Members:

```pike
#pragma strict_types

import Auth;

int main() {
    // Public function - works fine
    bool result = authenticate("alice", "secret");
    write("Auth: %s\n", result ? "Success" : "Failed");

    // Private members - not accessible
    // int x = Auth._MAX_ATTEMPTS;     // Error: protected
    // bool y = Auth._is_locked_out(); // Error: protected

    return 0;
}
```

:::tip
Use the `protected` modifier for module-level privacy. This prevents symbols from being accessed outside the module while still allowing them to be used within the module and its subclasses.
:::

---

## Controlling Module Symbol Visibility

Use `#require` to enforce module dependencies and control which symbols are exported. This is Pike 8's modern approach to module interfaces.

```pike
//-----------------------------
// Recipe: Define explicit module interfaces
//-----------------------------
// File: SecureConfig.pmod
#pragma strict_types

// Exported symbols - these define the public interface
public constant API_VERSION = "3.0";
public constant MAX_CONNECTIONS = 100;

//! Get configuration value.
public mixed get(string key) {
    return _config[key];
}

//! Set configuration value.
public void set(string key, mixed value) {
    _config[key] = value;
}

// Internal storage - not exported
protected mapping(string:mixed) _config = ([]);

// Private helper - not exported
protected void _load_defaults() {
    _config = ([
        "host": "localhost",
        "port": 8080,
        "debug": false,
    ]);
}

// Initialize defaults when module loads
_load_defaults();
```

```pike
//-----------------------------
// Recipe: Enforce module dependencies
//-----------------------------
// File: Database.pmod
#pragma strict_types

// Compile error if Sql.sql is not available
#require constant(Sql.sql)

// Compile error if ADT.Struct.Table is not available
#inherit ADT.Struct.Table:Table;

//! Database connection wrapper.
class Connection {
    inherit Sql.sql:sql;

    protected string _dsn;

    void create(string dsn) {
        _dsn = dsn;
        ::create(dsn);
    }

    // Additional wrapper methods here
}
```

:::note
The `#require` directive causes a compile-time error if the specified constant or module is not available. This is useful for ensuring that required dependencies are present before the code runs.
:::

---

## AutoDoc Documentation System

Pike 8 uses `//!` comments for AutoDoc documentation. Generate HTML docs with `pike -x extract_autodoc`.

```pike
//-----------------------------
// Recipe: Document modules with AutoDoc
//-----------------------------
// File: StringUtils.pmod
#pragma strict_types

//! String processing utilities for data validation and formatting.
//! @seealso
//!   @url{https://pike.lysator.liu.se/docs/refdoc/predef_3A_3A/String.html@}
//! @module
//!   This module provides high-level string operations for common tasks
//!   like email validation, slug generation, and text formatting.

//! Validate email address format.
//! @param email
//! Email address to validate
//! @returns
//! true if email appears valid, false otherwise
//! @example
//! // Validate an email address
//! if (StringUtils.is_valid_email("user@example.com")) {
//!     write("Valid email\n");
//! }
//! @note
//! This only checks format, not deliverability.
bool is_valid_email(string email) {
    return Regexp.Psimple("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$")->match(email);
}

//! Convert string to URL-friendly slug.
//! @param text
//! Text to convert
//! @param maxlen
//! Maximum length of slug (default: 50)
//! @returns
//! URL-safe slug string
//! @example
//! string slug = StringUtils.make_slug("Hello World!");
//! // Result: "hello-world"
string make_slug(string text, int(1..) maxlen=50) {
    string slug = lower_case(text);

    // Replace non-alphanumeric with hyphens
    slug = Regexp.replace("[^a-z0-9]+", slug, "-");

    // Remove leading/trailing hyphens
    slug = String.trim_all_whites(slug);
    slug = trim(slug, "-");

    // Truncate if too long
    if (sizeof(slug) > maxlen) {
        slug = slug[0..maxlen-1];
    }

    return slug;
}
```

:::tip
AutoDoc comments use `//!` instead of `//`. Always document public functions, classes, and constants with `//!` comments. Use `@param`, `@returns`, `@example`, `@throws`, and `@note` tags for comprehensive documentation.
:::

---

## Pike 8 Standard Library Modules

Pike 8 includes a comprehensive standard library. Here are the most commonly used modules:

### ADT (Abstract Data Types)

```pike
//-----------------------------
// Recipe: Use ADT for structured data
//-----------------------------
#pragma strict_types

import ADT; // Import all ADT submodules

int main() {
    // ADT.Struct - Define structured data types
    struct Person {
        string name;
        int age;
        string email;
    };

    Person p = Person("Alice", 30, "alice@example.com");
    write("Person: %s, age %d\n", p->name, p->age);

    // ADT.Table - Spreadsheet-like data structure
    object table = ADT.Table.table((
        ({"Name", "Age", "City"}),
        ({"Alice", 30, "NYC"}),
        ({"Bob", 25, "LA"}),
    ));

    write("Table rows: %d\n", table->num_rows());

    // ADT.Heap - Priority queue
    object heap = ADT.Heap.priorities();
    heap->push("low", 1);
    heap->push("high", 10);
    write("Heap pop: %s\n", heap->pop());  // "high"

    // ADT.Set - Mathematical set operations
    object set = ADT.Set();
    set->add("apple");
    set->add("banana");
    set->add("apple");  // Duplicate ignored

    write("Set contains: %{%s, %}\n", set->cast("array"));

    return 0;
}
```

### Sql Module - Database Connectivity

```pike
//-----------------------------
// Recipe: Connect to SQL databases
//-----------------------------
#pragma strict_types

import Sql.sql;

int main() {
    // SQLite connection (embedded database)
    object db = Sql.sql("sqlite://test.db");

    // Create table
    db->query("CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE
    )");

    // Insert data (using parameter binding for security)
    db->query("INSERT INTO users (name, email) VALUES (%s, %s)",
              "Alice", "alice@example.com");

    // Query data
    object result = db->query("SELECT * FROM users");

    // Iterate through results
    foreach (result; int i; mapping row) {
        write("User %d: %s (%s)\n",
               row->id, row->name, row->email);
    }

    // Transaction handling
    mixed error = catch {
        db->query("BEGIN");
        db->query("INSERT INTO users (name, email) VALUES (%s, %s)",
                  "Bob", "bob@example.com");
        db->query("COMMIT");
    };

    if (error) {
        db->query("ROLLBACK");
        werror("Transaction failed: %s\n", describe_error(error));
    }

    return 0;
}
```

:::warning
Always use parameter binding (`%s` placeholders) instead of string concatenation for SQL queries. This prevents SQL injection attacks and handles proper escaping of user input.
:::

### Protocols Module - Network Protocols

```pike
//-----------------------------
// Recipe: Work with HTTP and DNS
//-----------------------------
#pragma strict_types

import Protocols.HTTP;
import Protocols.DNS;

int main() {
    // HTTP GET request
    object req = get_url("https://pike.lysator.liu.se/");
    if (req) {
        write("Status: %d\n", req->status_code);
        write("Body length: %d\n", sizeof(req->body));
    }

    // DNS query
    object dns = Protocols.DNS.client();
    mapping result = dns->gethostbyname("example.com");
    write("IP addresses: %{%s, %}\n", result->ip || ({}));

    // HTTP POST with JSON
    mapping data = ([
        "name": "Alice",
        "age": 30,
    ]);
    string json = Standards.JSON.encode(data);

    object post_req = post_url(
        "https://api.example.com/users",
        ([
            "Content-Type": "application/json",
        ]),
        json
    );

    return 0;
}
```

---

## Module Dependencies and Versioning

Pike 8 provides mechanisms to manage module dependencies and ensure compatibility. Use constants for versioning and `#require` for dependency checking.

```pike
//-----------------------------
// Recipe: Add version checking to modules
//-----------------------------
// File: AppConfig.pmod
#pragma strict_types

// Version information
constant VERSION = "1.2.0";
constant PIKE_MIN_VERSION = "8.0";

// Required modules - compile error if not available
#require constant(__VERSION__) >= 8.0

//! Check if module version meets requirements.
bool version_at_least(string required_version) {
    array current = map(VERSION / ".", String.trim_all_whites);
    array required = map(required_version / ".", String.trim_all_whites);

    for (int i = 0; i < sizeof(required); i++) {
        if ((int)current[i] < (int)required[i])
            return false;
        if ((int)current[i] > (int)required[i])
            return true;
    }
    return true;
}
```

Module with Dependency Resolution:

```pike
//-----------------------------
// Recipe: Handle optional dependencies gracefully
//-----------------------------
// File: DataProcessor.pmod
#pragma strict_types

// Optional dependencies with graceful fallback
object crypto_module;

mixed error = catch {
    crypto_module = master()->resolv("Crypto.Hash.MD5");
};

constant HAS_CRYPTO = !zero_type(crypto_module);

//! Process data with optional encryption.
string process(string data, bool|void encrypt) {
    string result = String.trim_all_whites(data);

    if (encrypt && HAS_CRYPTO) {
        // Use Crypto module if available
        result = crypto_module->hash(result);
    } else if (encrypt) {
        werror("Warning: Crypto module not available, skipping encryption\n");
    }

    return result;
}
```

---

## Best Practices for Module Organization

Follow these conventions for clean, maintainable Pike 8 modules:

- **Use `#pragma strict_types`** - Always enable strict typing for better error detection
- **Document with AutoDoc** - Use `//!` comments for all public interfaces
- **Name private members with underscore** - Prefix internal functions and variables with `_`
- **Use `protected` for module-level privacy** - Controls symbol visibility
- **Organize by feature, not type** - Group related functionality together
- **Keep modules focused** - Each module should have a single, clear responsibility

```pike
// Recommended module structure:
// MyApp/
//   MyApp.pmod              # Main module (constants, version)
//   Core.pmod/              # Core functionality
//     Database.pmod         # Database layer
//     Cache.pmod            # Caching layer
//   Utils.pmod/             # Utilities (can be used independently)
//     String.pmod
//     Time.pmod
//   Services.pmod/          # Business logic
//     Auth.pmod             # Authentication
//     Email.pmod            # Email handling

// File: MyApp.pmod
//! MyApp - Application framework.

#pragma strict_types

constant VERSION = "1.0.0";
constant API_LEVEL = 3;

// Export commonly used functionality
import .Core.Database;
import .Services.Auth;
```

---

## Complete Module Example: Logger

Here's a complete, production-ready logger module demonstrating Pike 8 best practices:

```pike
//-----------------------------
// Program: Production-ready logging module
//-----------------------------
// File: Logger.pmod
//! Flexible logging module with multiple output handlers.
//! @example
//! // Basic usage
//! import Logger;
//! Logger.info("Application started");
//! Logger.error("Database connection failed");

#pragma strict_types

// Log levels
constant DEBUG = 0;
constant INFO = 1;
constant WARNING = 2;
constant ERROR = 3;

// Configuration
protected int _min_level = INFO;
protected string _log_file = "";
protected bool _use_stderr = true;
protected bool _use_timestamp = true;
protected bool _use_colors = true;

//! Set minimum log level.
void set_level(int level) {
    _min_level = level;
}

//! Enable file logging.
void set_log_file(string path) {
    _log_file = path;
}

//! Enable/disable stderr output.
void set_use_stderr(bool enabled) {
    _use_stderr = enabled;
}

//! Enable/disable timestamps in logs.
void set_use_timestamp(bool enabled) {
    _use_timestamp = enabled;
}

//! Enable/disable terminal colors.
void set_use_colors(bool enabled) {
    _use_colors = enabled;
}

//! Log a debug message.
void debug(string msg, mixed... args) {
    _log(DEBUG, "DEBUG", msg, @args);
}

//! Log an info message.
void info(string msg, mixed... args) {
    _log(INFO, "INFO", msg, @args);
}

//! Log a warning message.
void warning(string msg, mixed... args) {
    _log(WARNING, "WARNING", msg, @args);
}

//! Log an error message.
void error(string msg, mixed... args) {
    _log(ERROR, "ERROR", msg, @args);
}

// Internal logging implementation
protected void _log(int level, string level_name, string msg, mixed... args) {
    if (level < _min_level) return;

    // Format message
    string formatted = sprintf(msg, @args);

    // Add timestamp
    if (_use_timestamp) {
        string ts = Calendar.ISO.now()->format_time();
        formatted = sprintf("[%s] [%s] %s", ts, level_name, formatted);
    } else {
        formatted = sprintf("[%s] %s", level_name, formatted);
    }

    // Add colors for terminal
    if (_use_colors) {
        formatted = _colorize(level, formatted);
    }

    // Output to stderr
    if (_use_stderr) {
        werror("%s\n", formatted);
    }

    // Output to file
    if (_log_file != "") {
        object f = Stdio.append_file(_log_file);
        if (f) {
            // Strip ANSI colors for file output
            string clean = _strip_colors(formatted);
            f->write("%s\n", clean);
            f->close();
        }
    }
}

protected string _colorize(int level, string msg) {
    switch(level) {
        case DEBUG:
            return sprintf("\033[0;36m%s\033[0m", msg);  // Cyan

        case INFO:
            return sprintf("\033[0;32m%s\033[0m", msg);   // Green

        case WARNING:
            return sprintf("\033[0;33m%s\033[0m", msg);  // Yellow

        case ERROR:
            return sprintf("\033[0;31m%s\033[0m", msg);   // Red

        default:
            return msg;
    }
}

protected string _strip_colors(string msg) {
    // Remove ANSI escape sequences
    return Regexp.replace("\033\\[[0-9;]*m", msg, "");
}
```

Using the Logger Module:

```pike
//-----------------------------
// Recipe: Use the Logger module
//-----------------------------
// File: app.pike
#pragma strict_types

import Logger;

int main(int argc, array(string) argv) {
    // Configure logger
    if (argc > 1 && argv[1] == "--verbose") {
        set_level(DEBUG);
    }

    set_log_file("app.log");

    // Use logger
    info("Application starting");

    debug("Processing %d items", 42);

    warning("Configuration file not found, using defaults");

    error("Failed to connect to database: %s", "connection timeout");

    info("Application shutting down");

    return 0;
}
```

:::tip
This logger module demonstrates several best practices: clear public interface, protected internal state, comprehensive documentation, and sensible defaults. The module is both easy to use for beginners and configurable for advanced users.
:::

---

## See Also

- [Classes](/docs/advanced/classes) - Object-oriented programming in Pike
- [References and Records](/docs/advanced/references) - Data structures and memory management
- [Strings](/docs/basics/strings) - String manipulation
- [Network Programming](/docs/network/sockets) - Network protocols and sockets
