---
id: directories
title: Directories
sidebar_label: Directories
---

# Directories

## Introduction

Working with directories is essential for file system operations. Pike provides comprehensive tools for directory traversal, creation, and manipulation.

:::tip
Always check if a directory exists before operations using `file_stat()` or `Stdio.is_dir()`.
:::

---

## Reading Directory Contents

### List All Files

```pike
//-----------------------------
// Recipe: List directory contents
//-----------------------------

// Method 1: Using get_dir()
array(string) files = get_dir("/path/to/directory");

if (files) {
    write("Found %d items:\n", sizeof(files));
    foreach(files;; string filename) {
        write("  - %s\n", filename);
    }
} else {
    werror("Directory not found or not readable\n");
}

// Method 2: Using file system object
Stdio.File dir = Stdio.File("/path/to/directory");

if (dir) {
    array(string) contents = dir->get_dir();
    foreach(contents;; string item) {
        write("%s\n", item);
    }
    dir->close();
}
```

### Filter Files by Type

```pike
//-----------------------------
// Recipe: List only files or directories
//-----------------------------

string path = "/path/to/directory";
array(string) all_items = get_dir(path) || ({});

array(string) files = ({});
array(string) directories = ({});

foreach(all_items;; string item) {
    string full_path = combine_path(path, item);
    object stat = file_stat(full_path);

    if (!stat) continue;

    if (stat->isdir) {
        directories += ({item});
    } else if (stat->isreg) {
        files += ({item});
    }
}

write("Directories:\n");
foreach(directories;; string d) {
    write("  [DIR] %s\n", d);
}

write("Files:\n");
foreach(files;; string f) {
    write("  [FILE] %s\n", f);
}
```

### Recursive Directory Listing

```pike
//-----------------------------
// Recipe: List all files recursively
//-----------------------------

array(string) list_files_recursive(string path, void|bool include_hidden) {
    array(string) result = ({});
    array(string) items = get_dir(path);

    if (!items) return result;

    foreach(items;; string item) {
        // Skip hidden files (starting with .)
        if (!include_hidden && has_prefix(item, "."))
            continue;

        string full_path = combine_path(path, item);
        object stat = file_stat(full_path);

        if (!stat) continue;

        // Add to result
        result += ({full_path});

        // Recurse into subdirectories
        if (stat->isdir) {
            result += list_files_recursive(full_path, include_hidden);
        }
    }

    return result;
}

// Usage
array(string) all_files = list_files_recursive("/home/user/documents");
write("Found %d files:\n", sizeof(all_files));
foreach(all_files;; string f) {
    write("  %s\n", f);
}
```

---

## Creating Directories

### Create Single Directory

```pike
//-----------------------------
// Recipe: Create a directory
//-----------------------------

string dir_path = "/tmp/new_directory";

// Check if exists
if (file_stat(dir_path)) {
    werror("Directory already exists\n");
} else {
    // Create directory
    if (mkdir(dir_path)) {
        write("Created directory: %s\n", dir_path);
    } else {
        werror("Failed to create directory: %s\n", strerror(errno()));
    }
}
```

### Create Nested Directories

```pike
//-----------------------------
// Recipe: Create directory with parents
//-----------------------------

// Pike doesn't have mkdir -p built-in, so create recursively
bool mkdir_p(string path) {
    // Check if already exists
    object stat = file_stat(path);
    if (stat && stat->isdir) {
        return true;
    }

    // Create parent directories first
    string parent = dirname(path);
    if (sizeof(parent) && parent != path) {
        if (!mkdir_p(parent)) {
            return false;
        }
    }

    // Create this directory
    if (mkdir(path)) {
        return true;
    }

    // Check if it was created by another process
    stat = file_stat(path);
    return (stat && stat->isdir);
}

// Usage
string deep_path = "/tmp/level1/level2/level3";
if (mkdir_p(deep_path)) {
    write("Created: %s\n", deep_path);
} else {
    werror("Failed to create: %s\n", deep_path);
}
```

---

## Removing Directories

### Remove Empty Directory

```pike
//-----------------------------
// Recipe: Remove empty directory
//-----------------------------

string dir_path = "/tmp/empty_dir";

// Check if directory is empty
array(string) contents = get_dir(dir_path);
if (contents && sizeof(contents) == 0) {
    if (rm(dir_path)) {
        write("Removed empty directory\n");
    } else {
        werror("Failed to remove: %s\n", strerror(errno()));
    }
} else {
    werror("Directory not empty\n");
}
```

### Remove Directory and Contents

