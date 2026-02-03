---
id: classesetc
title: Classes, Objects, and Ties
sidebar_label: Classes, Objects, and Ties
---

## Introduction

```pike
// Classes, Objects, and Ties in Pike 8
#pragma strict_types

// Modern class definitions with type safety
class Person {
    public string name;
    private int _age;

    void create(string name, int age) {
        this->name = name;
        this->_age = age;
    }

    public int get_age() { return _age; }
    public void birthday() { _age++; }
}

// Usage
Person p = Person("Alice", 30);
write("Name: %s\n", p->name);
write("Age: %d\n", p->get_age());
p->birthday();
write("After birthday: %d\n", p->get_age());
```

## Class Inheritance

```pike
// Recipe 13.1: Class Inheritance
#pragma strict_types

class Animal {
    public string name;

    void create(string name) {
        this->name = name;
    }

    public void make_sound() {
        write("Some sound\n");
    }
}

class Dog {
    inherit Animal;

    void create(string name) {
        ::create(name);
    }

    public void make_sound() {
        write("%s barks: Woof!\n", name);
    }
}

class Cat {
    inherit Animal;

    void create(string name) {
        ::create(name);
    }

    public void make_sound() {
        write("%s meows: Meow!\n", name);
    }
}

// Usage
Dog dog = Dog("Rex");
Cat cat = Cat("Whiskers");
dog->make_sound();
cat->make_sound();
```

## Abstract Classes

```pike
// Recipe 13.2: Abstract Classes
#pragma strict_types

class Shape {
    // Abstract method (must be implemented by subclasses)
    public float calculate_area();

    public void display_info() {
        write("Shape area: %.2f\n", calculate_area());
    }
}

class Circle {
    inherit Shape;
    private float radius;

    void create(float r) {
        radius = r;
    }

    public float calculate_area() {
        return 3.14159 * radius * radius;
    }
}

class Rectangle {
    inherit Shape;
    private float width;
    private float height;

    void create(float w, float h) {
        width = w;
        height = h;
    }

    public float calculate_area() {
        return width * height;
    }
}

// Usage
Circle circle = Circle(5.0);
Rectangle rect = Rectangle(4.0, 6.0);
circle->display_info();
rect->display_info();
```

## Interfaces

```pike
// Recipe 13.3: Interface Implementation
#pragma strict_types

// Interface-like behavior using multiple inheritance
class Serializable {
    public string serialize() {
        return sprintf("Object of %O", this);
    }
}

class Loggable {
    public void log(string message) {
        write("[LOG] %s: %s\n", ctime(time()), message);
    }
}

class User {
    inherit Serializable;
    inherit Loggable;

    public string username;
    public string email;

    void create(string username, string email) {
        this->username = username;
        this->email = email;
        log("User created: " + username);
    }
}

// Usage
User user = User("alice", "alice@example.com");
write("Serialized: %s\n", user->serialize());
user->log("User logged in");
```

## Method Overriding

```pike
// Recipe 13.4: Method Overriding
#pragma strict_types

class Vehicle {
    public string brand;

    void create(string brand) {
        this->brand = brand;
    }

    public void start() {
        write("Vehicle starting...\n");
    }

    public void stop() {
        write("Vehicle stopping...\n");
    }
}

class Car {
    inherit Vehicle;

    void create(string brand) {
        ::create(brand);
    }

    public void start() {
        write("Car %s starting with ignition...\n", brand);
    }

    public void honk() {
        write("Car %s: Beep beep!\n", brand);
    }
}

// Usage
Car car = Car("Toyota");
car->start();
car->honk();
car->stop();
```

## Operator Overloading

```pike
// Recipe 13.5: Operator Overloading
#pragma strict_types

class Vector {
    public int x;
    public int y;

    void create(int x, int y) {
        this->x = x;
        this->y = y;
    }

    // Addition operator
    Vector `+(Vector other) {
        return Vector(x + other->x, y + other->y);
    }

    // Subtraction operator
    Vector `-(Vector other) {
        return Vector(x - other->x, y - other->y);
    }

    // String representation
    string _sprintf(int|void type) {
        if (type == 'O') {
            return sprintf("Vector(%d, %d)", x, y);
        }
        return 0;
    }
}

// Usage
Vector v1 = Vector(3, 4);
Vector v2 = Vector(1, 2);
Vector v3 = v1 + v2;
Vector v4 = v1 - v2;
write("v1: %s\n", v1);
write("v2: %s\n", v2);
write("v1 + v2: %s\n", v3);
write("v1 - v2: %s\n", v4);
```

## Static Methods

```pike
// Recipe 13.6: Static Methods
#pragma strict_types

class MathUtils {
    private static int _counter = 0;

    // Static method
    static int add(int a, int b) {
        _counter++;
        return a + b;
    }

    static int multiply(int a, int b) {
        _counter++;
        return a * b;
    }

    static int get_call_count() {
        return _counter;
    }

    // Non-static method
    public int get_result(int a, int b, string operation) {
        switch(operation) {
            case "add": return add(a, b);
            case "multiply": return multiply(a, b);
            default: return 0;
        }
    }
}

// Usage
int sum = MathUtils->add(5, 3);
int product = MathUtils->multiply(4, 6);
write("Sum: %d\n", sum);
write("Product: %d\n", product);
write("Total calls: %d\n", MathUtils->get_call_count());

MathUtils utils = MathUtils();
write("Result: %d\n", utils->get_result(2, 3, "add"));
```

## Class Variables

```pike
// Recipe 13.7: Class Variables
#pragma strict_types

class DatabaseConnection {
    private static int _connection_count = 0;
    private static string _host = "localhost";
    private static int _port = 5432;

    private string _connection_id;

    void create() {
        _connection_count++;
        _connection_id = sprintf("conn_%d", _connection_count);
        write("Connection %s created to %s:%d\n",
              _connection_id, _host, _port);
    }

    public string get_id() { return _connection_id; }
    public int get_connection_count() { return _connection_count; }

    // Static accessors
    static string get_host() { return _host; }
    static void set_host(string host) { _host = host; }
    static int get_port() { return _port; }
    static void set_port(int port) { _port = port; }
}

// Usage
DatabaseConnection conn1 = DatabaseConnection();
DatabaseConnection conn2 = DatabaseConnection();
write("Total connections: %d\n", conn1->get_connection_count());
write("Connection 1 ID: %s\n", conn1->get_id());
write("Connection 2 ID: %s\n", conn2->get_id());

DatabaseConnection->set_host("newhost.example.com");
write("New host: %s\n", DatabaseConnection->get_host());
```

## Object Lifecycle

```pike
// Recipe 13.8: Object Lifecycle
#pragma strict_types

class Resource {
    private string _name;
    private int _active = 1;

    void create(string name) {
        _name = name;
        write("Resource %s created\n", _name);
    }

    void destroy() {
        write("Resource %s destroyed\n", _name);
    }

    public void use() {
        if (_active) {
            write("Using resource %s\n", _name);
        } else {
            error("Resource %s is destroyed\n", _name);
        }
    }
}

// Usage
Resource res = Resource("test");
res->use();

// Automatic destruction when out of scope
{
    Resource temp = Resource("temporary");
    temp->use();
}
write("Resource should be destroyed by now\n");
```