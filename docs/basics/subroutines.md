---
id: subroutines
title: Subroutines
sidebar_label: Subroutines
---

## Introduction

```pike
#pragma strict_types
// Here, in this simple example, 'greeted', is used as a 'global'
// variable. In a more complex program, however, this would not be
// the case [subsequent sections exlain why]

int greeted;

// ----

void hello()
{
  write("hi there!, this procedure has been called %d times\n", ++greeted);
}

int how_many_greetings()
{
  return greeted;
}

// ------------

int main()
{
  hello();
  int greetings = how_many_greetings();
  write("bye there!, there have been %d greetings so far\n", greetings);
}

// ----------------------------

// Alternate means of defining functions [could, optionally, have also
// included type information in 'function' declaration]; could also
// have been done within scope of 'main'

int greeted;

// ----

function hello = lambda()
  {
    write("hi there!, this procedure has been called %d times\n", ++greeted);
  };

function how_many_greetings = lambda() { return greeted; };

// ------------

int main()
{
  hello();
  int greetings = how_many_greetings();
  write("bye there!, there have been %d greetings so far\n", greetings);
}
```

## Accessing Subroutine Arguments

```pike
#pragma strict_types
// Subroutine parameters are named, that is, access to these items from
// within a function is reliant on their being named in the parameter
// list [together with mandatory type information], something which is
// in line with many other commonly-used languages

float hypotenuse(float side1, float side2)
{
  // Arguments passed to this function are accessable as, 'side1',
  // and 'side2', respectively, and each is expected to be a 'float'
  // type

  return side1 * side1 + side2 * side2;
}

// ----
// 'side1' -> 3.0
// 'side2' -> 4.0

float diag = hypotenuse(3.0, 4.0);

// ------------

// However, Pike also allows parameters [and return types where applicable]:
// * To have one of a set of types [see (1)]
// * To have a generic type [see (2)]
// * To be optional, in which case any arguments are packaged as an
//   array, and array notation needed to access each item [see (3)]

// (1). Here the function will accept either 'int' or 'float'
// arguments, and perform runtime type checking to identify what is
// supplied

float hypotenuse(int|float side1, int|float side2)
{
  // If 'int' arguments passed. convert to 'float'
  float s1 = intp(side1) ? (float) side1 : side1;
  float s2 = intp(side2) ? (float) side2 : side2;

  return s1 * s1 + s2 * s2;
}

// ----
// Both are legal calls

float diag = hypotenuse(3.0, 4.0);
float diag = hypotenuse(3, 4);

// ------------

// (2). Here the function still expects to be called with two arguments
// but each may be of *any* type [admittedly a very contrived example
// of little utility except for illustrative value]. Such a function
// is almost entirely reliant on careful runtime type checking if it
// is to behave reliably

float hypotenuse(mixed side1, mixed side2)
{
  if (stringp(side1)) { ... }
  if (arrayp(side1)) { ... }
  if (objectp(side1)) { ... }
}

// ----
// All are legal calls

float diag = hypotenuse(3.0, 4.0);
float diag = hypotenuse(3, 4);
float diag = hypotenuse("3", "4");
float diag = (({3}), ({4}));

// ------------

// (3). Here, the function is defined to accept two, mandatory
// parameters [still accessable via name], then a set of zero or more
// optional parameters, which are accessable within the function body
// via an array [the placeholder, 'args', represents an array of zero
// or more elements each corresponding to one of the passed arguments

float hypotenuse(float side1, mixed side2, mixed ... args)
{
  // Mandatory parameters still accessable as usual
  ... side1 ... side2 ...

  // Total number of arguments passed to function determinable via:
  int total_passed_args = query_num_arg();

  // 'args' contains all optional arguments: 0 - N
  int optional_args = sizeof(args);

  // Process variable arguments ...
  foreach(args, mixed arg)
  {
    ... if (strinp(arg)) { ... }
  }

  ...
}

// ----
// All are legal calls

float diag = hypotenuse(3.0, 4.0);
float diag = hypotenuse(3.0, 4.0, "a");
float diag = hypotenuse(3.0, 4.0, lambda(){ return 5; }, "fff");
float diag = hypotenuse(3.0, 4.0, 1, "x", ({ 6, 7, 9 }));

// ----------------------------

// Modifies copy
array(int|float) int_all(array(int|float) arr)
{
  array(int|float) retarr = copy_value(arr);
  int i; for(int i; i < sizeof(retarr); ++i) { retarr[i] = (int) arr[i]; }
  return retarr;
}

// Modifies original

array(int|float) trunc_all(array(int|float) arr)
{
  int i; for(int i; i < sizeof(arr); ++i) { arr[i] = (int) arr[i]; }
  return arr;
}

// ----

array(int|float) nums = ({1.4, 3.5, 6.7});

// Copy modified - 'ints' and 'nums' separate arrays
array(int|float) ints = int_all(nums);
write("%O\n", nums);
write("%O\n", ints);

// Original modified - 'ints' acts as alias for 'nums'
ints = trunc_all(nums);
write("%O\n", nums);
write("%O\n", ints);
```

