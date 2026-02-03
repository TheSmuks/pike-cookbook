---
id: numbers
title: Numbers
sidebar_label: Numbers
---

## Checking Whether a String Is a Valid Number

```pike
string number = "123.3asdf";

int|float realnumber = (int)number;  // casting to int will throw away all
                                    // nonnumber parts
string rest;
[realnumber, rest] = array_sscanf(number, "%d%s"); // scan for an integer
// if rest contains anything but the empty string, then there was more than a
// number in the string
// use %f to scan for float, %x for hex or %o for octal

// Modern type validation and conversion in Pike 8
// Robust number checking with exception handling

mixed is_valid_number(string str)
{
  catch
  {
    float val = float(str);
    return val;
  };
  return 0;
}

// Advanced type conversion utilities
int to_int(mixed value)
{
  if (intp(value)) return value;
  if (floatp(value)) return int(value);
  if (stringp(value))
  {
    catch { return int(value); }
    return 0;
  }
  return 0;
}

float to_float(mixed value)
{
  if (floatp(value)) return value;
  if (intp(value)) return float(value);
  if (stringp(value))
  {
    catch { return float(value); }
    return 0.0;
  }
  return 0.0;
}

string to_string(mixed value)
{
  if (intp(value) || floatp(value)) return sprintf("%.6g", value);
  return string value;
}

// Example usage
array test_values = ({ "42", "3.14", "hello", 100, -5.5 });

foreach(test_values, mixed val)
{
  write("Value: %O, Int: %d, Float: %f, Valid: %s\n",
        val, to_int(val), to_float(val),
        is_valid_number(string)val) ? "Yes" : "No");
}
```

## Comparing Floating-Point Numbers

```pike
int same(float one, float two, int accuracy)
{
  return sprintf("%.*f", accuracy, one) == sprintf("%.*f", accuracy, two);
}

int wage=536;
int week=40*wage;
write("one week's wage is: $%.2f\n", week/100.0);
```

## Rounding Floating-Point Numbers

```pike
float unrounded=3.5;
string rounded=sprintf("%.*f", accuracy, unrounded);

float a=0.255;
string b=sprintf("%.2f", a);

write("Unrounded: %f\nRounded: %s\n", a, b);
write("Unrounded: %f\nRounded: %.2f\n", a, a);

// dec to bin
string bin=sprintf("%b", 5);

int dec=array_sscanf("0000011111111111111", "%b")[0];
                // array_sscanf returns an array

int num = array_sscanf("0110110", "%b")[0];  // num is 54
string binstr = sprintf("%b", 54);           // binstr is 110110
```

## Converting Between Binary and Decimal

```pike
// contributed by martin nilsson.

string dec2bin(int n)
{
  return sprintf("%b",n);
}

int bin2dec(string n)
{
  return array_sscanf(n, "%b")[0];
}
```

## Operating on a Series of Integers

```pike
// foreach(enumerate(int count, int step, int start);; int val)
// {
//   // val is set to each of count integers starting at start
// }

foreach(enumerate(y-x+1,1,x);; int val)
{
  // val is set to every integer from X to Y, inclusive
}

for(int i=x; i<=y; i++)
{
  // val is set to every integer from X to Y, inclusive
}

for(int i=x; i<=y; i+=7)
{
  // val is set to every integer from X to Y, stepsize = 7
}

foreach(enumerate(y-x+1,7,x);; int val)
{
  // val is set to every integer from X to Y, stepsize = 7
}

//----------------------------------------
write("Infancy is: ");
foreach(enumerate(3);; int val)
{
  write("%d ", val);
}
write("\n");

write("Toddling is: %{%d %}\n", enumerate(2,1,3));

write("Childhood is: ");
for (int i = 5; i <= 12; i++)
{
  write("%d ", i);
}
write("\n");

// Infancy is: 0 1 2
// Toddling is: 3 4
// Childhood is: 5 6 7 8 9 10 11 12
```

## Working with Roman Numerals

```pike
int arabic;
string roman = String.int2roman(arabic);        // handles values up to 10000

array nums=enumerate(10001);
array romans=String.int2roman(nums[*]);
mapping roman2int = mmapping(romans, nums);

int arabic = roman2int[roman];

//------------------------------------------------
string roman_fifteen = String.int2roman(15);    //  "XV"
write("Roman for fifteen is %s\n", roman_fifteen);

int arabic_fifteen = roman2int[roman_fifteen];
write("Converted back, %s is %d\n", roman_fifteen, arabic_fifteen);

// Roman for fifteen is XV
// Converted back, XV is 15
```

