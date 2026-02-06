---
id: visibility
title: Visibility & Access Modifiers
sidebar_label: Visibility Modifiers
---

Pike's visibility modifiers look familiar if you're coming from Java or C++, but they work very differently. This chapter explains what each modifier actually does and highlights the gotchas that trip up developers expecting Java/C++ semantics.

## Quick Reference

| Modifier | Java/C++ Meaning | Pike Meaning |
|----------|-----------------|--------------|
| `private` | Only within the class | Not accessible to subclasses; implies `protected` + `local` |
| `protected` | Accessible to subclasses + package | Accessible to subclasses, NOT via external `->` or `[]` |
| `public` | Accessible everywhere | Default; on inherits: exposes private symbols as local protected |
| `static` | Class-level member | **DEPRECATED** alias for `protected` (completely different!) |
| `local` | N/A | Prevents subclass overloading of this symbol |
| `final` | Prevents override | Prevents override (compile error) - similar to Java |
| `variant` | Function overloading (C++) | Function overloading by argument types |
| `optional` | N/A | Symbol can be omitted from implementation |
| `extern` | External linkage | Forward declaration for subclass implementation; implies `optional` |

## `public` — The Default

All symbols in Pike are public by default. You can access them from anywhere using the `->` or `[]` operators.

```pike
class Counter {
    int count = 0;  // public by default

    void increment() {
        count++;
    }
}

int main() {
    object c = Counter();
    c->increment();
    write("Count: %d\n", c->count);  // Direct access works
    return 0;
}
```

When used on an inherit statement, `public` has a special meaning: it converts inherited private symbols to local protected symbols, making them accessible to further subclasses.

```pike
class Base {
    private int secret = 42;
}

class Middle {
    public inherit Base;  // Makes 'secret' local protected in Middle
}

class Child {
    inherit Middle;  // Can now access 'secret' as protected

    void show() {
        write("Secret: %d\n", secret);
    }
}
```

## `protected` — Hidden from External Access

Protected symbols are accessible within the class and its subclasses, but NOT through external access via `->` or `[]`.

:::caution
Pike's `protected` was historically called `static`, which is extremely confusing for Java/C++ developers. The name `static` is now deprecated.
:::

```pike
class Account {
    protected float balance = 0.0;

    void deposit(float amount) {
        balance += amount;
    }

    void show_balance() {
        write("Balance: %.2f\n", balance);
    }
}

class SavingsAccount {
    inherit Account;

    void add_interest(float rate) {
        balance *= (1.0 + rate);  // Can access protected member from subclass
    }
}

int main() {
    object acc = SavingsAccount();
    acc->deposit(100.0);
    acc->add_interest(0.05);
    acc->show_balance();

    // This would cause an error:
    // write("%f\n", acc->balance);  // ERROR: protected member

    return 0;
}
```

Protected members support proper encapsulation while allowing inheritance-based extension.

## `private` — The Most Restrictive

Private members are not accessible to subclasses at all. They're completely hidden from internal indexing.

:::warning Major Difference from Java
In Java, private members still exist in subclass instances; they're just not directly accessible. In Pike, private members are truly invisible to subclasses.
:::

```pike
class Base {
    private int hidden_value = 42;

    void show_hidden() {
        write("Hidden: %d\n", hidden_value);
    }
}

class Child {
    inherit Base;

    void try_access() {
        // This would cause an error:
        // write("%d\n", hidden_value);  // ERROR: private member not visible

        // But we can call methods that use it:
        show_hidden();  // Works fine
    }
}

int main() {
    object c = Child();
    c->try_access();

    // Both of these fail:
    // c->hidden_value;     // ERROR: private
    // c->show_hidden();    // Wait, this actually works!

    return 0;
}
```

Since `private` implies both `protected` and `local`, private members provide the strongest encapsulation Pike offers.

## `local` — Prevent Dynamic Dispatch

The `local` modifier prevents subclasses from overriding a symbol for the current class's use. The symbol is still visible and accessible to subclasses, but the current class always uses its own version.

:::tip
`local` is also known as `inline` in Pike. This prevents dynamic dispatch for performance-critical code.
:::

```pike
class Base {
    local int get_value() {
        return 10;
    }

    void show_value() {
        write("Base sees: %d\n", get_value());  // Always calls Base's version
    }
}

class Child {
    inherit Base;

    int get_value() {  // This override is allowed
        return 20;
    }

    void show_both() {
        write("Child sees: %d\n", get_value());  // Calls Child's version
        show_value();  // Calls Base's show_value, which calls Base's get_value
    }
}

int main() {
    object c = Child();
    c->show_both();

    // Output:
    // Child sees: 20
    // Base sees: 10     <- Note: uses Base's get_value, not Child's!

    return 0;
}
```

Without `local`, Base's `show_value()` would dynamically dispatch to Child's `get_value()` and print 20.

