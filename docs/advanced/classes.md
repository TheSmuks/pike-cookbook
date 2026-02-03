---
id: classes
title: Classes and Objects
sidebar_label: Classes and Objects
---

## Introduction

Pike 8 is a modern object-oriented language with first-class support for classes, objects, inheritance, polymorphism, and encapsulation. This chapter covers Pike's object-oriented programming features including:

- Class declaration and instantiation
- Methods and properties with type annotations
- Single and multiple inheritance
- Access control and encapsulation
- Operator overloading
- Static members and class methods
- Lambda functions and closures
- Concurrent programming with objects

Pike 8 introduces enhanced type safety with `#pragma strict_types`, improved syntax, and better integration with modern asynchronous patterns using `Concurrent.Future`.

```pike
// Simple Person class with Pike 8 features
pragma strict_types

class Person {
    protected string name;
    protected int age;

    void create(string name_, int age_) {
        name = name_;
        age = age_;
    }

    public string get_name() {
        return name;
    }

    public string _sprintf(int type) {
        return sprintf("Person(%s, %d)", name, age);
    }
}

// Usage
Person p = Person("Alice", 30);
write("%s\n", p);  // Output: Person(Alice, 30)
```

## Constructing an Object

Pike uses the `create()` method as the constructor. The constructor is called automatically when you instantiate an object using the `ClassName()` syntax.

```pike
pragma strict_types

class Employee {
    protected string name;
    protected int id;
    protected float salary;

    // Constructor with required parameters
    void create(string name_, int id_, float salary_) {
        name = name_;
        id = id_;
        salary = salary_;
    }

    // Constructor with default values
    void create(string name_, int id_, void|float salary_) {
        name = name_;
        id = id_;
        salary = undefinedp(salary_) ? 0.0 : salary_;
    }
}

// Creating objects
Employee emp1 = Employee("Bob", 1001, 50000.0);
Employee emp2 = Employee("Carol", 1002);  // salary defaults to 0.0
```

Pike 8 supports named parameters and optional parameters for more flexible constructors:

```pike
pragma strict_types

class Config {
    protected mapping(string:string) options;

    // Constructor with optional mapping parameter
    void create(void|mapping(string:string) opts) {
        options = opts || ([]);
    }

    public string get(string key, void|string default_) {
        return options[key] || default_ || "";
    }
}

Config cfg1 = Config();
Config cfg2 = Config((["host": "localhost", "port": "8080"]));
```

## Destroying an Object

Pike automatically handles object destruction through garbage collection. You can define a `destroy()` method for cleanup when an object is garbage collected.

```pike
pragma strict_types

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

// Object is automatically destroyed when out of scope
void test_connection() {
    DatabaseConnection db = DatabaseConnection("postgresql://localhost/test");
    write("Working with database...\n");
}  // destroy() called here

test_connection();
```

For explicit resource management, Pike 8 works well with `Concurrent.Future` and scoping:

```pike
pragma strict_types

class Resource {
    protected string name;

    void create(string name_) {
        name = name_;
        write("Acquired: %s\n", name);
    }

    void destroy() {
        write("Released: %s\n", name);
    }

    public void use() {
        write("Using: %s\n", name);
    }
}

// Using a block to control lifetime
{
    Resource r = Resource("file.txt");
    r->use();
}  // r destroyed here
```

## Managing Instance Data

Instance data in Pike is managed through member variables. Use access modifiers to control visibility:

```pike
pragma strict_types

class BankAccount {
    // Private instance data (protected visibility)
    protected string account_number;
    protected float balance;
    protected string owner;

    // Public constant
    public constant OVERDRAFT_FEE = 35.0;

    // Constructor
    void create(string owner_, string acct_num) {
        owner = owner_;
        account_number = acct_num;
        balance = 0.0;
    }

    // Public getter methods
    public string get_owner() {
        return owner;
    }

    public float get_balance() {
        return balance;
    }

    // Public setter with validation
    public int deposit(float amount) {
        if (amount <= 0) {
            return 0;  // Failure
        }
        balance += amount;
        return 1;  // Success
    }

    public int withdraw(float amount) {
        if (amount <= 0 || amount > balance) {
            return 0;  // Failure
        }
        balance -= amount;
        return 1;  // Success
    }
}

BankAccount acct = BankAccount("Alice", "123-456");
acct->deposit(100.0);
acct->withdraw(50.0);
write("Balance: $%.2f\n", acct->get_balance());
```