## Generating Random Numbers

```pike
int y,x;
int rand = random(y-x+1)+x;

float y,x;
float rand = random(y-x+1)+x;

int rand = random(51)+25;
write("%d\n", rand);

array arr;
mixed elt = arr[random(sizeof(arr))];
mixed elt = random(arr);

array chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@%^&*"/"";
string password = "";
for(int i=1; i<=8; i++)
{
  password+=random(chars);
}

string password = random_string(8);      // creates an untypable string

// turn the string into something typable using the base64 charset
string password = MIME.encode_base64(random_string(8))[..7];
```

## Generating Different Random Numbers

```pike
random_seed(int seed);
random_seed((int)argv[1]);
```

## Making Numbers Even More Random

```pike
// Crypto.Random.random(int max)
// Crypto.Random.random_string(int length)
// Crypto.Random.blocking_random_string(int length)
// Crypto.Random.add_entropy(string random_data, int entropy)
```

## Generating Biased Random Numbers

```pike
float gaussian_rand()
{
  float u1, u2, w, g1, g2;

  do
  {
    u1 = 2.0 * random(1.0) - 1.0; u2 = 2.0 * random(1.0) - 1.0;
    w = u1 * u1 + u2 * u2;
  } while (w > 1.0);

  w = sqrt((-2.0 * log(w)) / w); g2 = u1 * w; g1 = u2 * w;

  return g1;
}

// ----

float mean = 25.0, sdev = 2.0;
float salary = gaussian_rand() * mean + sdev;

write("You have been hired at: %.2f\n", salary);
```

## Doing Trigonometry in Degrees, not Radians

```pike
float deg2rad(float deg)
{
  return (deg / 180.0) * Math.pi;
}

float rad2deg(float rad)
{
  return (rad / Math.pi) * 180.0;
}

// ----

write("%f\n", Math.convert_angle(180, "deg", "rad"));
write("%f\n", deg2rad(180.0));

// ----------------------------

float degree_sin(float deg)
{
  return sin(deg2rad(deg));
}

// ----

float rad = deg2rad(380.0);
write("%f\n", sin(rad));
write("%f\n", degree_sin(380.0));
```

## Calculating More Trigonometric Functions

```pike
float my_tan(float theta)
{
  return sin(theta) / cos(theta);
}

// ----

float theta = 3.7;

write("%f\n", my_tan(theta));
write("%f\n", tan(theta));
```

## Converting Between Number Bases

```pike
// Convert numbers between different bases using Pike's sprintf and sscanf
// Common conversions: decimal, binary, octal, hexadecimal

// Convert from decimal to other bases
int decimal = 42;

// To binary
string binary = sprintf("%b", decimal);  // "101010"
// To octal
string octal = sprintf("%o", decimal);    // "52"
// To hexadecimal
string hexadecimal = sprintf("%x", decimal); // "2a"

// Convert from other bases back to decimal
string bin_str = "101010";
string oct_str = "52";
string hex_str = "2a";

int from_bin = array_sscanf(bin_str, "%b")[0];  // 42
int from_oct = array_sscanf(oct_str, "%o")[0];   // 42
int from_hex = array_sscanf(hex_str, "%x")[0];   // 42

// Convert between bases using sscanf with any string format
string hex_val = "2A";
string bin_val;

sscanf(hex_val, "%x", hexadecimal);
bin_val = sprintf("%b", hexadecimal);

write("Hex %s converts to binary: %s\n", hex_val, bin_val);

// Base conversion utility functions
string convert_base(int number, int from_base, int to_base)
{
  int decimal = array_sscanf(sprintf("%*s", number), "%" + (string)from_base + "d")[0];
  return sprintf("%*s", to_base, decimal);
}

// Example usage
string oct_to_hex = convert_base("52", 8, 16);  // "2a"
string bin_to_dec = convert_base("101010", 2, 10); // "42"

// Literal notation for different bases in Pike
int dec_literal = 42;          // decimal (base 10)
int hex_literal = 0x2A;         // hexadecimal (base 16)
int oct_literal = 052;         // octal (base 8)
int bin_literal = 0b101010;      // binary (base 2)

write("All represent the same value: %d, 0x%x, 0%o, 0b%b\n",
      dec_literal, hex_literal, oct_literal, bin_literal);

// Output: All represent the same value: 42, 0x2a, 052, 0b101010
```

