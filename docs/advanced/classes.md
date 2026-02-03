---
id: classes
title: Classes and Objects
sidebar_label: Classes and Objects
---

# Classes and Objects

## Introduction

Pike 8 is a modern object-oriented language with first-class support for classes, objects, inheritance, polymorphism, and encapsulation. This chapter covers Pike's object-oriented programming features including class declaration, methods, inheritance, access control, operator overloading, and lambda functions.

**What this covers:**
- Class declaration and instantiation
- Methods and properties with type annotations
- Single and multiple inheritance
- Access control and encapsulation
- Operator overloading
- Static members and class methods
- Lambda functions and closures

**Why use it:**
- Organize code into reusable components
- Model real-world entities and relationships
- Create maintainable, modular code
- Implement design patterns
- Leverage polymorphism for flexible architectures

:::tip
Pike 8's `#pragma strict_types` combined with OOP provides robust type safety while maintaining Pike's flexibility.
:::

---

## Constructing an Object

### Basic Class and Constructor

```pike
//-----------------------------
// Recipe: Simple class with constructor
//-----------------------------

#pragma strict_types

class Person {
    protected string name;
    protected int age;

    // Constructor with required parameters
    void create(string name_, int age_) {
        name = name_;
        age = age_;
    }

    // Public getter methods
    public string get_name() {
        return name;
    }

    public int get_age() {
        return age;
    }

    // String representation
    public string _sprintf(int type) {
        return sprintf("Person(%s, %d)", name, age);
    }
}

// Usage
Person p = Person("Alice", 30);
write("%s\n", p);  // Output: Person(Alice, 30)
write("Name: %s\n", p->get_name());
```

### Constructor with Default Values

```pike
//-----------------------------
// Recipe: Constructor with optional parameters
//-----------------------------

#pragma strict_types

class Config {
    protected mapping(string:mixed) options;

    void create(void|mapping(string:mixed) opts) {
        options = opts || ([]);
    }

    mixed get(string key, void|mixed default_val) {
        return options[key] || default_val;
    }

    void set(string key, mixed value) {
        options[key] = value;
    }
}

Config cfg1 = Config();
Config cfg2 = Config((["host": "localhost", "port": 8080]));
```

---

## Destroying an Object

### Resource Cleanup

```pike
//-----------------------------
// Recipe: Automatic cleanup with destroy()
//-----------------------------

#pragma strict_types

class DatabaseConnection {
    protected string connection_string;
    protected bool is_connected = false;

    void create(string conn_str) {
        connection_string = conn_str;
        is_connected = true;
        write("Connected to: %s\n", conn_str);
    }

    void destroy() {
        if (is_connected) {
            write("Closing connection to: %s\n", connection_string);
            is_connected = false;
        }
    }
}

void test_connection() {
    DatabaseConnection db = DatabaseConnection("postgresql://localhost/test");
    write("Working with database...\n");
}  // destroy() called here
```

:::note
Pike uses garbage collection, so `destroy()` is called when an object is no longer referenced.
:::

---

## Managing Instance Data

### Instance Variables and Encapsulation

```pike
//-----------------------------
// Recipe: Class with private data and public accessors
//-----------------------------

#pragma strict_types

class BankAccount {
    // Private instance data
    protected string account_number;
    protected float balance;

    // Public constant
    public constant OVERDRAFT_FEE = 35.0;

    void create(string owner, string acct_num) {
        account_number = acct_num;
        balance = 0.0;
    }

    public float get_balance() {
        return balance;
    }

    public int deposit(float amount) {
        if (amount <= 0) return 0;
        balance += amount;
        return 1;
    }

    public int withdraw(float amount) {
        if (amount <= 0 || amount > balance) return 0;
        balance -= amount;
        return 1;
    }
}

BankAccount acct = BankAccount("Alice", "123-456");
acct->deposit(100.0);
write("Balance: $%.2f\n", acct->get_balance());
```