Pike 8 supports property-like syntax with optional type annotations:

```pike
pragma strict_types

class User {
    private string _email;

    void create(string email_) {
        _email = validate_email(email_) ? email_ : "";
    }

    public string get_email() {
        return _email;
    }

    public void set_email(string email) {
        if (validate_email(email)) {
            _email = email;
        }
    }

    private bool validate_email(string email) {
        return has_value(email, "@") && has_value(email, ".");
    }
}

User u = User("user@example.com");
write("%s\n", u->get_email());
u->set_email("new@example.com");
```

## Managing Class Data

Static class data is shared across all instances. Use `static` for class-level variables:

```pike
pragma strict_types

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

    static mapping(string:int) get_registry() {
        return registry;
    }
}

Counter c1 = Counter("first");
Counter c2 = Counter("second");
Counter c3 = Counter("third");

write("Instances: %d\n", Counter->get_instance_count());  // Output: 3
write("Registry: %O\n", Counter->get_registry());
```

Class constants are defined using `constant`:

```pike
pragma strict_types

class MathConstants {
    public constant PI = 3.141592653589793;
    public constant E = 2.718281828459045;
    public constant GOLDEN_RATIO = 1.618033988749895;
}

write("PI: %f\n", MathConstants->PI);
write("E: %f\n", MathConstants->E);
```

## Using Classes as Structs

Pike classes work well as lightweight structs. Use the `mapping` type for simple data structures, or create proper classes for type safety:

```pike
pragma strict_types

// Simple struct-like class
class Point {
    public float x;
    public float y;

    void create(void|float x_, void|float y_) {
        x = undefinedp(x_) ? 0.0 : x_;
        y = undefinedp(y_) ? 0.0 : y_;
    }

    public float distance(Point other) {
        float dx = x - other->x;
        float dy = y - other->y;
        return sqrt(dx*dx + dy*dy);
    }
}

Point p1 = Point(3.0, 4.0);
Point p2 = Point(0.0, 0.0);
write("Distance: %f\n", p1->distance(p2));  // Output: 5.0

// Alternative: using mapping for simple structs
mapping point = (["x": 3.0, "y": 4.0]);
write("Point: (%.1f, %.1f)\n", point->x, point->y);

// Safe property access with Pike 8
float? x = point->"x";  // Returns 3.0
float? z = point->"z";  // Returns UNDEFINED

// Safe access with default
float z_safe = point->"z" || 0.0;
```

For more complex structs, use factory functions:

```pike
pragma strict_types

// Record factory function
fun make_person = lambda(string name, int age, string email) {
    return ([
        "name": name,
        "age": age,
        "email": email,
        "created": time()
    ]);
};

mapping(string:mixed) person = make_person("Dave", 25, "dave@example.com");
```

## Cloning Objects

Pike provides several ways to clone objects. The simplest is to create a new instance with the same data:

```pike
pragma strict_types

class Widget {
    public string name;
    public int id;
    public array(mixed) data;

    void create(string name_, int id_) {
        name = name_;
        id = id_;
        data = ({});
    }

    // Clone method
    public Widget clone() {
        Widget w = Widget(name, id);
        w->data = data + ({});  // Shallow copy of array
        return w;
    }

    // Deep clone method
    public Widget deep_clone() {
        Widget w = Widget(name, id);
        w->data = copy_value(data);  // Deep copy
        return w;
    }
}

Widget original = Widget("gadget", 1);
original->data = ({1, 2, 3});

Widget shallow = original->clone();
Widget deep = original->deep_clone();

original->data[0] = 99;
write("Original: %O\n", original->data);  // ({99, 2, 3})
write("Shallow: %O\n", shallow->data);    // ({99, 2, 3}) - shared reference!
write("Deep: %O\n", deep->data);        // ({1, 2, 3}) - independent copy
```

