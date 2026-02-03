---
id: directories
title: Directories
sidebar_label: Directories
---

## Directories

### Introduction

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0

Stdio.Stat entry;

entry = file_stat("/bin/vi");
entry = file_stat("/usr/bin");
entry = file_stat(argv[1]);

// ------------

Stdio.Stat entry; int ctime, size;

entry = file_stat("/bin/vi");
ctime = entry->ctime;
size = entry->size;

// ------------
// A routine detecting whether a file is a 'text' file doesn't appear
// to exist, so have implemented the following [crude] function(s)
// which search for a LF / NEWLINE in the file:

// Usable with any file
int(0..1) containsText(Stdio.File file)
{
  string|zero c;
  while ((c = file->read(1)) != NULL) { (c == NEWLINE) && return 1; }
  return 0;
}

// Alternate version, expects a buffered file [usually containing text]
int(0..1) containsText(Stdio.FILE file)
{
  int c;
  while ((c = file->getchar()) != EOF) { (c == LF) && return 1; }
  return 0;
}

// Yet another alternative - this time we cheat and use the *NIX 'file'
// utility :) !

int(0..1) isTextFile(string filename)
{
  return chop(Process.popen("file -bN " + filename), 1)  == "ASCII text";
}

// ----
containsText(Stdio.File(argv[1])) || write("File %s doesn't have any text in it\n", argv[1]);
isTextFile(argv[1]) || write("File %s doesn't have any text in it\n", argv[1]);

// ------------
Filesystem.Traversion dirtree = Filesystem.Traversion("/usr/bin");

foreach(dirtree; string dir; string file)
{
  write("Inside %s is something called %s\n", chop(dir, 1), file);
}
```

### Getting and Setting Timestamps

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
string filename = "example.txt";
Stdio.Stat fs = file_stat(filename);
int readtime = fs->atime, writetime = fs->mtime;
System.utime(filename, readtime, writetime);
// ----------------------------
constant SECONDS_PER_DAY = 60 * 60 * 24;
string filename = "example.txt";
Stdio.Stat fs = file_stat(filename);
int atime = fs->atime, mtime = fs->mtime;
atime -= 7 * SECONDS_PER_DAY; mtime -= 7 * SECONDS_PER_DAY;
System.utime(filename, atime, mtime);
// ----------------------------
argc != 1 || die("usage: " + argv[0] + " filename");
Stdio.Stat fs = file_stat(argv[1]);
int atime = fs->atime, mtime = fs->mtime;
Process.system(getenv("EDITOR") || "vi" + " " + argv[1]);
mixed result = catch { System.utime(argv[1], atime, mtime); };
(result == OK) || write("Error updating timestamp on file, %s!\n", argv[1]);
```

### Deleting a File

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
string filename = "...";
rm(filename) || write("Can't delete, %s!\n", filename);
// ------------
int(0..1) rmAll(array(string) filelist)
{
  mixed|zero result = catch
  {
    foreach(filelist, string filename) { rm(filename) || throw(PROBLEM); }
  };
  return result == OK;
}
// ----
array(string) filelist = ({"/tmp/x", "/tmp/y", "/tmp/z"});
rmAll(filelist) || write("Can't delete all files in array!\n");
// ----------------------------
void die(string msg, void|int(1..256) rc) { werror(msg + NEWLINE); exit(rc ? rc : PROBLEM); }
// ----
string filename = "...";
rm(filename) || die("Can't delete " + filename);
// ----------------------------
array(string) filelist = ({"/tmp/x", "/tmp/y", "/tmp/z"});
int deleted, count = sizeof(filelist);
foreach(filelist, string filename) { rm(filename) && ++deleted; }
```

### Copying Files

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
string source = "file1", dest = "file2";
Stdio.write_file(dest, Stdio.read_file(source)) || write("Copy failed: %s\n", strerror(errno()));
// ----
// Directory copy
int copy_dir(string from, string to)
{
  if (!Stdio.is_directory(from)) return 0;

  // Create destination directory
  Stdio.make_directory(to) || (access(to, W_OK) == -1 && Stdio.make_directory(to));

  // Copy all files
  foreach(get_dir(from), string file)
  {
    if (file != "." && file != "..")
    {
      string src = from + "/" + file;
      string dst = to + "/" + file;
      if (Stdio.is_directory(src))
        copy_dir(src, dst);
      else
        Stdio.write_file(dst, Stdio.read_file(src)) ||
          write("Failed to copy %s to %s\n", src, dst);
    }
  }
  return 1;
}
```

