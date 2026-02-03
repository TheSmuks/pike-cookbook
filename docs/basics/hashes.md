---
id: hashes
title: Hashes
sidebar_label: Hashes
---

## Introduction

```pike
// creating a mapping from arrays
mapping age = mkmapping( ({ "Nat", "Jules", "Josh", }), ({ 24, 25, 17 }) );

// initialize one index at a time
mapping age = ([]);
age["Nat"] = 24;
age["Jules"] = 25;
age["Josh"] = 17;

// if your index names are valid identifiers:
age->Nat = 24;
age->Jules = 25;
age->Josh = 17;

// the traditional way to initialize mappings
mapping age = ([ "Nat":24, "Jules":25, "Josh":17 ]);

mapping(string:string) food_color = ([
                                      "Apple":"red",
                                      "Banana":"yellow",
                                      "Lemon":"yellow",
                                      "Carrot":"orange"
                                     ]);

// a index may be of any type
mapping any = ([ "1":"a string", 1:"an int", 1.0:"a float" ]);

// you may use other types too, but be aware that they are matched by
// reference, and not by value.
```

## Adding an Element to a Hash

```pike
// simplest way to add an element to a mapping:
mapping age = ([ "Nat":24 ]);
age["Jules"] = 25;
age->Josh = 17;

// you can also use the assign function:
mapping new_age = age + ([ "Steve":35 ]);

// m_add() is deprecated
// in Pike 7.7+ use the + operator
```

## Testing for the Presence of a Key in a Hash

```pike
// an undefined value in a mapping gets turned to 0.
// assigning 0 as a value is allowed and will not remove the index.
// checking for the index will of course return 0 and be interpreted as false.
// to check if the index is really there, use zero_type()

if(!zero_type(mapping->index))
{
  // it exists
}
else
{
  // it doesn't
}

// food_color as per section 5.0
foreach( ({ "Banana", "Milk" }) ;; string name)
{
  if(!zero_type(food_color[name]))
    write("%s is a food.\n", name);
  else
    write("%s is a drink.\n", name);
}
// Banana is a food.
// Milk is a drink.

// ---------------------------------------------------------
mapping age = ([ "Toddler":3,
                 "Unborn":0,
                 "Newborn":0.0,
                 "Phantasm":UNDEFINED ]);

foreach( ({ "Toddler", "Unborn", "Newborn", "Phantasm", "Relic"});; string thing)
{
    write(thing+":");
    if(!zero_type(age[thing]))
      write(" Exists");
    if(age[thing])
      write(" True");
    write("\n");
}
// Toddler: Exists True
// Unborn: Exists
// Newborn: Exists True
// Phantasm: Exists
// Relic:

// age->Toddler exists, because zero_type() is only true if the index is not in
// the mapping. it is true because the value is not 0.
// age->Unborn exists, but is false because 0 is false
// age->Newborn exists and is true, because 0.0 is not false
// age->Phantasm exists and is false, like Unborn
// age->Relic does not exist

// we can not test for defined. UNDEFINED is a special value used internally by
// the compiler. it gets converted to 0 as soon as it is assigned in a mapping

// however we can create something equivalent that can be treated like any
// other value, except that it is false:

class Nil
{
  // this is a minimal example.
  // a more complete one would also handle casting

  int `!() {return 1;}
  string _sprintf() {return "Nil";}

  // we could have this function externally, but this is more convenient
  int defined(mixed var)
  {
    return !zero_type(var) && var!=this;
  }
}

Nil NIL = Nil();                    // create an instance so we can use it
function defined = NIL->defined;  // just for symetry

mapping age = ([ "Toddler":3,
                 "Unborn":0,
                 "Phantasm":NIL ]);
```

## Deleting from a Hash

```pike
// users occasionally may get the idea that mapping[index]=0; may remove index
// from mapping. the normal way to remove a index from a mapping is to
// subtract: mapping -= ([ index:0 ]); the following shall demonstrate the
// difference between subtracting a index and assigning 0 to it.

// food_color as per section 5.0
void print_foods()
{
  write("Foods:%{ %s%}\n", indices(food_color));
  write("Values: ");

  foreach(food_color; string food; string color)
  {
    if(color)
      write(color+" ");
    else
      write("(no value) ");
  }
  write("\n");
}

write("Initially:\n");
print_foods();

write("\nWith Banana set to 0\n");
food_color->Banana = 0;
print_foods();

