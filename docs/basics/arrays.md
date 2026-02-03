---
id: arrays
title: Arrays
sidebar_label: Arrays
---

## Introduction

```pike
// nested arrays are supported
array flat = ({ "this", "that", "the", "other" });
array nested = ({ "this", "that", ({ "the", "other" }) });
array tune = ({ "The", "Star-Spangled", "Banner" });
tune[0];
// Result: "The"
tune[1];
// Result: "Star-Spangled"
// the typing may be more specific
// only strings allowed in the array (thus no nesting!)
array(string) flat = ({ "this", "that", "the", "other" });
// allow one level of nesting
array(string|array(string)) admit1 = ({ "this", "that", ({ "the", "other" }) });
// the first level may only contain arrays, other levels may contain anything
array(array) require1 ({ ({ "this", "that" }), ({ "the", "other" }) });
```


## Specifying a List In Your Program

```pike
// list
array(string) a = ({ "quick", "brown", "fox" });
// words
array(string) a = "Why are you teasing me?"/" ";
// lines
array(string) lines = #"The boy stood on the burning deck,
It was as hot as glass."/"\n";
// file
array(string) bigarray = Stdio.read_file("mydatafile")/"\n";
// the quoting issues do not apply.
array(string) ships = "Niña Pinta Santa María"/" ";         // wrong
array(string) ships = ({ "Niña", "Pinta", "Santa María" }); // right
```


## Printing a List with Commas

```pike
// download the following standalone program
#!/usr/bin/pike
// chapter 4.2
// commify_series - show proper comma insertion in list output
array(array(string)) lists =
({
({ "just one thing" }),
({ "Mutt", "Jeff" }),
({ "Peter", "Paul", "Mary" }),
({ "To our parents", "Mother Theresa", "God" }),
({ "pastrami", "ham and cheese", "peanut butter and jelly", "tuna" }),
({ "recycle tired, old phrases", "ponder big, happy thoughts" }),
({ "recycle tired, old phrases",
"ponder big, happy thoughts",
"sleep and dream peacefully" }),
});
void main()
{
write("The list is: %s.\n", commify_list(lists[*])[*]);
}
string commify_list(array(string) list)
{
switch(sizeof(list))
{
case 1: return list[0];
case 2: return sprintf("%s and %s", @list);
default:
string seperator=",";
int count;
while(count<sizeof(list) && search(list[count], seperator)==-1)
count++;
if(count<sizeof(list))
seperator=";";
return sprintf("%{%s"+seperator+" %}and %s",
list[..sizeof(list)-2], list[-1]);
}
}
```


## Changing Array Size

```pike
void what_about_that_array(array list)
{
write("The array now has %d elements.\n", sizeof(list));
write("The index of the last element is %d.\n", sizeof(list)-1);
write("Element #3 is %O.\n", list[3]);
}
array people = ({ "Crosby", "Stills", "Nash", "Young" });
what_about_that_array(people);
// The array now has 4 elements.
// The index of the last element is 3.
// Element #3 is "Young".
people=people[..sizeof(people)-2];
what_about_that_array(people);
// The array now has 3 elements.
// The index of the last element is 2.
// Index 3 is out of array range -3..2.
people+=allocate(10001-sizeof(people));
what_about_that_array(people);
// The array now has 10001 elements.
// The index of the last element is 10000.
// Element #3 is 0.
array people = ({ "Crosby", "Stills", "Nash", "Young" }); // resetting the array
people[10000]=0;
// Index 10000 is out of array range -4..3.
// accessing a nonexisting index is always an error.
// arrays can not be enlarged this way.
```


## Doing Something with Every Element in a List

