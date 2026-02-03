---
id: packagesetc
title: Packages, Libraries, and Modules
sidebar_label: Packages, Libraries, and Modules
---

## Introduction

Pike 8 provides a comprehensive module system for organizing code into reusable packages and libraries. This chapter covers modern module organization techniques, imports, and best practices for creating maintainable code structures.

## Module Organization

```pike
// Modern Pike 8 module organization
#pragma strict_types

// Basic module structure
module MyModule {
    // Public API
    public constant VERSION = "1.0.0";

    public function(string:string) process;

    // Private implementation
    private string _internal_data = "";

    // Public function
    public function(string:string) process = lambda(string input) {
        return upper_case(input);
    };

    // Public accessors
    public string get_version() { return VERSION; }
}

// Using the module
MyModule mod = MyModule();
write("Module version: %s\n", mod->get_version());
write("Processed: %s\n", mod->process("hello"));
```

## Import Management

```pike
// Recipe 12.1: Managing Imports
import System;
import Stdio;
import Crypto;

// Selective imports with aliases
import Database.{ Connection as DBConn, Statement };

// Modern import patterns
import ADT.Array;
import ADT.Mapping;

// Conditional imports
#if constant(GTK2)
import GTK2;
#endif

// Import version checking
constant MIN_PIKE_VERSION = "8.0";
#if constant(version) && version() < MIN_PIKE_VERSION
error("Pike version %s required", MIN_PIKE_VERSION);
#endif
```

## Package Structure

```pike
// Pike 8 package organization
package com.example.mypackage;

// Package-level constants
constant PACKAGE_NAME = "MyPackage";
constant PACKAGE_VERSION = "1.0.0";

// Package initialization
static void create() {
    write("Package %s initialized\n", PACKAGE_NAME);
}

// Package functions
public function(string:string) string_processor =
    lambda(string s) { return upper_case(s); };
```

## Library Creation

```pike
// Recipe 12.2: Creating Reusable Libraries
#pragma strict_types

// Library interface
class Library {
    // Configuration
    protected mapping(string:mixed) config = ([]);

    // Core functionality
    public function(string:mixed) get;
    public function(string:mixed:void) set;

    // Constructor
    void create(mapping(string:mixed)|void init_config) {
        if (init_config) {
            config = init_config;
        }
    }
}

// String processing library
class StringLibrary {
    public function(string:string) uppercase;
    public function(string:string) lowercase;
    public function(string:int) length;

    void create() {
        uppercase = lambda(string s) { return upper_case(s); };
        lowercase = lambda(string s) { return lower_case(s); };
        length = lambda(string s) { return sizeof(s); };
    }
}

// Usage example
StringLibrary strings = StringLibrary();
write("Length: %d\n", strings->length("Hello"));
write("Uppercase: %s\n", strings->uppercase("hello"));
```

## Module Dependencies

```pike
// Recipe 12.3: Managing Module Dependencies
import Crypto.MD5;
import Crypto.SHA1;
import Crypto.RSA;

// Dependency management class
class DependencyManager {
    private array(string) required_modules = ({
        "Crypto.MD5",
        "Crypto.SHA1"
    });

    public int check_dependencies() {
        foreach(required_modules, string module) {
            if (!constant(module)) {
                write("Missing dependency: %s\n", module);
                return 0;
            }
        }
        return 1;
    }
}

// Example usage
DependencyManager deps = DependencyManager();
if (deps->check_dependencies()) {
    write("All dependencies satisfied\n");
}
```

## Version Control

```pike
// Recipe 12.4: Version Control for Modules
constant MODULE_VERSION = "1.2.0";
constant MODULE_NAME = "AdvancedTools";

// Version information mapping
mapping(string:mixed) version_info = ([
    "name": MODULE_NAME,
    "version": MODULE_VERSION,
    "author": "Pike Team",
    "description": "Advanced tools for Pike 8"
]);

// Version checking function
public int version_check(string required_version) {
    return version_compare(MODULE_VERSION, required_version) >= 0;
}

// Usage
write("Module: %s v%s\n", version_info->name, version_info->version);
```

## Plugin System

```pike
// Recipe 12.5: Plugin System Implementation
class PluginManager {
    private mapping(string:object) loaded_plugins = ([]);

    public int register_plugin(string name, object plugin) {
        if (loaded_plugins[name]) {
            error("Plugin %s already registered", name);
        }
        loaded_plugins[name] = plugin;
        return 1;
    }

    public object|zero get_plugin(string name) {
        return loaded_plugins[name];
    }

    public array(string) list_plugins() {
        return indices(loaded_plugins);
    }
}

// Base plugin interface
class Plugin {
    public string name;
    public string version;

    public void create(string n, string v) {
        name = n;
        version = v;
    }

    public void init() {
        // Override in subclasses
    }
}

// Example plugin
class MyPlugin {
    inherit Plugin;

    void create() {
        ::create("MyPlugin", "1.0.0");
    }

    public void init() {
        write("MyPlugin initialized\n");
    }
}

// Usage
PluginManager manager = PluginManager();
manager->register_plugin("myplugin", MyPlugin());
```