Use `copy_value()` for deep copying complex structures:

```pike
pragma strict_types

class Config {
    public mapping(string:mixed) settings;

    void create() {
        settings = ([]);
    }

    // Create a deep copy
    public Config copy() {
        Config c = Config();
        c->settings = copy_value(settings);
        return c;
    }
}

Config config1 = Config();
config1->settings = ([
    "database": (["host": "localhost", "port": 5432]),
    "features": ({"auth", "cache", "api"})
]);

Config config2 = config1->copy();
config2->settings->database->host = "remote";

write("Config1 host: %s\n", config1->settings->database->host);  // localhost
write("Config2 host: %s\n", config2->settings->database->host);  // remote
```

## Calling Methods Indirectly

Pike supports several ways to call methods indirectly, including function references and the arrow operator:

```pike
pragma strict_types

class Calculator {
    public float add(float a, float b) { return a + b; }
    public float subtract(float a, float b) { return a - b; }
    public float multiply(float a, float b) { return a * b; }
    public float divide(float a, float b) { return a / b; }
}

Calculator calc = Calculator();

// Direct method call
float result1 = calc->add(5.0, 3.0);

// Method reference
fun add_ref = calc->add;
float result2 = add_ref(5.0, 3.0);

// Dynamic method name
string method_name = "multiply";
fun method = calc[method_name];
float result3 = method(5.0, 3.0);

// Using call_function
float result4 = call_function(calc->subtract, 5.0, 3.0);
```

For method dispatch tables, use mappings:

```pike
pragma strict_types

class CommandProcessor {
    public void handle_create(mapping data) { write("Creating: %O\n", data); }
    public void handle_update(mapping data) { write("Updating: %O\n", data); }
    public void handle_delete(mapping data) { write("Deleting: %O\n", data); }
    public void handle_default(mapping data) { write("Unknown: %O\n", data); }

    // Dispatch table
    private mapping(string:fun) handlers;

    void create() {
        handlers = ([
            "create": handle_create,
            "update": handle_update,
            "delete": handle_delete
        ]);
    }

    public void process(string action, mapping data) {
        fun handler = handlers[action] || handle_default;
        handler(data);
    }
}

CommandProcessor proc = CommandProcessor();
proc->process("create", (["id": 1]));
proc->process("update", (["id": 1, "name": "Test"]));
proc->process("unknown", (["id": 1]));
```

## Determining Subclass Membership

Use Pike's type checking system and the `object_program()` function to determine class relationships:

```pike
pragma strict_types

class Animal {
    public string name;

    void create(string name_) {
        name = name_;
    }

    public void speak() {
        write("%s makes a sound\n", name);
    }
}

class Dog {
    inherit Animal;

    void create(string name_) {
        ::create(name_);
    }

    public void bark() {
        write("%s barks!\n", name);
    }
}

class Cat {
    inherit Animal;

    void create(string name_) {
        ::create(name_);
    }

    public void meow() {
        write("%s meows!\n", name);
    }
}

// Check object type
void check_type(object obj) {
    // Get the program (class) of the object
    program p = object_program(obj);

    write("Object type: %s\n", master()->describe_program(p));

    // Check inheritance
    if (object_program(obj) == Dog) {
        write("This is a Dog\n");
    } else if (object_program(obj) == Cat) {
        write("This is a Cat\n");
    }

    // Check if object inherits from Animal
    if (Program.inherits(object_program(obj), Animal)) {
        write("This is an Animal\n");
    }
}

Animal generic = Animal("Creature");
Dog dog = Dog("Buddy");
Cat cat = Cat("Whiskers");

check_type(generic);
check_type(dog);
check_type(cat);
```

Use `catch()` for safe type-based dispatch:

```pike
pragma strict_types

void handle_animal(Animal animal) {
    // Try to call Dog-specific method
    if (catch {
        (Dog)animal->bark();
        write("Handled as Dog\n");
    }) {
        write("Not a Dog\n");
    }

    // Or use object_program check
    if (object_program(animal) == Dog) {
        (Dog)animal->bark();
    }
}
```