### Moving Files

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
string source = "oldname", dest = "newname";
rename(source, dest) || write("Rename failed: %s\n", strerror(errno()));
// ----
// Directory move/rename
int move_dir(string from, string to)
{
  if (!Stdio.is_directory(from)) return 0;

  // Create destination directory
  Stdio.make_directory(to) || (access(to, W_OK) == -1 && Stdio.make_directory(to));

  // Move all files
  foreach(get_dir(from), string file)
  {
    if (file != "." && file != "..")
    {
      string src = from + "/" + file;
      string dst = to + "/" + file;
      if (Stdio.is_directory(src))
        move_dir(src, dst);
      else
        rename(src, dst) || write("Failed to move %s to %s\n", src, dst);
    }
  }
  return 1;
}
```

### File and Directory Size

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// File size
Stdio.Stat stat = file_stat("filename.txt");
if (stat)
{
  write("Size: %d bytes\n", stat->size);
  write("Modified: %s\n", ctime(stat->mtime));
}
// Directory size
int dir_size(string path)
{
  int total = 0;
  foreach(get_dir(path), string file)
  {
    if (file != "." && file != "..")
    {
      string full_path = path + "/" + file;
      Stdio.Stat s = file_stat(full_path);
      if (s)
      {
        if (s->isdir)
          total += dir_size(full_path);
        else
          total += s->size;
      }
    }
  }
  return total;
}
```

### Deleting Directories

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// Simple directory removal (must be empty)
Stdio.rmdir("empty_dir") || write("Can't remove directory: %s\n", strerror(errno()));
// Recursive directory removal
int rmdir(string path)
{
  foreach(get_dir(path) || ({}), string file)
  {
    if (file != "." && file != "..")
    {
      string full_path = path + "/" + file;
      Stdio.Stat s = file_stat(full_path);
      if (s)
      {
        if (s->isdir)
          rmdir(full_path);
        else
          rm(full_path);
      }
    }
  }
  return Stdio.rmdir(path);
}
// ----
// Force remove directory with all contents
int rm_rf(string path)
{
  mixed err = catch
  {
    foreach(get_dir(path) || ({}), string file)
    {
      if (file != "." && file != "..")
      {
        string full_path = path + "/" + file;
        Stdio.Stat s = file_stat(full_path);
        if (s)
        {
          if (s->isdir)
            rm_rf(full_path);
          else
            rm(full_path);
        }
      }
    }
    rmdir(path);
  };
  return !err;
}
```

### Reading Directories

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// List directory contents
array files = get_dir("/path/to/directory");
foreach(files || ({}), string file)
{
  write("%s\n", file);
}
// List with full paths
array full_files = map(get_dir("/path/to/directory") || ({}),
                     string file: "/path/to/directory/" + file);
// Filter directories
array dirs = filter(get_dir("/path/to/directory") || ({}),
                   string file: file_stat("/path/to/directory/" + file)->isdir);
// Filter files
array only_files = filter(get_dir("/path/to/directory") || ({}),
                        string file: !file_stat("/path/to/directory/" + file)->isdir);
```