```pike
foreach(list; int index; mixed item)
{
// do something with item (and possibly index)
}
foreach(bad_users;; object user)
{
complain(user);
}
// for such simple cases pike provides a convenient automap feature:
complain(bad_users[*]);
// will do the same as the foreach above.
foreach(sort(indices(getenv()));; string var)
{
write("%s=%s\n", var, getenv(var));
}
// if you don't need an assurance that the indices are sorted (they most likely
// are sorted anyways) you may use:
foreach(getenv(); string var; string value)
{
write("%s=%s\n", var, value);
}
foreach(all_users;; string user)
{
int disk_space = get_usage(user);
if(disk_space > MAX_QUOTA)
complain(user);
}
// continue; to jump to the next
// break; to stop the loop
// redo can be done by doing a loop with the proper checks in the block
object pipe=Stdio.File();
Process.create_process(({ "who" }), ([ "stdout":pipe->pipe() ]));
foreach(pipe->line_iterator();; string line)
{
if(search(line, "tchrist")>-1)
write(line+"\n");
}
object fh=Stdio.File("somefile");
foreach(fh->line_iterator(); int linenr; string line)
{
foreach(Process.split_quoted_string(line);; string word)//split on whitespace
{
write(reverse(word));
}
}
array(int) list = ({ 1,2,3 });
foreach(list;; int item)
{
item--;
}
write("%{%d %}\n", list);
// Result: 1 2 3
// we can still use foreach instead of for,
// because foreach gives us the index as well:
foreach(list; int index;)
{
list[index]--;
}
write("%{%d %}\n", list);
// Result: 0 1 2
array a = ({ 0.5, 3 });
array b = ({ 0, 1 });
// foreach handles only one array so there is nothing to gain here.
// better use automap:
array a_ = a[*]*7;
array b_ = b[*]*7;
write("%{%O %}\n", a_+b_);
// 3.500000 21 0 7
string scalar = " abc ";
array(string) list = ({ " a ", " b " });
mapping(mixed:string) hash = ([ "a":" a ", "b":" b " ]);
scalar = String.trim_whites(scalar);
list = String.trim_whites(list[*]);
foreach(hash; int key;)
{
hash[key]=String.trim_whites(hash[key]);
}
```


## Iterating Over an Array by Reference

```pike
// pike does not distinguish between arrays and array references
// (they are all references anyways) so this section does not apply
```


## Extracting Unique Elements from a List

```pike
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
if(!seen[item])
seen[item] = 1;
else
uniq += ({ item });
}
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
if(!seen[item]++)
uniq += ({ item });
}
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
if(!seen[item]++)
some_func(item);
}
// the following is probably the most natural for pike
mapping seen = ([]);
array   uniq = ({});
foreach(list;; mixed item)
{
seen[item]++;
}
uniq = indices(seen);
// not necessarily faster but shorter:
array uniq = indices(({ list[*],1 }));
// also short, and preserving the originaal order:
array uniq = list&indices(({ list[*],1 }));
object pipe = Stdio.File();
Process.create_process(({ "who" }), ([ "stdout":pipe->pipe() ]));
mapping ucnt = ([]);
foreach(pipe->line_iterator();; string line)
{
ucnt[(line/" ")[0]]++;
}
array users = sort(indices(ucnt));
write("users logged in: %s\n", users*" ");
```


## Finding Elements in One Array but Not Another

```pike
// one of pikes strenghts are operators.
// the following are the only idiomatic solutions to the problem
array A = ({ 1, 2, 3 });
array B = ({ 2, 3, 4 });
array aonly = A-B;
// Result: ({ 1 });
```


## Computing Union, Intersection, or Difference of Unique Lists

```pike
array a = ({ 1, 3, 5, 6, 7, 8 });
array b = ({ 2, 3, 5, 7, 9 });
// union:
array union = a|b;
// ({ 1, 3, 5, 6, 7, 8, 2, 9 })
// intersection
array intersection = a&b;
// ({ 3, 5, 7 })
// difference
array difference = a-b;
// ({ 1, 6, 8 })
// symetric difference
array symdiff= a^b;
// ({ 1, 6, 8, 2, 9 })
```


## Appending One Array to Another

```pike
// join arrays
// appending to an array will always create a new array and pike is designed to
// handle this efficiently.
array members = ({ "Time", "Flies" });
array initiates = ({ "An", "Arrow" });
members += initiates;
// members is now ({ "Time", "Flies", "An", "Arrow" })
members = members[..1]+({ "Like" })+members[2..];
write("%s\n", members*" ");
members[0] = "Fruit";
members = members[..sizeof(members)-3]+({ "A", "Banana" });
write("%s\n", members*" ");
// Time Flies Like An Arrow
// Fruit Flies Like A Banana
```