---

## Managing Class Data

### Static Class Members

```pike
//-----------------------------
// Recipe: Shared class data
//-----------------------------

#pragma strict_types

class Counter {
    // Static class data - shared across all instances
    static int instance_count = 0;
    static mapping(string:int) registry = ([]);

    protected string name;

    void create(string name_) {
        name = name_;
        instance_count++;
        registry[name_] = instance_count;
    }

    void destroy() {
        instance_count--;
        m_delete(registry, name);
    }

    // Static class method
    static int get_instance_count() {
        return instance_count;
    }
}

Counter c1 = Counter("first");
Counter c2 = Counter("second");
write("Instances: %d\n", Counter->get_instance_count());  // 2
```

---

## Creating Hierarchical Modules

### Module Organization

```pike
//-----------------------------
// Recipe: Nested module structure
//-----------------------------

// Directory structure:
// MyApp/
//   MyApp.pmod
//   Utils.pmod/
//     String.pmod
//     Math.pmod

// File: MyApp.pmod
#pragma strict_types

constant VERSION = "2.0.0";

// This makes Utils available as MyApp.Utils
import .Utils;

// File: MyApp/Utils/String.pmod
#pragma strict_types

//! String manipulation utilities.
string title_case(string s) {
    return String.capitalize(lower_case(s));
}

// File: MyApp/Utils/Math.pmod
#pragma strict_types

//! Math operations.
int add(int a, int b) {
    return a + b;
}
```

---

## Access Control

### Public, Protected, Private

```pike
//-----------------------------
// Recipe: Controlling member visibility
//-----------------------------

#pragma strict_types

class SecureData {
    // Public - accessible from anywhere
    public constant API_VERSION = "1.0";

    // Protected - accessible in this class and subclasses
    protected string _internal_state = "";

    // Private - only in this class
    private string _private_key = "secret";

    public string get_state() {
        return _internal_state;
    }

    protected void set_state(string new_state) {
        _internal_state = new_state;
    }

    private void _encrypt(string data) {
        // Implementation
    }
}
```

---

## Inheritance

### Single Inheritance

```pike
//-----------------------------
// Recipe: Base and derived classes
//-----------------------------

#pragma strict_types

class Shape {
    protected string name;

    void create(string name_) {
        name = name_;
    }

    public float area() {
        return 0.0;
    }

    public void describe() {
        write("%s: area=%.2f\n", name, area());
    }
}

class Circle {
    inherit Shape;

    protected float radius;

    void create(float r) {
        ::create("Circle");
        radius = r;
    }

    public float area() {
        return Math.PI * radius * radius;
    }
}

class Rectangle {
    inherit Shape;

    protected float width;
    protected float height;

    void create(float w, float h) {
        ::create("Rectangle");
        width = w;
        height = h;
    }

    public float area() {
        return width * height;
    }
}

// Polymorphism in action
array(Shape) shapes = ({
    Circle(2.5),
    Rectangle(3.0, 4.0)
});

foreach(shapes; Shape shape) {
    shape->describe();
}
```

### Multiple Inheritance

```pike
//-----------------------------
// Recipe: Multiple inheritance
//-----------------------------

#pragma strict_types

class Drawable {
    public void draw() {
        write("Drawing...\n");
    }
}

class Serializable {
    public string serialize() {
        return "serialized data";
    }
}

class Sprite {
    inherit Drawable;
    inherit Serializable;

    protected int x = 0;
    protected int y = 0;

    void move(int dx, int dy) {
        x += dx;
        y += dy;
    }
}

Sprite sprite = Sprite();
sprite->draw();        // From Drawable
write("%s\n", sprite->serialize());  // From Serializable
```

---

## Accessing Overridden Methods

### Calling Parent Methods

