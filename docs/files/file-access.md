---
id: file-access
title: File Access
sidebar_label: File Access
---

## 7. File Access

### Introduction

```pike
// if you are going to read the whole file, the most common way is to use
// Stdio.read_file()

string INPUT = Stdio.read_file("/usr/local/widgets/data");
if(!INPUT)
{
  werror("Couldn't open /usr/local/widgets/data for reading\n");
  exit(1);
}

foreach(INPUT/"\n";; string line)
{
  if(search(line, "blue")!=-1)
    write(line+"\n");
}

// if you need more control over the process you can get a filehandle with
// Stdio.File()

Stdio.File INPUT = Stdio.File("/usr/local/widgets/data", "r");
if(!INPUT)
{
  werror("Couldn't open /usr/local/widgets/data for reading\n");
  exit(1);
}

foreach(INPUT->line_iterator();; string line)
{
  if(search(line, "blue")!=-1)
    write(line+"\n");
}
INPUT->close();

//---------------------------------------------------------

foreach(Stdio.stdin;; string line)            // reads from STDIN
{
  if(!sizeof(array_sscanf(line, "%*s%d")))
    werror("No digit found.\n");              // writes to STDERR
  write("Read: %s\n", line);                  // writes ot STDOUT
}
Stdio.stdout->close() || werror("couldn't close STDOUT\n") && exit(1);

// just as with Stdio.read_file(), there are convenience functions for writing:
// Stdio.write_file() and Stdio.append_file()

Stdio.File logfile = Stdio.File("/tmp/log", "w");

// access modes are "r" for reading, "w" for writing and "a" for append
// default mode is "rw"

// to read a line you may use Stdio.File()->gets() or get a line_iterator() and
// read lines from it.

object LOGFILE = logfile->line_iterator();
do
{
  string line=LOGFILE->value();
}
while(LOGFILE->next())
logfile->close();

// or use foreach as shown above.

// write() is actually a shortcut for Stdio.stdout->write()
// you could get yourself a different shortcut by assigning that to a variable:

function write = logfile->write;     //  switch to LOGFILE for write();
write("Countdown initiated ...\n");
write = Stdio.stdout->write;         //  return to stdout
write("You have 30 seconds to reach minimum safety distance.\n");

// Stdio.File is unbuffered. a buffered version is provided by Stdio.FILE
```

### Opening a File

```pike
// use Stdio.read_file(), Stdio.write_file() and Stdio.append_file() for
// convenience, or Stdio.File for precision and to get a filehandle.

string path;

// open file for reading
string file = Stdio.read_file(path);
Stdio.File file = Stdio.File(path, "r");

// open file for writing, create new file if needed, or else truncate old file
Stdio.write_file(path, "content");
Stdio.File file = Stdio.File(path, "wc");

// same with setting access permissions
Stdio.write_file(path, "content", 0600);
Stdio.File file = Stdio.File(path, "wc", 0600);

// open file for writing, create new file, file must not exist
if(!file_stat(path))
  Stdio.write_file(path, "content");
Stdio.File file = Stdio.File(path, "wcx");

if(!file_stat(path))
  Stdio.write_file(path, "content", 0600);
Stdio.File file = Stdio.File(path, "wcx", 0600);

// open file for appending, create if necessary
Stdio.append_file(path, "content");
Stdio.File file = Stdio.File(path, "wac");

Stdio.append_file(path, "content", 0600);
Stdio.File file = Stdio.File(path, "wac", 0600);

// open file for appending, file must exist
Stdio.File file = Stdio.File(path, "wacx");

// open file for update, file must exist
string file = Stdio.read_file(path);
string updated = file+"foo"  // update contents of file
Stdio.write_file(path, updated);

Stdio.File file = Stdio.File(path);          // this is the default operation

// open file for update, file must not exist
Stdio.File file = Stdio.File(path, "rwcx");

```

### Opening Files with Unusual Filenames

```pike
// since the filename is contained in a string, this problem does not apply
```

### Expanding Tildes in Filenames

```pike
string filename;

if(filename[0] == "~")
{
  string user, path, home;
  [ user, path ] = array_sscanf(filename, "~%[^/]%s");
  if(user == "")
    home = getenv("HOME") || getenv("LOGDIR") || getpwuid(geteuid())[5];
  else
    home = getpwnam(user)[5];
  filename = home+path;
}
```

### Making Perl Report Filenames in Errors

```pike
string path = "/tmp/fooo";
mixed error = catch
{
  Stdio.File file = Stdio.File(path, "r");
};

if(error)
{
  werror("Couldn't open %s for reading:\n", path);
  werror(error[0]);
}
// Couldn't open /tmp/fooo for reading:
// Failed to open "/tmp/fooo" mode "r" : No such file or directory
```

### Creating Temporary Files

```pike
Stdio.File fh;
string name;
do
{
  name = "/tmp/"+MIME.encode_base64(random_string(10));
  fh = Stdio.File(name, "rwcx");
}
while(!fh)

atexit(lambda(){ fh->close(); rm(name); });


// if you don't really need the file to be on disk (or if /tmp is a ramdisk)
// but you need an object that behaves like a file, then use Stdio.FakeFile

fh = Stdio.FakeFile();

// and use fh like any other filehandle.

```

### Storing Files Inside Your Program Text

```pike
// since the usual way to handle files is to read them into a string, then just
// assign your data to a string and work from there:

string data = "your data goes here";


// or for convenient multiline data:

string data = #"your data goes here
and here
and ends here";


// or use Stdio.FakeFile for a Stdio.File compatible interface
// see 7.5

//-----------------------------------------------------------------

object stat = file_stat(__FILE__);
int raw_time = stat->ctime;
int size     = stat->size;
int kilosize = size/1024;

write("<P>Script size is %dk\n", kilosize);
write("<P>Last script update: %s\n", Calendar.Second(raw_time)->format_nicez());

```

### Writing a Filter

### Modifying a File in Place with Temporary File

### Modifying a File in Place with -i Switch

### Modifying a File in Place Without a Temporary File

### Locking a File

### Flushing Output

### Reading from Many Filehandles Without Blocking

### Doing Non-Blocking I/O

### Determining the Number of Bytes to Read

### Storing Filehandles in Variables

### Caching Open Output Filehandles

### Printing to Many Filehandles Simultaneously

### Opening and Closing File Descriptors by Number

### Copying Filehandles

### Program: netlock

### Program: lockarea