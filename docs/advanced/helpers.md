---
id: helpers
title: Helpers
sidebar_label: Helpers
---

## Introduction

```pike
// (this section is optional; use it if you need to import very
// generic stuff for the whole code)
//
// Note: To avoid clutter each example will only include any necessary
// code. However, it should be understood that:
//
// * The following constants need to be defined:
//
//   constant FALSE = 0, TRUE = 1, PROBLEM = 1, OK = 0,
//     EOF = -1, NULL = "", NEWLINE = "\n", LF = 10, SPACE = 32;
//
// * Each example needs to be enclosed within the following block:
//
//   int main(int argc, array(string) argv)
//   {
//     ...
//   }
//
//   where a 'main' is not provided. Also:
//
//   - Any function definitions would ordinarily be placed
//     before, and outside of, 'main'
//   - Variables can be assumed to be locals residing in 'main';
//     any 'global' variables will be defined at the start of the
//     code example prior to any function definitions

// ----------------------------
```

```pike
string chop(string s, void|int size)
{
  int length = sizeof(s);
  return size > 0 && size < length ? s[..length - (size + 1)] : s;
}
```

> **Note**: This is a simple helper function that removes characters from the end of a string. If `size` is not specified or 0, it returns the original string. If `size` is specified, it removes that many characters plus one (so `chop(s, 1)` removes the last 2 characters).