```pike
//-----------------------------
// Recipe: Use :: to access parent methods
//-----------------------------

#pragma strict_types

class Vehicle {
    protected string make;
    protected string model;

    void create(string make_, string model_) {
        ::create(make_, model_);
        write("Vehicle created: %s %s\n", make_, model_);
    }

    public string get_info() {
        return sprintf("%s %s", make, model);
    }
}

class Car {
    inherit Vehicle;

    protected int num_doors;

    void create(string make_, string model_, int doors) {
        ::create(make_, model_);  // Call parent constructor
        num_doors = doors;
    }

    public string get_info() {
        // Extend parent method
        return ::get_info() + sprintf(" (%d doors)", num_doors);
    }
}

Car car = Car("Toyota", "Camry", 4);
write("%s\n", car->get_info());  // "Toyota Camry (4 doors)"
```

---

## Operator Overloading

### Custom Operators

```pike
//-----------------------------
// Recipe: Overload operators for custom behavior
//-----------------------------

#pragma strict_types

class Complex {
    public float real;
    public float imag;

    void create(float r, float i) {
        real = r;
        imag = i;
    }

    // Overload +
    public Complex `+(mixed other) {
        if (!objectp(other) || object_program(other) != Complex)
            error("Can only add Complex to Complex\n");
        return Complex(real + other->real, imag + other->imag);
    }

    // Overload ==
    public int `==(mixed other) {
        return objectp(other) &&
               object_program(other) == Complex &&
               real == other->real &&
               imag == other->imag;
    }

    public string _sprintf(int type) {
        if (type == 'O' || type == 's') {
            return sprintf("Complex(%.2f%+.2fi)", real, imag);
        }
        return sprintf("%O", this);
    }
}

Complex c1 = Complex(3.0, 4.0);
Complex c2 = Complex(1.0, 2.0);

Complex sum = c1 + c2;
write("Sum: %s\n", sum);  // Complex(4.00+6.00i)

if (sum == Complex(4.0, 6.0)) {
    write("Equality works\n");
}
```

---

## Closure-based Objects

### Closures as Objects

```pike
//-----------------------------
// Recipe: Use closures instead of classes
//-----------------------------

#pragma strict_types

// Counter using closure
function(int:void) create_counter(int start) {
    int count = start;
    return lambda(int delta) {
        count += delta;
        write("Count: %d\n", count);
    };
}

function(int:void) counter1 = create_counter(0);
function(int:void) counter2 = create_counter(100);

counter1(1);   // Output: Count: 1
counter2(10);  // Output: Count: 110

// Getter/setter using closure
mapping(string:function) create_property(mixed initial_value) {
    mixed value = initial_value;
    return ([
        "get": lambda() { return value; },
        "set": lambda(mixed new_val) { value = new_val; }
    ]);
}

mapping(string:function) prop = create_property("test");
write("%s\n", prop["get"]());  // "test"
prop["set"]("updated");
write("%s\n", prop["get"]());  // "updated"
```

---

## Cloning Objects

### Deep Copy

```pike
//-----------------------------
// Recipe: Clone objects with copy_value()
//-----------------------------

#pragma strict_types

class Widget {
    public string name;
    public int id;
    public array(mixed) data;

    void create(string name_, int id_) {
        name = name_;
        id = id_;
        data = ({});
    }

    public Widget clone() {
        Widget w = Widget(name, id);
        w->data = copy_value(data);  // Deep copy
        return w;
    }
}

Widget original = Widget("widget", 1);
original->data = ({1, 2, 3});

Widget cloned = original->clone();
cloned->data[0] = 99;

write("Original: %O\n", original->data);  // ({99, 2, 3})
write("Clone: %O\n", cloned->data);    // ({99, 2, 3})

// For complete independence
cloned->data = copy_value(original->data);
```

---

## See Also

- [Modules](/docs/advanced/modules) - Code organization
- [References](/docs/advanced/references) - Advanced data structures
- [Process Management](/docs/advanced/processes) - IPC and communication
- [Lambda Expressions](/docs/basics/subroutines) - Closures and functional programming