write("\nWith Banana deleted\n");
food_color -= ([ "Banana":"the value is irrelevant" ]);
print_foods();

// Initially:
// Foods: Lemon Banana Apple Carrot
// Values: yellow yellow red orange
//
// With Banana set to 0
// Foods: Banana Lemon Apple Carrot
// Values: (no value) yellow red orange
//
// With Banana deleted
// Foods: Lemon Carrot Apple
// Values: yellow orange red

// you can also subtract multiple indices:
food_color -= ([ "Banana":0, "Apple":0, "Cabbage":0 ]);

// note that subtracting a mapping from another creates a new mapping.
// thus any references you have to a mapping will be broken.
// in most cases this is what you want anyways. if it is not, you can also
// remove indices using m_delete();

m_delete(food_color, "Banana");
```

## Traversing a Hash

```pike
foreach( mapping; type index; type value)
{
  //do something with index and value
}

// food_color as per 5.0
foreach(food_color; string food; string color)
{
  write("%s is %s.\n", food, color);
}
```

## Printing a Hash

```pike
// since mappings are not ordered, printing them directly can result in
// seemingly random output:

mapping age = ([ "Nat":24, "Jules":25, "Josh":17 ]);
write(age); // ([ "Josh":17, "Jules":25, "Nat":24 ])

// to get consistent output you can sort the indices:
write(sprintf("%{ %s:%s%}", sort(indices(age))..., age));

// if you want a specific order, you can specify it:
write("Nat:%d, Jules:%d, Josh:%d\n", age->Nat, age->Jules, age->Josh);

// or
array(string) names = ({ "Nat", "Jules", "Josh" });
foreach(names; int i; string name)
  write("%s:%d\n", name, age[name]);

// this will always print:
// Nat:24
// Jules:25
// Josh:17

// for food_color, which maps to another string, you could write:
foreach(food_color; string food; string color)
  write("%s: %s\n", food, color);
```

## Retrieving from a Hash in Insertion Order

```pike
// Pike mappings do not preserve insertion order, but you can simulate it by
// keeping a separate array of keys in the order you want:

mapping(string:string) food_color = ([]);
array(string) insertion_order = ({});

void add_food(string food, string color)
{
  food_color[food] = color;
  insertion_order += ({ food });
}

// now you can retrieve in insertion order:
foreach(insertion_order; string food)
  write("%s: %s\n", food, food_color[food]);
```

## Hashes with Multiple Values Per Key

```pike
// there are several ways to handle multiple values per key:

// 1. using arrays as values
mapping(string:array(int)) ages = ([]);

void add_age(string name, int age)
{
  if(!ages[name]) ages[name] = ({});
  ages[name] += ({ age });
}

// 2. using a multiset
mapping(string:multiset(int)) age_set = ([]);

void add_age(string name, int age)
{
  if(!age_set[name]) age_set[name] = (< >);
  age_set[name][age] = 1;
}

// 3. using a custom class
class AgeList
{
  array(int) ages = ({});

  void add(int age) { ages += ({ age }); }
  array(int) get() { return ages; }
}

mapping(string:AgeList) age_lists = ([]);

void add_age(string name, int age)
{
  if(!age_lists[name]) age_lists[name] = AgeList();
  age_lists[name]->add(age);
}
```

## Inverting a Hash

```pike
// to invert a hash (swap keys and values):
mapping(string:string) food_color = ([
  "Apple":"red", "Banana":"yellow",
  "Lemon":"yellow", "Carrot":"orange"
]);

mapping(string:array(string)) color_foods = ([]);

foreach(food_color; string food; string color)
{
  if(!color_foods[color]) color_foods[color] = ({});
  color_foods[color] += ({ food });
}

// resulting structure:
// ([ "red":({ "Apple" }), "yellow":({ "Banana", "Lemon" }),
//    "orange":({ "Carrot" }) ])

// for one-to-one mappings, you can use:
mapping inverted = mkmapping(values(food_color), indices(food_color));
```

## Sorting a Hash

```pike
// to get the keys of a hash sorted:
mapping age = ([ "Nat":24, "Jules":25, "Josh":17 ]);
array(string) sorted_names = sort(indices(age));

// to sort by values:
array(int) sorted_ages = sort(values(age));

// to sort by keys with custom comparison:
array(string) names = ({ "Josh", "Nat", "Jules" });
sorted_names = sort(names, lambda(string a, string b) {
  return sizeof(a) - sizeof(b);
});