## Making Variables Private to a Function

```pike
#pragma strict_types

void some_func()
{
  // Variables declared within a function are local to that function
  mixed variable = something;
}

// ----------------------------

// Assuming these are defined at file level, that is, outside of 'main'
// or any other function they are accessable by every other member of
// the same file [and if this file (read: class or program) is the
// only one comprising the 'system', they are effectively 'global']

string name = argv[1]; int age = (int) argv[2];

int c = fetch_time();

int condition;

// ------------

int run_check()
{
  ...
  condition = 1;
}

int check_x(int x)
{
  string y = "whatever";

  // Whilst 'run_check' has access to 'name', 'age', and 'c' [because
  // these are declared at a higher scope], it does not have access to
  // 'y' or any other locally defined variable
  run_check();

  // 'run_check' will have updated 'condition'
  if (condition) write("got x: %d\n", x);
}
```

## Creating Persistent Private Variables

```pike
#pragma strict_types
// Pike does not implement C style 'static' variables [i.e. persisent
// local variables], nor does it implement C++ style 'class variables'
// [oddly enough, also implemented in C++ via use of the 'static'
// keyword], both of which could be used to implement solutions to the
// problems presented in this section. Also, there is no direct
// equivalent to Perl's 'BEGIN' block [closest equivalent is the
// class 'create' method]. So, to solve a problem like implementing a
// 'counter':

// * Use Pike's OOP facilities [simple, natural]
// * Use closures [somewhat unwieldly, but possible]

// OOP Approach
class Counter
{
  private int counter;

  static void create(int start) { counter = start; }
  public int next() { return ++counter; }
  public int prev() { return --counter; }
}

// ----

int main()
{
  Counter counter = Counter(42);

  write("%d\n", counter->next());
  write("%d\n", counter->prev());
}

// ----------------------------

// A refinement of the previous implementation that mimics 'static'
// variables

class Static
{
  // 'static' variable that is shared by all instance of 'Counter'
  int counter;

  class Counter
  {
    public int next() { return ++counter; }
    public int prev() { return --counter; }
  }

  Counter make() { return Counter(); }

  public void create(int counter_) { counter = counter_; }
}

// ----

int main()
{
  Static mkst = Static(42);

  Static.Counter counter_1 = mkst->make();
  Static.Counter counter_2 = mkst->make();

  // Same value of, 'counter', is accessed by each object
  write("%d\n", counter_1->next());
  write("%d\n", counter_1->next());

  write("%d\n", counter_2->next());
  write("%d\n", counter_2->prev());
}

// ----------------------------

// Closure Approach [Admittedly somewhat contrived: a Scheme overdose ;) !]

function(string : function(void : int)) make_counter(int start)
{
  int counter = start;
  int next_counter() { return ++counter; };
  int prev_counter() { return --counter; };

  return
    lambda(string op)
    {
      if (op == "next") return next_counter;
      if (op == "prev") return prev_counter;
      return 0;
    };
}

int main()
{
  function(string : function(void : int)) counter = make_counter(42);

  function(void : int) next = counter("next");
  function(void : int) prev = counter("prev");

  write("%d\n", next());
  write("%d\n", next());
  write("%d\n", prev());
  write("%d\n", prev());
}
```