### Making and Removing Directories

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// Create directory
Stdio.make_directory("new_dir") || write("Failed: %s\n", strerror(errno()));
// Create with parents
int mkdir_p(string path)
{
  array parts = path/"/";
  string current = "";
  foreach(parts, string part)
  {
    if (!part) continue;
    current += "/" + part;
    if (!Stdio.exist(current) && !Stdio.make_directory(current))
    {
      write("Failed to create %s: %s\n", current, strerror(errno()));
      return 0;
    }
  }
  return 1;
}
// Remove directory (must be empty)
Stdio.rmdir("empty_dir") || write("Failed: %s\n", strerror(errno()));
```

### Changing Permissions

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// File permissions
Stdio.Stat s = file_stat("filename.txt");
if (s)
{
  write("Current permissions: %o\n", s->mode & 0777);
  // Set new permissions
  if (!s->isdir)
    s->mode = 0644;  // rw-r--r--
  else
    s->mode = 0755;  // rwxr-xr-x
}
// Set permissions
Stdio.chmod("filename.txt", 0644) || write("Failed: %s\n", strerror(errno()));
// Recursive permission change
int chmod_r(string path, int mode)
{
  foreach(get_dir(path) || ({}), string file)
  {
    if (file != "." && file != "..")
    {
      string full_path = path + "/" + file;
      Stdio.Stat s = file_stat(full_path);
      if (s)
      {
        Stdio.chmod(full_path, mode);
        if (s->isdir)
          chmod_r(full_path, mode);
      }
    }
  }
  return 1;
}
```

### Symbolic Links

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// Create symlink
Stdio.symlink("target", "linkname") || write("Failed: %s\n", strerror(errno()));
// Read link target
string target = readlink("linkname");
if (target)
  write("Link points to: %s\n", target);
else
  write("Not a symbolic link\n");
// Check if path is a symlink
Stdio.Stat s = file_stat("linkname");
if (s && s->islnk)
  write("Is a symbolic link\n");
// Recursive link following
string real_path = Stdio.readlink("linkname");
while (real_path && Stdio.stat(real_path)->islnk)
  real_path = Stdio.readlink(real_path);
```

### Path Manipulation

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// Path operations
string path = "/path/to/file.txt";
string dirname = path;
int last_slash = search(dirname, "/", -1);
if (last_slash != -1)
  dirname = dirname[..last_slash-1];
else
  dirname = "/";
string filename = path[last_slash+1..];
// Join paths
string joined = combine_path("/base", "sub/path");
// Split path into components
array parts = path/"/";
// Normalize path (remove . and ..)
string normalized = Stdio.get_path(normalize_path(path));
```

### Directory Traversal

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// Traverse directory tree
void traverse_dir(string path)
{
  write("Processing: %s\n", path);
  array files = get_dir(path) || ({});
  foreach(files, string file)
  {
    if (file == "." || file == "..") continue;
    string full_path = path + "/" + file;
    Stdio.Stat s = file_stat(full_path);
    if (s)
    {
      if (s->isdir)
        traverse_dir(full_path);
      else
        write("File: %s (%d bytes)\n", full_path, s->size);
    }
  }
}
// Using Filesystem.Traversion
Filesystem.Traversion dirtree = Filesystem.Traversion("/path/to/dir");
foreach(dirtree; string dir; string file)
{
  write("In %s: %s\n", dir, file);
}
```

### Temporary Files and Directories

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// Create temporary file
string tmpfile = combine_path("/tmp", "tmpfile_" + String.string_to_random(8));
Stdio.write_file(tmpfile, "temporary content") || write("Failed\n");
// Clean up
rm(tmpfile);
// Create temporary directory
string tmpdir = combine_path("/tmp", "tmpdir_" + String.string_to_random(8));
Stdio.make_directory(tmpdir) || write("Failed\n");
// Clean up
rm_rf(tmpdir);
// System temp directory
string system_temp = getenv("TMPDIR") || "/tmp";
```

### File Locking

```pike
// #!/usr/bin/pike
#pragma strict_types
#pragma pike 8.0
// Simple file locking
int lock_file(string filename)
{
  Stdio.File f = Stdio.File(filename, "wxc");
  if (!f)
    return 0;
  // Write lock info
  f->write_lock_info("Locked");
  f->close();
  return 1;
}
// Check if file is locked
int is_locked(string filename)
{
  Stdio.File f = Stdio.File(filename, "r");
  if (!f) return 0;
  string lock_info = f->read_lock_info();
  f->close();
  return !!lock_info;
}
// Unlock file
unlock_file(string filename)
{
  rm(filename);
}
```