## Writing an Inheritable Class

Pike supports single and multiple inheritance using the `inherit` keyword. Base classes should be designed with protected methods that can be overridden:

```pike
pragma strict_types

class Shape {
    protected string name;

    void create(string name_) {
        name = name_;
    }

    // Virtual method - to be overridden
    public float area() {
        return 0.0;
    }

    public float perimeter() {
        return 0.0;
    }

    // Template method
    public void describe() {
        write("%s: area=%.2f, perimeter=%.2f\n",
              name, area(), perimeter());
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

    public float perimeter() {
        return 2 * (width + height);
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

    public float perimeter() {
        return 2 * Math.PI * radius;
    }
}

array(Shape) shapes = ({
    Rectangle(5.0, 3.0),
    Circle(2.5),
    Rectangle(10.0, 4.0)
});

foreach(shapes; int i; Shape shape) {
    shape->describe();
}
```

Multiple inheritance in Pike:

```pike
pragma strict_types

class Drawable {
    public void draw() {
        write("Drawing...\n");
    }
}

class Serializable {
    public string serialize() {
        return "serialized data";
    }

    public void deserialize(string data) {
        write("Deserializing: %s\n", data);
    }
}

class Sprite {
    inherit Drawable;
    inherit Serializable;

    protected int x = 0;
    protected int y = 0;

    public void move(int dx, int dy) {
        x += dx;
        y += dy;
        write("Moved to (%d, %d)\n", x, y);
    }
}

Sprite sprite = Sprite();
sprite->draw();
sprite->move(10, 20);
write("%s\n", sprite->serialize());
```

## Accessing Overridden Methods

Use the scope resolution operator `::` to call overridden methods from parent classes:

```pike
pragma strict_types

class Vehicle {
    protected string make;
    protected string model;

    void create(string make_, string model_) {
        make = make_;
        model = model_;
        write("Vehicle created: %s %s\n", make, model);
    }

    public string get_info() {
        return sprintf("%s %s", make, model);
    }

    public void start() {
        write("Vehicle starting...\n");
    }
}

class Car {
    inherit Vehicle;

    protected int num_doors;

    void create(string make_, string model_, int doors) {
        ::create(make_, model_);  // Call parent constructor
        num_doors = doors;
    }

    // Override and extend
    public string get_info() {
        // Call parent method and extend
        return ::get_info() + sprintf(" (%d doors)", num_doors);
    }

    // Override with completely different behavior
    public void start() {
        write("Car engine roaring!\n");
    }
}

Car car = Car("Toyota", "Camry", 4);
write("%s\n", car->get_info());
car->start();
```

With multiple inheritance, specify which parent to call:

```pike
pragma strict_types

class Logger {
    public void log(string msg) {
        write("[LOG] %s\n", msg);
    }
}

class Validator {
    public bool validate(string data) {
        return sizeof(data) > 0;
    }
}

class DataProcessor {
    inherit Logger;
    inherit Validator;

    public void process(string data) {
        // Call validate from Validator parent
        if (Validator::validate(data)) {
            Logger::log("Processing: " + data);
        }
    }
}

DataProcessor proc = DataProcessor();
proc->process("test data");
```

## Generating Attribute Methods Using AUTOLOAD

Pike doesn't have AUTOLOAD like Perl, but you can create dynamic getters and setters using `->()` and `[]()` operators. For dynamic method handling, use these special methods:

```pike
pragma strict_types

class DynamicObject {
    protected mapping(string:mixed) attributes = ([]);

    // Override the [] operator for attribute access
    mixed `[](string key) {
        return attributes[key];
    }

    // Override the []= operator for attribute setting
    mixed `[]=(string key, mixed value) {
        attributes[key] = value;
        return value;
    }

    // Override _indices to list all attributes
    array _indices() {
        return indices(attributes);
    }

    // Override _values to get all values
    array _values() {
        return values(attributes);
    }

    // Check if attribute exists
    public bool has_attribute(string key) {
        return has_index(attributes, key);
    }
}

DynamicObject obj = DynamicObject();
obj->name = "Alice";
obj->age = 30;
obj->email = "alice@example.com";

write("Name: %s\n", obj->name);
write("Age: %d\n", obj->age);

foreach(indices(obj); int i; string key) {
    write("%s: %O\n", key, obj[key]);
}
```