## Reversing an Array

```pike
// almost any operation you do on the elements will add more overhead than
// reversing the array, if there is any possible optimization, pike will do it
// for you.
array reversed = reverse(arr);
// unless you were going to use for anyways then foreach(reverse( ...)) is
// preferable.
foreach(reverse(arr);; mixed item)
{
// do something with item
}
for(int i=sizeof(arr)-1; i<=0; i--)
{
// so something with arr[i]
}
array ascending = sort(users);
array descending = reverse(sort(users));
// reverse(sort()) is faster by a magnitude
array descending = Array.sort_array(users, lambda(mixed a, mixed b)
{
return a<b;
}
);
```


## Processing Multiple Elements of an Array

```pike
array arr = ({ 0,1,2,3,4,5,6,7,8,9 });
int n=3;
array front = arr[..n-1];
arr = arr[n..];
array back = arr[sizeof(arr)-n..];
arr = arr[..sizeof(arr)-(n+1)];
// since new arrays are created if elements are added or removed
// shift and pop are not usefull here.
// if you need shift and pop capabilities use the ADT classes:
array shift2(ADT.Queue queue)
{
return ({ queue->read(), queue->read() });
}
ADT.Queue friends = ADT.Queue("Peter", "Paul", "Mary", "Jim", "Tim");
string this, that;
[this, that] = shift2(friends);
// this contains Peter, that has Paul, and
// friends has Mary, Jim, and Tim
ADT.Stack beverages = ADT.Stack();
beverages->set_stack(({ "Dew", "Jolt", "Cola", "Sprite", "Fresca" }));
array pair = beverages->pop(2); // implementing pop2 would gain nothing here
// pair[0] contains Sprite, pair[1] has Fresca,
// and beverages has (Dew, Jolt, Cola)
// to be able to shift and pop on the same list use the following:
array shift2(ADT.CircularList list)
{
return ({ list->pop_front(), list->pop_front() });
}
array pop2(ADT.CircularList list)
{
return reverse( ({ list->pop_back(), list->pop_back() }) );
}
ADT.CircularList friends = ADT.CircularList( ({"Peter", "Paul", "Mary", "Jim", "Tim"}) );
string this, that;
[this, that] = shift2(friends);
// this contains Peter, that has Paul, and
// friends has Mary, Jim, and Tim
ADT.CircularList beverages = ADT.CircularList( ({ "Dew", "Jolt", "Cola", "Sprite", "Fresca" }) );
array pair = pop2(beverates);
// pair[0] contains Sprite, pair[1] has Fresca,
// and beverages has (Dew, Jolt, Cola)
```


## Finding the First List Element That Passes a Test

```pike
mixed match = search(arr, element);
int test(mixed element)
{
if(sizeof(element)==5)
return 1;
else
return 0;
}
mixed match = Array.search_array(arr, test);
if(match != -1)
{
// do something with arr[match]
}
else
{
// do something else
}
// another convenient way if you do many tests on the same list,
// and you do not care for the position is:
if( (multiset)arr[element] )
{
// found
}
else
{
// not found
}
```


## Finding All Elements in an Array Matching Certain Criteria

```pike
array matching=({});
foreach(list;; mixed element)
{
if(test(element))
matching+=({ element });
}
array matching = map(list, test)-({ 0 });
array matching = test(list[*])-({ 0 });
// apply test() on each element in list, collect the results, and remove
// results that are 0.
```


## Sorting an Array Numerically

```pike
// since pike has different types for strings and numbers, ints and floats are
// of course sorted numerically
// (sort() is destructive, the original array is changed)
array(int) unsorted = ...;
array(int) sorted = sort(unsorted);
// but suppose you want to sort an array of strings by their numeric value then
// things get a bit more interresting:
array(string) unsorted = ({ "123asdf", "3poiu", "23qwert", "3ayxcv" });
sort((array(int))unsorted, unsorted);
// unsorted is now sorted.
```


## Sorting a List by Computable Field