// to sort the entire mapping by keys:
mapping sorted_by_key = ([]);
foreach(sort(indices(age)), string name)
  sorted_by_key[name] = age[name];

// to sort by values (descending):
mapping sorted_by_value = ([]);
array(int) ages = sort(values(age));
foreach(reverse(ages), int age) {
  foreach(age; string name; int value)
    if(value == age)
      sorted_by_value[name] = age;
}
```

## Merging Hashes

```pike
// in Pike 7.7+ you can use the + operator:
mapping age1 = ([ "Nat":24, "Jules":25 ]);
mapping age2 = ([ "Josh":17, "Steve":35 ]);
mapping combined = age1 + age2;

// duplicate keys will take the value from the second mapping
// values from age2 will overwrite values from age1

// to merge without overwriting, you can:
mapping merge_safe = ([]);
foreach(age1; string key; mixed val)
  merge_safe[key] = val;
foreach(age2; string key; mixed val)
  if(!merge_safe[key])
    merge_safe[key] = val;

// for Pike 7.6 and earlier, use:
mapping combined = age1 + ([ "Josh":17, "Steve":35 ]);
```

## Finding Common or Different Keys in Two Hashes

```pike
mapping age1 = ([ "Nat":24, "Jules":25, "Josh":17 ]);
mapping age2 = ([ "Jules":26, "Steve":35, "Josh":17 ]);

// common keys:
array(string) common = intersect(indices(age1), indices(age2));

// keys only in first mapping:
array(string) only_in_first = difference(indices(age1), indices(age2));

// keys only in second mapping:
array(string) only_in_second = difference(indices(age2), indices(age1));

// symmetric difference (keys in either but not both):
array(string) unique = symmetric_difference(indices(age1), indices(age2));

// to get key-value pairs from both mappings:
mapping both = ([]);
foreach(common; string key)
  both[key] = ({ age1[key], age2[key] });

// where both[key] = ({ value_from_age1, value_from_age2 })
```

## Hashing References

```pike
// in Pike, hash keys are compared by reference, not by value:
class Person
{
  string name;
  void create(string n) { name = n; }
}

Person p1 = Person("Alice");
Person p2 = Person("Alice");

mapping people = ([ p1:"found", p2:"not found" ]);
// both entries exist because p1 and p2 are different objects

// to use value-based comparison, create a custom hash:
class PersonHash
{
  inherit Stdio.HashTable;

  int key(object p) { return p->hash(); }

  int equal(object a, object b)
  {
    return a->name == b->name;
  }
}
```

## Presizing a Hash

```pike
// mappings in Pike auto-grow as needed, but you can preallocate:
mapping age = allocate_mapping(100);

// or for a more precise estimate:
mapping age = ([]);
if(sizeof(keys) > 0)
  age = allocate_mapping(sizeof(keys));

// the estimated size helps optimize memory usage for large mappings
```

## Finding the Most Common Anything

```pike
// to find the most common item in an array:
array(string) items = ({ "a", "b", "a", "c", "b", "a" });
mapping count = ([]);

foreach(items; string item)
  count[item]++;

string most_common = indices(count)[0];
foreach(count; string item; int cnt)
  if(cnt > count[most_common])
    most_common = item;

// more concise version:
mapping counts = aggregate_mapping(@(array(int))mapping_create(@items), 0);
counts++;
string most_common = max(@indices(counts), lambda(string a, string b) {
  return counts[a] - counts[b];
});
```

## Representing Relationships Between Data

```pike
// using mappings to represent relationships:
mapping(string:array(string)) friends = ([]);

void add_friend(string person, string friend)
{
  if(!friends[person]) friends[person] = ({});
  if(!friends[friend]) friends[friend] = ({});

  if(!has_value(friends[person], friend))
    friends[person] += ({ friend });
  if(!has_value(friends[friend], person))
    friends[friend] += ({ person });
}

// checking relationships:
bool are_friends(string a, string b)
{
  return friends[a] && has_value(friends[a], b);
}

// friend of a friend:
array(string) friends_of_friends(string person)
{
  array(string) result = ({});
  foreach(friends[person] || ({}); string friend)
    foreach(friends[friend] || ({}); string fof)
      if(fof != person && !has_value(friends[person], fof))
        result += ({ fof });
  return result;
}
```

## Program: dutree

```pike
// dutree - directory tree analyzer
// usage: pike dutree.pike [directory]

#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/stat.h>