For method generation, use a factory pattern:

```pike
pragma strict_types

class PropertyAccessor {
    protected mapping(string:mixed) data = ([]);

    void create(array(string) property_names) {
        // Create getter and setter for each property
        foreach(property_names; int i; string prop) {
            data[prop] = UNDEFINED;
        }
    }

    // Generic getter
    public mixed get(string prop) {
        return data[prop];
    }

    // Generic setter
    public void set(string prop, mixed value) {
        data[prop] = value;
    }
}

PropertyAccessor person = PropertyAccessor(({"name", "age", "city"}));
person->set("name", "Bob");
person->set("age", 25);
write("%s is %d years old\n", person->get("name"), person->get("age"));
```

## Solving the Data Inheritance Problem

When using inheritance in Pike, each class maintains its own instance data. To share data properly, design your classes with clear separation of concerns:

```pike
pragma strict_types

// Base class with common data
class Entity {
    protected int id;
    protected string name;
    protected int created_at;

    void create(int id_, string name_) {
        id = id_;
        name = name_;
        created_at = time();
    }

    public int get_id() { return id; }
    public string get_name() { return name; }
}

// User extends Entity with its own data
class User {
    inherit Entity;

    protected string email;
    protected string password_hash;
    protected bool is_active = true;

    void create(int id_, string name_, string email_) {
        ::create(id_, name_);
        email = email_;
    }

    public string get_email() { return email; }
    public bool active() { return is_active; }
}

// Product extends Entity with different data
class Product {
    inherit Entity;

    protected float price;
    protected int stock_qty;

    void create(int id_, string name_, float price_) {
        ::create(id_, name_);
        price = price_;
        stock_qty = 0;
    }

    public float get_price() { return price; }
    public int get_stock() { return stock_qty; }
}

User user = User(1, "Alice", "alice@example.com");
Product product = Product(100, "Widget", 29.99);

write("User: %s (%s)\n", user->get_name(), user->get_email());
write("Product: %s ($%.2f)\n", product->get_name(), product->get_price());
```

For complex hierarchies, use composition over inheritance:

```pike
pragma strict_types

// Component: Timestamps
class Timestamps {
    protected int created_at;
    protected int updated_at;

    void create() {
        created_at = time();
        updated_at = time();
    }

    public void touch() {
        updated_at = time();
    }

    public int get_created() { return created_at; }
    public int get_updated() { return updated_at; }
}

// Component: Identifiable
class Identifiable {
    protected int id;

    public void set_id(int id_) { id = id_; }
    public int get_id() { return id; }
}

// Main class using composition
class Article {
    private Timestamps timestamps;
    private Identifiable identifiable;

    protected string title;
    protected string content;

    void create(string title_, string content_) {
        timestamps = Timestamps();
        identifiable = Identifiable();
        title = title_;
        content = content_;
    }

    // Delegate to components
    public void set_id(int id_) { identifiable->set_id(id_); }
    public int get_id() { return identifiable->get_id(); }
    public void touch() { timestamps->touch(); }
    public int get_created() { return timestamps->get_created(); }

    public string get_title() { return title; }
    public string get_content() { return content; }
}

Article article = Article("Hello World", "My first article");
article->set_id(42);
write("Article %d: %s\n", article->get_id(), article->get_title());
```

## Coping with Circular Data Structures

Circular references can prevent proper garbage collection. Use weak references or explicitly break cycles:

```pike
pragma strict_types

class Node {
    public string name;
    public array(Node) children = ({});
    public Node|zero parent = 0;

    void create(string name_) {
        name = name_;
    }

    void destroy() {
        write("Destroying node: %s\n", name);
    }

    public void add_child(Node child) {
        children += ({child});
        child->parent = this;  // Creates circular reference!
    }

    // Explicitly break the cycle
    public void cleanup() {
        foreach(children; int i; Node child) {
            child->parent = 0;
        }
        children = ({});
    }
}

// Create a circular structure
Node parent = Node("parent");
Node child = Node("child");
parent->add_child(child);

// Clean up explicitly to break the cycle
parent->cleanup();
child->cleanup();
```

Use `_destruct` for automatic cleanup:

```pike
pragma strict_types

class GraphNode {
    public string id;
    public mapping(string:GraphNode) neighbors = ([]);

    void create(string id_) {
        id = id_;
    }

    void add_edge(GraphNode other) {
        neighbors[other->id] = other;
        other->neighbors[id] = this;
    }

    // Break all references on destruction
    void destroy() {
        foreach(neighbors; string nid; GraphNode node) {
            m_delete(node->neighbors, id);
        }
        neighbors = ([]);
    }
}

GraphNode a = GraphNode("A");
GraphNode b = GraphNode("B");
a->add_edge(b);
// Edges automatically cleaned up when nodes are destroyed
```

## Overloading Operators

Pike allows operator overloading by implementing special methods. Define operators like `+`, `==`, `_sprintf()`, etc:

```pike
pragma strict_types

class Complex {
    public float real;
    public float imag;

    void create(float r, float i) {
        real = r;
        imag = i;
    }

    // Overload + operator
    public Complex `+(mixed other) {
        if (!objectp(other) || object_program(other) != Complex)
            error("Can only add Complex to Complex\n");
        return Complex(real + other->real, imag + other->imag);
    }

    // Overload - operator
    public Complex `-(mixed other) {
        if (!objectp(other) || object_program(other) != Complex)
            error("Can only subtract Complex from Complex\n");
        return Complex(real - other->real, imag - other->imag);
    }

    // Overload * operator
    public Complex `*(mixed other) {
        if (!objectp(other) || object_program(other) != Complex)
            error("Can only multiply Complex by Complex\n");
        // (a+bi)(c+di) = (ac-bd) + (ad+bc)i
        float r = real * other->real - imag * other->imag;
        float i = real * other->imag + imag * other->real;
        return Complex(r, i);
    }

    // Overload == operator
    public int `==(mixed other) {
        return objectp(other) &&
               object_program(other) == Complex &&
               real == other->real &&
               imag == other->imag;
    }

    // String representation
    public string _sprintf(int type) {
        if (type == 'O' || type == 's') {
            return sprintf("Complex(%.2f%+.2fi)", real, imag);
        }
        return sprintf("%O", this);
    }

    // Hash value for use in mappings
    public int _hash() {
        return hash_value(real) ^ hash_value(imag);
    }
}

Complex c1 = Complex(3.0, 4.0);
Complex c2 = Complex(1.0, 2.0);

Complex sum = c1 + c2;
Complex diff = c1 - c2;
Complex product = c1 * c2;

write("c1: %s\n", c1);
write("c2: %s\n", c2);
write("sum: %s\n", sum);
write("diff: %s\n", diff);
write("product: %s\n", product);
```

More operator overloading examples:

```pike
pragma strict_types

class Vector {
    public array(float) elements;

    void create(array(float) elems) {
        elements = elems;
    }

    // Index access: v[index]
    public float `[](int index) {
        return elements[index];
    }

    // Index assignment: v[index] = value
    public float `[]=(int index, float value) {
        elements[index] = value;
        return value;
    }

    // Sizeof: sizeof(v)
    public int _sizeof() {
        return sizeof(elements);
    }

    // Iteration: foreach(v; int i; float val)
    public array _indices() {
        return indices(elements);
    }

    public array _values() {
        return values(elements);
    }

    // Comparison
    public int `==(mixed other) {
        return objectp(other) &&
               object_program(other) == Vector &&
               equal(elements, other->elements);
    }

    public string _sprintf(int type) {
        return sprintf("Vector(%s)", sprintf("%O", elements));
    }
}