## Taking Logarithms

```pike
float value = 100.0;

float log_e = log(value);
float log_10 = Math.log10(value);

// ----------------------------

float log_base(float base, float value)
{
  return log(value) / log(base);
}

// ----

float answer = log_base(10.0, 10000.0);

write("log(10, 10,000) = %f\n", answer);
```

## Multiplying Matrices

```pike
// Pike offers a solid matrix implementation; highlights:
// * Operator overloading makes matrix operations succinct
// * Matrices may be of various types, thus allowing user to
//   choose between range representation and speed
// * Wide variety of operations available

Math.Matrix a = Math.Matrix( ( ({3, 2, 3}), ({5, 9, 8}) ) ),
            b = Math.Matrix( ( ({4, 7}), ({9, 3}), ({8, 1}) ) );

Math.Matrix c = a * b;

// ------------

Math.Matrix t = c->transpose();
```

## Using Complex Numbers

```pike
// Using complex numbers in Pike with Math.Complex
// Complex numbers can be created using literal syntax or constructor

// Create complex numbers - j is the imaginary unit
complex c1 = 3.0 + 2.0 * Math.CI;  // 3 + 2i
complex c2 = 1.0 - 4.0 * Math.CI;  // 1 - 4i

// Basic operations
complex sum = c1 + c2;      // (3 + 1) + (2 - 4)i = 4 - 2i
complex diff = c1 - c2;     // (3 - 1) + (2 - (-4))i = 2 + 6i
complex product = c1 * c2;  // (3*1 - 2*4) + (3*(-4) + 2*1)i = -5 - 10i
complex quotient = c1 / c2; // complex division

// Complex conjugate and magnitude
complex conjugate = Math.conjugate(c1);  // 3 - 2i
float magnitude = Math.abs(c1);        // sqrt(3² + 2²) = 3.60555...

// Mathematical functions for complex numbers
complex squared = c1 * c1;                // (3 + 2i)² = 9 + 12i + 4i² = 5 + 12i
complex power = Math.pow(c1, 3);         // (3 + 2i)³
complex sqrt_c1 = Math.sqrt(c1);        // square root of complex number
complex exp_c1 = Math.exp(c1);          // e^(3 + 2i)
complex log_c1 = Math.log(c1);          // natural logarithm
complex sin_c1 = Math.sin(c1);          // sine of complex number
complex cos_c1 = Math.cos(c1);          // cosine of complex number

// Modern math functions with Pike 8
x = 2.5;

// Advanced mathematical functions
sqrt_x = sqrt(x);              // square root
pow_x = Math.pow(x, 3);        // x³
exp_x = Math.exp(x);            // e^x
log_x = log(x);              // natural logarithm
log10_x = Math.log10(x);        // base-10 logarithm
sin_x = sin(x);              // sine (radians)
cos_x = cos(x);              // cosine (radians)
tan_x = tan(x);              // tangent (radians)

// Hyperbolic functions
sinh_x = Math.sinh(x);            // hyperbolic sine
cosh_x = Math.cosh(x);            // hyperbolic cosine
tanh_x = Math.tanh(x);            // hyperbolic tangent

// Inverse trigonometric functions
asin_x = asin(x);            // arcsine
acos_x = acos(x);            // arccosine
atan_x = atan(x);            // arctangent

// Rounding functions
floor_x = floor(x);            // round down
ceil_x = ceil(x);             // round up
round_x = round(x);           // round to nearest integer
trunc_x = float(int)x;          // truncate decimal part

// Mathematical constants
pi = Math.pi;                    // π ≈ 3.14159...
e = Math.e;                      // e ≈ 2.71828...

// Example: Solve quadratic equation x² + x + 1 = 0
// Roots: (-1 ± sqrt(1 - 4)) / 2 = (-1 ± sqrt(-3)) / 2
float a = 1, b = 1, c = 1;
float discriminant = b*b - 4*a*c;  // -3
complex root1 = (-b + Math.sqrt(discriminant)) / (2*a);
complex root2 = (-b - Math.sqrt(discriminant)) / (2*a);

write("Roots of x² + x + 1 = 0:\n");
write("  %O\n  %O\n", root1, root2);

// Output:
// Roots of x² + x + 1 = 0:
//   (-0.5000000000000000000+0.8660254037844386468j)
//   (-0.5000000000000000000-0.8660254037844386468j)
```