```pike
//-----------------------------
// Recipe: Remove directory recursively
//-----------------------------

bool remove_recursive(string path) {
    object stat = file_stat(path);

    if (!stat) {
        // Already gone
        return true;
    }

    if (stat->isreg) {
        // Remove file
        return rm(path);
    }

    if (stat->isdir) {
        // Remove contents first
        array(string) items = get_dir(path);
        if (items) {
            foreach(items;; string item) {
                string full_path = combine_path(path, item);
                if (!remove_recursive(full_path)) {
                    return false;
                }
            }
        }

        // Remove empty directory
        return rm(path);
    }

    return false;
}

// Usage
if (remove_recursive("/tmp/mydata")) {
    write("Removed directory tree\n");
}
```

:::warning
Be very careful with recursive deletion! Always verify the path before calling `remove_recursive()`.
:::

---

## Changing Directories

### Current Working Directory

```pike
//-----------------------------
// Recipe: Get and change current directory
//-----------------------------

// Get current directory
string cwd = getcwd();
write("Current directory: %s\n", cwd);

// Change directory
if (cd("/tmp")) {
    write("Changed to: %s\n", getcwd());
} else {
    werror("Failed to change directory\n");
}

// Execute in directory
cd("/home/user");
array(string) files = get_dir(".");
write("Files in home: %s\n", files * ", ");
```

### Operations in Different Directory

```pike
//-----------------------------
// Recipe: Work with files in other directories
//-----------------------------

// Read file from another directory
string content = Stdio.read_file("/path/to/file.txt");

// Better: use combine_path for portability
string base_dir = "/path/to";
string filename = "file.txt";
string full_path = combine_path(base_dir, filename);
content = Stdio.read_file(full_path);

// Relative paths work too
string config = Stdio.read_file("../config/settings.ini");
```

---

## Directory Information

### Get Directory Size

```pike
//-----------------------------
// Recipe: Calculate directory size
//-----------------------------

int get_directory_size(string path) {
    int total_size = 0;
    array(string) items = get_dir(path);

    if (!items) return 0;

    foreach(items;; string item) {
        string full_path = combine_path(path, item);
        object stat = file_stat(full_path);

        if (!stat) continue;

        if (stat->isreg) {
            total_size += stat->size;
        } else if (stat->isdir) {
            total_size += get_directory_size(full_path);
        }
    }

    return total_size;
}

// Format size nicely
string format_size(int bytes) {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1024 * 1024) return sprintf("%.1f KB", bytes / 1024.0);
    if (bytes < 1024 * 1024 * 1024) return sprintf("%.1f MB", bytes / (1024.0 * 1024));
    return sprintf("%.1f GB", bytes / (1024.0 * 1024 * 1024));
}

// Usage
int size = get_directory_size("/home/user/documents");
write("Directory size: %s\n", format_size(size));
```

### Find Largest Files

```pike
//-----------------------------
// Recipe: Find largest files in directory tree
//-----------------------------

array(mapping) find_largest_files(string path, int top_n) {
    mapping(string:int) file_sizes = ([]);

    // Collect all files
    array(string) all_files = list_files_recursive(path);

    foreach(all_files;; string filepath) {
        object stat = file_stat(filepath);
        if (stat && stat->isreg) {
            file_sizes[filepath] = stat->size;
        }
    }

    // Sort by size
    array(string) sorted = indices(file_sizes);
    sort(file_sizes[*], sorted);
    sorted = reverse(sorted);

    // Get top N
    array(mapping) result = ({});
    foreach(sorted[0..top_n-1];; string filepath) {
        result += ({([
            "path": filepath,
            "size": file_sizes[filepath],
            "formatted": format_size(file_sizes[filepath])
        ])});
    }

    return result;
}

// Usage
array(mapping) largest = find_largest_files("/home/user", 10);
write("Largest files:\n");
foreach(largest;; mapping info) {
    write("  %s: %s\n", info->formatted, info->path);
}
```

---

## Directory Patterns

### Find Files Matching Pattern

```pike
//-----------------------------
// Recipe: Find files by pattern
//-----------------------------

array(string) find_files_by_pattern(string path, string pattern) {
    array(string) result = ({});
    array(string) items = get_dir(path);

    if (!items) return result;

    // Create regex from glob pattern
    string regex = replace(pattern, ({"*", "."}), ({"[^/]*", "\\."}));
    object re = Regexp.SimpleRegexp("^" + regex + "$");

    foreach(items;; string item) {
        if (re->match(item)) {
            result += ({combine_path(path, item)});
        }
    }

    return result;
}

// Usage
array(string) pike_files = find_files_by_pattern("/home/user/code", "*.pike");
write("Pike files:\n");
foreach(pike_files;; string f) {
    write("  %s\n", f);
}

// Find log files
array(string) logs = find_files_by_pattern("/var/log", "*.log");
```