Vector v = Vector(({1.0, 2.0, 3.0, 4.0}));
write("%s\n", v);
write("Size: %d\n", sizeof(v));
write("v[1]: %f\n", v[1]);

v[2] = 10.0;
write("After v[2] = 10.0: %s\n", v);

foreach(v; int i; float val) {
    write("v[%d] = %f\n", i, val);
}
```

## Creating Magic Variables with tie

Pike doesn't have Perl's `tie()` mechanism, but you can achieve similar behavior using objects with operator overloading. Create wrapper objects that intercept all operations:

```pike
pragma strict_types

// Traced variable - logs all accesses
class TracedVariable {
    protected mixed value;
    protected string name;

    void create(string name_, mixed initial) {
        name = name_;
        value = initial;
        write("[TRACE] %s created with value: %O\n", name, value);
    }

    // Overload cast to mixed
    public mixed cast(program to) {
        if (to == typeof(value)) {
            write("[TRACE] %s read: %O\n", name, value);
        }
        return value;
    }

    // Assignment
    public mixed `=(mixed new_value) {
        write("[TRACE] %s: %O -> %O\n", name, value, new_value);
        value = new_value;
        return value;
    }

    public string _sprintf(int type) {
        return sprintf("TracedVariable(%s: %O)", name, value);
    }
}

// Validated variable
class ValidatedString {
    protected string value;
    protected function(string:int) validator;

    void create(function(string:int) validate_, string initial) {
        validator = validate_;
        set(initial);
    }

    public string get() {
        return value;
    }

    public void set(string new_value) {
        if (!validator(new_value)) {
            error("Invalid value: %s\n", new_value);
        }
        value = new_value;
    }

    public string _sprintf(int type) {
        return sprintf("%s", value);
    }
}

// Email validator
fun is_valid_email = lambda(string email) {
    return has_value(email, "@") && sizeof(email) > 3;
};

ValidatedString email = ValidatedString(is_valid_email, "user@example.com");
write("Email: %s\n", email->get());
email->set("admin@example.com");
```

Create lazy-evaluated variables using closures:

```pike
pragma strict_types

// Lazy-evaluated value
class Lazy {
    protected mixed _computed_value = UNDEFINED;
    protected bool _computed = false;
    protected fun _compute_fn;

    void create(fun compute_fn) {
        _compute_fn = compute_fn;
    }

    public mixed get() {
        if (!_computed) {
            _computed_value = _compute_fn();
            _computed = true;
            write("[LAZY] Computed value\n");
        }
        return _computed_value;
    }

    public void reset() {
        _computed = false;
        _computed_value = UNDEFINED;
    }
}

// Expensive computation
Lazy expensive_result = Lazy(lambda() {
    write("Computing expensive result...\n");
    // Simulate expensive work
    int sum = 0;
    for (int i = 0; i < 1000000; i++) {
        sum += i;
    }
    return sum;
});

write("First access: %d\n", expensive_result->get());
write("Second access: %d\n", expensive_result->get());  // Cached!
```

For advanced integration with Pike 8's async features, use `Concurrent.Future`:

```pike
pragma strict_types

import Concurrent.Future;

// Async wrapper that returns futures
class AsyncCache {
    protected mapping(string:Future) cache = ([]);

    public Future get(string key, fun fetch_fn) {
        // Return cached future if available
        if (cache[key]) {
            return cache[key];
        }

        // Create new future for the fetch
        Future result = fetch_fn();
        cache[key] = result;

        // Clean up on error
        result->on_failure(lambda(mixed err) {
            m_delete(cache, key);
        });

        return result;
    }
}

// Usage example
AsyncCache cache = AsyncCache();

fun fetch_user = lambda(string user_id) {
    // Simulate async fetch
    return Future(lambda(fun success, fun failure) {
        // In real code, this would be an async operation
        success(([ "id": user_id, "name": "User" + user_id ]));
    });
};

Future user_future = cache->get("123", fetch_user);
user_future->on_success(lambda(mapping user) {
    write("Got user: %O\n", user);
});
```