## `static` — The Big Gotcha

:::danger DEPRECATED
`static` is considered deprecated and generates compiler warnings in recent Pike versions. It's simply an alias for `protected`.
:::

Pike's `static` has **nothing to do** with class-level vs instance-level members like in Java or C++. This is one of the biggest gotchas for developers from other languages.

```pike
// WRONG: Java developer expecting class-level behavior
class Counter {
    static int count = 0;  // NOT a class variable!

    void increment() {
        count++;
    }
}

int main() {
    object c1 = Counter();
    object c2 = Counter();

    c1->increment();
    c1->increment();

    // Java developer expects this to be 2, but it's 0
    // because 'count' is protected (instance-level)
    // and not accessible via ->

    // write("%d\n", c2->count);  // ERROR: protected member

    return 0;
}
```

For class-level shared data, use module-level variables or constants:

```pike
// CORRECT: Module-level variable for sharing
int global_count = 0;

class Counter {
    void increment() {
        global_count++;
    }

    void show() {
        write("Global count: %d\n", global_count);
    }
}

int main() {
    object c1 = Counter();
    object c2 = Counter();

    c1->increment();
    c2->increment();
    c2->show();  // Prints: Global count: 2

    return 0;
}
```

## `final` — Prevent Override

The `final` modifier (formerly `nomask`) causes a compile-time error if a subclass tries to override the symbol. This is stricter than `local`.

```pike
class Base {
    final int get_constant() {
        return 42;
    }

    local int get_dynamic() {
        return 10;
    }
}

class Child {
    inherit Base;

    // This would cause a compile error:
    // int get_constant() { return 100; }  // ERROR: final method

    // This is allowed (but Base won't see it):
    int get_dynamic() { return 20; }  // OK: local allows override
}
```

Use `final` when you want to enforce that a method's implementation cannot be changed, even for the subclass's own use.

## `variant` — Function Overloading

The `variant` modifier allows multiple functions with the same name but different argument types. The compiler selects the correct version based on the arguments.

```pike
class Printer {
    variant void print(int value) {
        write("Integer: %d\n", value);
    }

    variant void print(string value) {
        write("String: %s\n", value);
    }

    variant void print(array value) {
        write("Array with %d elements\n", sizeof(value));
    }

    variant void print(int x, int y) {
        write("Coordinates: (%d, %d)\n", x, y);
    }
}

int main() {
    object p = Printer();

    p->print(42);              // Integer: 42
    p->print("hello");         // String: hello
    p->print(({1, 2, 3}));     // Array with 3 elements
    p->print(10, 20);          // Coordinates: (10, 20)

    return 0;
}
```

The type resolution happens at compile time when possible, falling back to runtime dispatch when needed.

## `optional` and `extern`

These modifiers support interface-like patterns where some symbols may be omitted or implemented by subclasses.

```pike
// Define an interface-like base class
class Drawable {
    extern void draw();          // Must be implemented by subclass
    extern optional void erase(); // May be implemented

    void render() {
        draw();
        if (this_object()->erase) {
            erase();
        }
    }
}

class Circle {
    inherit Drawable;

    void draw() {
        write("Drawing circle\n");
    }

    // erase is optional, so we can omit it
}

class Rectangle {
    inherit Drawable;

    void draw() {
        write("Drawing rectangle\n");
    }

    void erase() {
        write("Erasing rectangle\n");
    }
}

int main() {
    object c = Circle();
    object r = Rectangle();

    c->render();  // Drawing circle
    r->render();  // Drawing rectangle
                  // Erasing rectangle

    return 0;
}
```

`extern` implies `optional`, so all extern symbols can be omitted. This is useful for defining abstract base classes.

## Modifier Combinations

Some modifiers imply others:

- `private` implies `protected` + `local`
- `extern` implies `optional`

Common useful combinations:

```pike
class Example {
    // Encapsulated helper, can't be overridden
    protected local int helper() {
        return 42;
    }

    // Template method pattern
    final void process() {
        setup();
        do_work();
        cleanup();
    }

    // Subclasses can override these
    protected void setup() { }
    protected void do_work() { }
    protected void cleanup() { }
}
```

## The `::` Operator

Pike provides the `::` operator to access parent class members explicitly, bypassing normal inheritance and dispatch rules.

```pike
class Base {
    void greet() {
        write("Hello from Base\n");
    }
}

class Child {
    inherit Base;

    void greet() {
        write("Hello from Child\n");
    }

    void greet_both() {
        greet();        // Calls Child's version
        ::greet();      // Calls Base's version
    }
}

int main() {
    object c = Child();
    c->greet_both();

    // Output:
    // Hello from Child
    // Hello from Base

    return 0;
}
```

With named inheritance, you can specify which parent:

```pike
class Animal {
    void speak() {
        write("Generic animal sound\n");
    }
}

class Robot {
    void speak() {
        write("Beep boop\n");
    }
}

class Cyborg {
    inherit Animal;
    inherit Robot;

    void speak() {
        write("I am a cyborg: ");
        Animal::speak();
        Robot::speak();
    }
}

int main() {
    object c = Cyborg();
    c->speak();

    // Output:
    // I am a cyborg: Generic animal sound
    // Beep boop

    return 0;
}
```

## Multiple Inheritance and Visibility

Pike supports multiple inheritance, and protected symbols work well with mixin patterns.

```pike
class Logger {
    protected void log(string msg) {
        write("[LOG] %s\n", msg);
    }
}

class Validator {
    protected int validate(int value) {
        return value >= 0 && value <= 100;
    }
}

class Component {
    inherit Logger;
    inherit Validator;

    void set_value(int value) {
        if (validate(value)) {
            log(sprintf("Setting value to %d", value));
        } else {
            log(sprintf("Invalid value: %d", value));
        }
    }
}

int main() {
    object c = Component();
    c->set_value(50);   // [LOG] Setting value to 50
    c->set_value(150);  // [LOG] Invalid value: 150

    return 0;
}
```

Diamond inheritance is handled by Pike, but note that each `inherit` creates its own copy of the inherited members:

:::info
Unlike C++ virtual inheritance, Pike does not merge diamond-inherited members. Each `inherit` brings its own copy. Use named inherits with `::` to disambiguate.
:::

```pike
class Base {
    protected int value = 0;
}

class Left {
    inherit Base;

    void set_left(int v) {
        value = v;
    }
}

class Right {
    inherit Base;

    void set_right(int v) {
        value = v * 2;
    }
}

class Diamond {
    inherit Left;
    inherit Right;

    void show() {
        write("Left value: %d\n", Left::value);
        write("Right value: %d\n", Right::value);
    }
}

int main() {
    object d = Diamond();
    d->set_left(10);
    d->set_right(20);
    d->show();
    // Output:
    // Left value: 10
    // Right value: 40

    return 0;
}
```

## Common Pitfalls

### "Why can't I access this member with `->`?"

It's probably `protected`. Protected members can only be accessed from within the class hierarchy, not from external code.

```pike
class Counter {
    protected int count = 0;  // Note: protected

    void increment() {
        count++;
    }
}

int main() {
    object c = Counter();
    // c->count;  // ERROR: protected member

    // Solution: add a public accessor
    return 0;
}
```

### "Why does my subclass see the parent's version?"

You probably need `local` on the parent's method to prevent dynamic dispatch.

```pike
class Base {
    // Without local:
    int get_value() { return 10; }

    void show() {
        write("%d\n", get_value());  // Calls Child's version!
    }
}

class Child {
    inherit Base;
    int get_value() { return 20; }
}

// Solution: Make Base's get_value local
class FixedBase {
    local int get_value() { return 10; }

    void show() {
        write("%d\n", get_value());  // Always calls FixedBase's version
    }
}
```

### "Why doesn't `static` make a class variable?"

Because Pike's `static` is deprecated and means `protected`. Use module-level variables instead.

```pike
// WRONG
class Counter {
    static int count = 0;  // This is protected, not class-level!
}

// RIGHT
int shared_count = 0;  // Module-level variable

class Counter {
    void increment() {
        shared_count++;
    }
}
```

### "My private method is invisible to child classes"

That's by design. `private` means truly private, unlike Java where private members still exist in subclass instances.

```pike
class Base {
    private int secret = 42;

    int get_secret() {
        return secret;
    }
}

class Child {
    inherit Base;

    void show() {
        // write("%d\n", secret);      // ERROR: private, not visible
        write("%d\n", get_secret());   // OK: call public method
    }
}
```

If you want subclasses to access the member, use `protected` instead of `private`.

## Best Practices

1. **Default to public** for true public APIs that external code should use
2. **Use protected** for internal helpers that subclasses might need
3. **Use private** sparingly, only for implementation details that truly should never be visible
4. **Use local** for performance-critical methods where you want to prevent dynamic dispatch
5. **Use final** when you want to enforce that a method cannot be overridden at all
6. **Avoid `static`** — it's deprecated; use `protected` explicitly
7. **Use `variant`** when you need type-based overloading
8. **Use `extern`** for defining abstract base classes and interfaces

## Summary

Pike's visibility modifiers provide fine-grained control over access and inheritance, but they work differently from Java/C++:

- `protected` hides from external access (`->`), not from subclasses
- `private` truly hides from subclasses (not just external access)
- `local` prevents dynamic dispatch while keeping the symbol visible
- `static` is deprecated and means `protected`, NOT class-level
- `final` prevents overriding completely
- `variant` enables type-based overloading
- `extern`/`optional` support interface patterns

Understanding these differences is crucial for writing correct Pike code, especially if you're coming from other object-oriented languages.