mapping file_stats = ([]);

void scan_directory(string dir, int level)
{
  DIR *d;
  struct dirent *entry;
  struct stat st;

  if(!(d = opendir(dir)))
    return;

  while((entry = readdir(d)))
  {
    if(entry->d_name[0] == '.') continue;

    string path = dir + "/" + entry->d_name;
    if(lstat(path, &st))
      continue;

    if(S_ISDIR(st.st_mode))
    {
      printf("%*s%s/\n", level * 2, "", entry->d_name);
      scan_directory(path, level + 1);
    }
    else
    {
      printf("%*s%s\n", level * 2, "", entry->d_name);
      file_stats[path] = st.st_size;
    }
  }

  closedir(d);
}

int main(int argc, string|array argv)
{
  string dir = argc > 1 ? argv[1] : ".";
  printf("Directory tree for %s:\n", dir);
  scan_directory(dir, 0);

  if(sizeof(file_stats))
  {
    int total = aggregate(@values(file_stats));
    printf("\nTotal files: %d\n", sizeof(file_stats));
    printf("Total size: %d bytes\n", total);
  }

  return 0;
}
```

## Modern Mapping Operations in Pike 8

```pike
// Pike 8 introduces more mapping operations:

// filter() - create new mapping with filtered key-value pairs
mapping age = ([ "Nat":24, "Jules":25, "Josh":17 ]);
mapping adults = filter(age, lambda(string name, int age) { return age >= 18; });

// map() - transform values
mapping age_doubled = map(age, lambda(int age) { return age * 2; });

// reduce() - reduce values to single value
int sum_age = reduce(values(age), lambda(int a, int b) { return a + b; });

// any() and all() - check conditions
bool has_adult = any(age, lambda(int age) { return age >= 18; });
bool all_adult = all(age, lambda(int age) { return age >= 18; });

// unzip() - split mapping into two arrays
array(array) split = unzip(age);
// split[0] is keys, split[1] is values
```

## Mapping.pmod Utilities

```pike
// the Mapping.pmod module provides many utilities:

#include <Mapping.pmod>

// merge_mappings() - merge multiple mappings
mapping m1 = ([ "a":1, "b":2 ]);
mapping m2 = ([ "c":3, "d":4 ]);
mapping merged = Mapping()->merge_mappings(m1, m2);

// filter_mapping() - filter by key or value
mapping filtered = Mapping()->filter_mapping(age, lambda(int age) { return age > 20; });

// mapping_search() - find key by value
string name = Mapping()->mapping_search(age, 24); // returns "Nat"

// invert_mapping() - simple inversion
mapping inverted = Mapping()->invert_mapping(food_color);
```

## Safe Indexing with ->?

```pike
// Pike 8 introduces safe indexing operator ->?
mapping age = ([ "Nat":24, "Jules":25 ]);

// safe access - returns UNDEFINED if key doesn't exist
int nat_age = age->?"Nat"; // 24
int josh_age = age->?"Josh"; // UNDEFINED

// safe nested access
mapping nested = ([ "user": ([ "name": "Alice", "age": 25 ]) ]);
string name = nested->?"user"->?"name"; // "Alice"
string email = nested->?"user"->?"email"; // UNDEFINED

// conditional chaining
int user_age = nested->?"user" && nested->user->?"age"; // 25
```

## Advanced Hash Patterns

```pike
// memoization pattern:
class Memoizer
{
  mapping cache = ([]);

  mixed execute(function f, mixed ... args)
  {
    string key = sprintf("%O", args);
    if(cache[key]) return cache[key];

    mixed result = f(@args);
    cache[key] = result;
    return result;
  }
}

// cache decorator:
function cache_results(function f)
{
  mapping cache = ([]);
  return lambda(mixed ... args) {
    string key = sprintf("%O", args);
    if(cache[key]) return cache[key];
    return cache[key] = f(@args);
  };
}

// singleton pattern:
class Singleton
{
  static private Singleton instance;
  private void create() {}

  static Singleton get()
  {
    if(!instance) instance = Singleton();
    return instance;
  }
}

// observer pattern:
class Observable
{
  mapping observers = ([]);

  void add_observer(string event, function callback)
  {
    if(!observers[event]) observers[event] = ({});
    observers[event] += ({ callback });
  }

  void notify(string event, mixed ... data)
  {
    if(observers[event])
      foreach(observers[event]; function cb)
        cb(@data);
  }
}
```