## Converting Between Octal and Hexadecimal

```pike
// Like C, Pike supports decimal-alternate notations. Thus, for example,
// the integer value, 867, is expressable in literal form as:
//
//   Hexadecimal -> 0x363
//   Octal       -> 01543
//
// For effecting such conversions using strings there is 'sprintf' and
// 'sscanf'.

int dec = 867;
string hex = sprintf("%x", dec);
string oct = sprintf("%o", dec);

// ------------

int dec;
string hex = "363"; sscanf(hex, "%x", dec);

// ------------

int dec;
string oct = "1543"; sscanf(oct, "%o", dec);

// ----------------------------

int number;

write("Gimme a number in decimal, octal, or hex: ");
sscanf(Stdio.stdin->gets(), "%D", number);

write("%d %x %o\n", number, number, number);
```

## Putting Commas in Numbers

```pike
string commify_series(int series)
{
  return reverse((reverse((string)series) / 3.0) * ",");
}

// ----

int hits = 3452347;

write("Your website received %s accesses last month.\n", commify_series(hits));

// ----------------------------

string commify(string s)
{
  function t = lambda(string m) { return reverse((reverse(m) / 3.0) * ","); };
  return Regexp.PCRE("([0-9]+)")->replace(s, t);
}

// ----

int hits = 3452347;
string output = sprintf("Your website received %d accesses last month.", hits);

write("%s\n", commify(output));

// ----------------------------

// Additional modern number formatting with Pike 8
string format_currency(float amount)
{
  return sprintf("%.2f", amount);
}

// Scientific notation
value = 1234.5678;
scientific = sprintf("%.2e", value);  // "1.23e+03"

// Fixed width formatting with leading zeros
padded = sprintf("%010d", 42);        // "0000000042"

// Locale-aware formatting (if locale is set)
locale_format = sprintf("'" + value + "'");  // Uses current locale

formatted = commify_series(1000000);
write("Formatted: %s\nCurrency: %s\nScientific: %s\n",
      formatted, format_currency(1234.56), scientific);
```

## Printing Correct Plurals

```pike
string pluralise(int value, string root, void|string singular_, void|string plural_)
{
  string singular = singular_ ? singular_ : "";
  string plural = plural_ ? plural_ : "s";

  return root + ((value > 1) ? plural : singular);
}

// ----

int duration = 1;
write("It took %d %s\n", duration, pluralise(duration, "hour"));
write("%d %s %s enough.\n", duration, pluralise(duration, "hour"),
      pluralise(duration, "", "is", "are"));

duration = 5;
write("It took %d %s\n", duration, pluralise(duration, "hour"));
write("%d %s %s enough.\n", duration, pluralise(duration, "hour"),
      pluralise(duration, "", "is", "are"));

// ----------------------------

// Non-regexp implementation, uses the string-based, 'has_prefix'
// and 'replace' library functions
string plural(string singular)
{
  mapping(string : string) e2 =
    (["ss":"sses", "ph":"phes", "sh":"shes", "ch":"ches",
      "ey":"eys", "ix":"ices", "ff":"ffs"]);

  mapping(string : string) e1 =
    (["z":"zes", "f":"ves", "y":"ies", "s":"ses", "x":"xes"]);

  foreach(({e2, e1}), mapping(string : string) endings)
  {
    foreach(indices(endings), string ending)
    {
      if (has_suffix(singular, ending))
      {
        return replace(singular, ending, endings[ending]);
      }
    }
  }

  return singular;
}

// ----

int main()
{
  foreach(aggregate("mess", "index", "leaf", "puppy"), string word)
    write("%6s -> %s\n", word, plural(word));
}
```

## Program: Calculating Prime Factors

```pike
// <font size="-1"><a href="../include/pike/ch02/bigfact.html">download the following standalone program</a></font>
#!/usr/bin/pike
// contributed by martin nilsson

void main(int n, array args)
{
  foreach(args[1..], string arg)
  {
    mapping r = ([]);
    foreach(Math.factor((int)arg), int f)
      r[f]++;
    write("%-10s", arg);
    if(sizeof(r)==1)
      write(" PRIME");
    else
    {
      foreach(sort(indices(r)), int f)
      {
        write(" %d", f);
        if(r[f]>1) write("**%d", r[f]);
      }
    }
    write("\n");
  }
}
```