### Directory Watcher

```pike
//-----------------------------
// Recipe: Monitor directory for changes
//-----------------------------

mapping(string:int) get_directory_state(string path) {
    mapping(string:int) state = ([]);
    array(string) items = get_dir(path);

    if (!items) return state;

    foreach(items;; string item) {
        string full_path = combine_path(path, item);
        object stat = file_stat(full_path);

        if (stat) {
            state[full_path] = stat->mtime;
        }
    }

    return state;
}

void watch_directory(string path, int interval_seconds) {
    write("Watching: %s\n", path);

    mapping(string:int) last_state = get_directory_state(path);

    while (1) {
        sleep(interval_seconds);

        mapping(string:int) current_state = get_directory_state(path);

        // Check for new files
        foreach(indices(current_state);; string file) {
            if (!last_state[file]) {
                write("NEW: %s\n", file);
            } else if (current_state[file] > last_state[file]) {
                write("MODIFIED: %s\n", file);
            }
        }

        // Check for deleted files
        foreach(indices(last_state);; string file) {
            if (!current_state[file]) {
                write("DELETED: %s\n", file);
            }
        }

        last_state = current_state;
    }
}

// Usage (in a separate thread or background)
// watch_directory("/home/user/watch", 5);
```

---

## Practical Examples

### Clean Temporary Files

```pike
//-----------------------------
// Recipe: Remove files older than N days
//-----------------------------

void cleanup_old_files(string path, int max_age_days) {
    int cutoff_time = time() - (max_age_days * 24 * 60 * 60);
    int deleted_count = 0;
    int freed_space = 0;

    array(string) files = list_files_recursive(path);

    foreach(files;; string filepath) {
        object stat = file_stat(filepath);

        if (stat && stat->isreg && stat->mtime < cutoff_time) {
            int size = stat->size;

            if (rm(filepath)) {
                deleted_count++;
                freed_space += size;
                write("Deleted: %s (%s)\n",
                      filepath, format_size(size));
            }
        }
    }

    write("\nSummary:\n");
    write("  Deleted: %d files\n", deleted_count);
    write("  Freed: %s\n", format_size(freed_space));
}

// Usage: Delete files older than 30 days
// cleanup_old_files("/tmp/cache", 30);
```

### Organize Files by Extension

```pike
//-----------------------------
// Recipe: Sort files into subdirectories
//-----------------------------

void organize_by_extension(string source_dir) {
    array(string) files = get_dir(source_dir) || ({});

    foreach(files;; string filename) {
        string full_path = combine_path(source_dir, filename);
        object stat = file_stat(full_path);

        if (!stat || !stat->isreg) continue;

        // Get extension
        array(string) parts = filename / ".";
        string ext = sizeof(parts) > 1 ? parts[-1] : "no_ext";

        // Create target directory
        string target_dir = combine_path(source_dir, ext);
        mkdir_p(target_dir);

        // Move file
        string target_path = combine_path(target_dir, filename);

        if (rename(full_path, target_path)) {
            write("Moved: %s -> %s/\n", filename, ext);
        }
    }
}

// Usage
// organize_by_extension("/home/user/Downloads");
```

### Backup Directory

```pike
//-----------------------------
// Recipe: Create timestamped backup
//-----------------------------

string backup_directory(string source_dir, string backup_root) {
    // Create backup name with timestamp
    string timestamp = Calendar.ISO.now()->format_nice();
    timestamp = replace(timestamp, " ", "_");
    timestamp = replace(timestamp, ":", "-");

    string backup_name = basename(source_dir) + "_backup_" + timestamp;
    string backup_path = combine_path(backup_root, backup_name);

    write("Creating backup: %s\n", backup_path);

    // Copy directory recursively
    array(string) items = get_dir(source_dir);
    if (!items) {
        werror("Source directory not found\n");
        return "";
    }

    mkdir_p(backup_path);

    foreach(items;; string item) {
        string src = combine_path(source_dir, item);
        string dst = combine_path(backup_path, item);

        object stat = file_stat(src);
        if (!stat) continue;

        if (stat->isreg) {
            // Copy file
            string content = Stdio.read_file(src);
            if (content) {
                Stdio.write_file(dst, content);
            }
        } else if (stat->isdir) {
            // Recurse into subdirectory
            backup_directory(src, backup_path);
        }
    }

    return backup_path;
}

// Usage
// string backup = backup_directory("/home/user/documents", "/backups");
// write("Backup created at: %s\n", backup);
```

---

## See Also

- [File Access](/docs/files/file-access) - Working with individual files
- [File Contents](/docs/files/file-contents) - Reading and writing file data
- [Database Access](/docs/files/database-access) - Database operations