```pike
array unordered;
int compare(mixed a, mixed b)
{
// return comparison of a and b
}
array ordered = Array.sort_array(unordered, compare);
//-------------------------------------------------------------
int compute(mixed element)
{
// return computation from element
}
array precomputed = map(unordered, compute);
sort(precomputed, unordered); // will destructively sort unordered in the same
array ordered = unordered;    // manner as precomputed.
//-------------------------------------------------------------
sort(map(unordered, compute), unordered); // without a temp variable
sort(compute(unordered[*]), unordered);   // using the automap operator
// both get compiled to the same code
//-------------------------------------------------------------
array ordered = sort(employees, lambda(mixed a, mixed b)
{
return a->name > b->name;
}
);
//-------------------------------------------------------------
foreach(Array.sort_array(employees,
lambda(mixed a, mixed b){ return a->name > b->name; })
;; mixed employee)
{
write("%s earns $%d\n", employee->name, employee->salary);
}
//-------------------------------------------------------------
array ordered_employees =
Array.sort_array(employees,
lambda(mixed a, mixed b){ return a->name > b->name; });
foreach(ordered_employees;; mixed employee)
{
write("%s earns $%d\n", employee->name, employee->salary);
}
mapping bonus;
foreach(ordered_employees;; mixed employee)
{
// you are not supposed to use the social security number as an id
if(bonus[employee->id])
write("%s got a bonus!\n", employee->name);
}
//-------------------------------------------------------------
array sorted = Array.sort_array(employees,
lambda(mixed a, mixed b)
{
if(a->name!=b->name)
return (a->name < b->name)
return (b->age < a->age);
}
);
//-------------------------------------------------------------
array(array) users = System.get_all_users();
sort(users);
// System.get_all_users() returns an array of arrays, with the name as the
// first element in each inner array, sort handles multidimensional arrays, so
// we can skip creating our own sort function.
// if we wanted to sort on something else one could rearrange the array:
array user;
while(user=System.getpwent())
{
users += ({ user[2], user });
}
System.endpwent();
sort(users);  // now we are sorting by uid.
// alternative:
array(array) users = System.get_all_users();
sort(users[*][2], users);
write(users[*][0]*"\n");
write("\n");
//-------------------------------------------------------------
array names;
array sorted = Array.sort_array(names, lambda(mixed a, mixed b)
{
return a[1] < b[1];
}
);
// faster:
sort(names[*][1], names);
sorted=names;
//-------------------------------------------------------------
array strings;
array sorted = Array.sort_array(strings, lambda(mixed a, mixed b)
{
return sizeof(a) < sizeof(b);
}
);
// faster:
sort(sizeof(strings[*]), strings);
sorted=strings;
//-------------------------------------------------------------
array strings;
array temp = map(strings, sizeof);
sort(temp, strings);
array sorted = strings;
//-------------------------------------------------------------
array strings;
sort(map(strings, sizeof), strings);   // pick one
sort(sizeof(strings[*]), strings);
sorted=strings;
//-------------------------------------------------------------
array fields;
array temp = map(fields, array_sscanf, "%*s%d%*s");
sort(temp, fields);
array sorted_fields=fields;
//-------------------------------------------------------------
sort(array_sscanf(fields[*], "%*s%d%*s"), fields);
array sorted_fields=fields;
//-------------------------------------------------------------
array passwd_lines = (Stdio.read_file("/etc/passwd")/"\n")-({""});
array(array) passwd = passwd_lines[*]/":";
int compare(mixed a, mixed b)
{
if(a[3]!=b[3])
return (int)a[3]<(int)b[3];
if(a[2]!=b[2])
return (int)a[2]<(int)b[2];
return a[0]<b[0];
}
array sorted_passwd = Array.sort_array(passwd, compare);
// alternatively the following uses the builtin sort
sort( passwd[*][0], passwd);
sort( ((array(int))passwd[*][2]), passwd);
sort( ((array(int))passwd[*][3]), passwd);
```


## Implementing a Circular List

```pike
ADT.CircularList circular;
circular->push_front(circular->pop_back());
circular->push_back(circular->pop_front());
//-------------------------------------------------------------
mixed grab_and_rotate(ADT.CircularList list)
{
mixed element = list->pop_front();
list->push_back(element);
return element;
}
ADT.CircularList processes = ADT.CircularList( ({ 1, 2, 3, 4, 5 }) );
while(1)
{
int process = grab_and_rotate(processes);
write("Handling process %d\n", process);
sleep(1);
}
```


## Randomizing an Array

```pike
array arr;
Array.shuffle(arr);  // this uses the fisher-yates shuffle
//-------------------------------------------------------------
// being creative with the algorithm, this is not as memory efficient,
// but it shows the utility of multisets.
array set_shuffle(array list)
{
multiset elements=(multiset)list;
list=({});                     // reset the list
while(sizeof(elements))        // while we still have elements left
{
mixed pick=random(elements); // pick a random element
list+=({ pick });            // add it to the new list
elements[pick]--;            // remove the element we picked
}
return list;
}
array list;
list=set_shuffle(list);
//-------------------------------------------------------------
inherit "mjd_permute";
int permutations = factorial(sizeof(list));
array shuffle = list[n2perm(random(permutations)+1, sizeof(list))[*]];
//-------------------------------------------------------------
void naive_shuffle(array list)
{
for(int i=0; i<sizeof(list); i++)
{
int j=random(sizeof(list)-1);
[ list[i], list[j] ] = ({ list[j], list[i] });
}
}
```


## Program: words

```pike
// download the following standalone program
#!/usr/bin/pike
// section 4.18 example 4.2
// words - gather lines, present in columns
void main()
{
array words=Stdio.stdin.read()/"\n";   // get all input
int maxlen=sort(sizeof(words[*]))[-1]; // sort by size and pick the largest
maxlen++;                              // add space
// get boundaries, this should be portable
int cols = Stdio.stdout->tcgetattr()->columns/maxlen;
int rows = (sizeof(words)/cols) + 1;
string mask="%{%-"+maxlen+"s%}\n";     // compute format
words=Array.transpose(words/rows);     // split into groups as large as the
// number of rows and then transpose
write(mask, words[*]);                 // apply mask to each group
}
```


## Program: permute

```pike
int factorial(int n)
{
int s=1;
while(n)
s*=n--;
return s;
}
write("%d\n", factorial(500));
// Using Array.permute() to generate all permutations
// -------------------------------------------------------------
// Example: Generate all permutations of an array using Array.permute()
// Note: Array.permute() returns all possible orderings of array elements
import Array;
// Simple permutation example
array(string) fruits = ({"apple", "banana", "cherry"});
array(array(string)) perms = permute(fruits);
foreach(perms, array(string) p)
{
write("%s\n", p*", ");
}
// Output:
// apple, banana, cherry
// apple, cherry, banana
// banana, apple, cherry
// banana, cherry, apple
// cherry, apple, banana
// cherry, banana, apple
//-------------------------------------------------------------
// download the following standalone program
#!/usr/bin/pike
void main()
{
string line;
while(line=Stdio.stdin->gets())
{
permute(line/" ");
}
}
void permute(array items, array|void perms)
{
if(!perms)
perms=({});
if(!sizeof(items))
write((perms*" ")+"\n");
else
{
foreach(items; int i;)
{
array newitems=items[..i-1]+items[i+1..];
array newperms=items[i..i]+perms;
permute(newitems, newperms);
}
}
}
//-------------------------------------------------------------
// download the following standalone program
#!/usr/bin/pike
mapping fact=([ 1:1 ]);
int factorial(int n)
{
if(!fact[n])
fact[n]=n*factorial(n-1);
return fact[n];
}
array n2pat(int N, int len)
{
int i=1;
array pat=({});
while(i <= len)
{
pat += ({ N%i });
N/=i;
i++;
}
return pat;
}
array pat2perm(array pat)
{
array source=indices(pat);
array perm=({});
while(sizeof(pat))
{
perm += ({ source[pat[-1]] });
source = source[..pat[-1]-1]+source[pat[-1]+1..];
pat=pat[..sizeof(pat)-2];
}
return perm;
}
array n2perm(int N, int len)
{
return pat2perm(n2pat(N, len));
}
void main()
{
array data;
while(data=Stdio.stdin->gets()/" ")
{
int num_permutations = factorial(sizeof(data));
for(int i; i<num_permutations; i++)
{
array permutation = data[n2perm(i, sizeof(data))[*]];
write(permutation*" "+"\n");
}
}
}
```

