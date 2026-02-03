---
id: subroutines
title: Subroutines
sidebar_label: Subroutines
---

## Introduction

```pike
// Subroutines in Pike 8 - Advanced implementation
#pragma strict_types

// Complex function with multiple return types
mixed process_request(mapping(string:mixed) request) {
    if (request->action == "add") {
        return (int)request->a + (int)request->b;
    } else if (request->action == "multiply") {
        return (int)request->a * (int)request->b;
    } else if (request->action == "error") {
        error("Invalid request");
    }
    return UNDEFINED;
}

// Functional programming utilities
class FunctionalUtils {
    public function(mixed...:mixed) compose;
    public array(mixed) map;
    public mixed reduce;

    void create() {
        // Function composition
        compose = lambda(function(mixed:mixed) f1, function(mixed:mixed) f2) {
            return lambda(mixed x) { return f1(f2(x)); };
        };

        // Map function
        map = lambda(array(mixed) data, function(mixed:mixed) fn) {
            array(mixed) result = ({});
            foreach(data; mixed item) {
                result += ({fn(item)});
            }
            return result;
        };

        // Reduce function
        reduce = lambda(array(mixed) data, function(mixed,mixed:mixed) fn, mixed initial) {
            mixed result = initial;
            foreach(data; mixed item) {
                result = fn(result, item);
            }
            return result;
        };
    }
}

// Usage
FunctionalUtils utils = FunctionalUtils();
array(int) numbers = ({1, 2, 3, 4, 5});
array(int) squared = utils->map(numbers, lambda(int x) { return x * x; });
int sum = utils->reduce(numbers, lambda(int a, int b) { return a + b; }, 0);

write("Numbers: %s\n", numbers * ", ");
write("Squared: %s\n", squared * ", ");
write("Sum: %d\n", sum);
```

## High-Order Functions

```pike
// High-order function examples
#pragma strict_types

// Predicate function
bool is_even(int x) { return x % 2 == 0; }

// Filter function
array(mixed) filter(array(mixed) data, function(mixed:bool) predicate) {
    array(mixed) result = ({});
    foreach(data; mixed item) {
        if (predicate(item)) {
            result += ({item});
        }
    }
    return result;
}

// Partition function
array(array(mixed)) partition(array(mixed) data, function(mixed:bool) predicate) {
    array(mixed) true_part = ({});
    array(mixed) false_part = ({});

    foreach(data; mixed item) {
        if (predicate(item)) {
            true_part += ({item});
        } else {
            false_part += ({item});
        }
    }

    return ({true_part, false_part});
}

// Usage
array(int) nums = ({1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
array(int) evens = filter(nums, is_even);
array(array(int)) partitioned = partition(nums, is_even);

write("All numbers: %s\n", nums * ", ");
write("Even numbers: %s\n", evens * ", ");
write("Partitioned: [%s], [%s]\n",
      partitioned[0] * ", ", partitioned[1] * ", ");
```

## Currying

```pike
// Currying implementation
#pragma strict_types

// Curry function
function(mixed...) curry(function(mixed...:mixed) fn, mixed... args) {
    return lambda(mixed... more_args) {
        return fn(@args, @more_args);
    };
}

// Partial application
function(mixed...) partial_apply(function(mixed...:mixed) fn, mixed... args) {
    return lambda(mixed... more_args) {
        return fn(@args, @more_args);
    };
}

// Usage
function(int,int:int) add = lambda(int a, int b) { return a + b; };
function(int:int) add5 = curry(add, 5);
function(int,int:int) multiply = lambda(int a, int b) { return a * b; };
function(int:int) multiply_by_10 = partial_apply(multiply, 10);

write("Add 5 + 3 = %d\n", add5(3));
write("Multiply 10 * 7 = %d\n", multiply_by_10(7));
```

## Monads

```pike
// Simple Maybe monad implementation
#pragma strict_types

class Maybe {
    inherit ProgramWrapper;

    private mixed _value;
    private int _has_value;

    void create(mixed|void value) {
        _value = value;
        _has_value = value != UNDEFINED && value != 0;
    }

    public int has_value() { return _has_value; }
    public mixed get_value() { return _value; }

    public Maybe map(function(mixed:mixed) fn) {
        if (has_value()) {
            return Maybe(fn(_value));
        }
        return this;
    }

    public Maybe bind(function(mixed:Maybe) fn) {
        if (has_value()) {
            return fn(_value);
        }
        return this;
    }

    public mixed get_default(mixed default_value) {
        return has_value() ? _value : default_value;
    }
}

// Usage
Maybe number = Maybe(42);
Maybe empty = Maybe();

Maybe doubled = number->map(lambda(int x) { return x * 2; });
Maybe empty_doubled = empty->map(lambda(int x) { return x * 2; });

write("Number: %d\n", number->get_value());
write("Doubled: %d\n", doubled->get_value());
write("Empty value: %s\n", empty->get_value());
write("Default: %d\n", empty->get_default(0));
```

## Function Pipelines

```pike
// Function pipeline implementation
#pragma strict_types

class Pipeline {
    inherit ProgramWrapper;

    private array(function(mixed:mixed)) _stages;

    void create(function(mixed:mixed)... stages) {
        _stages = ({ stages });
    }

    public mixed process(mixed input) {
        mixed result = input;
        foreach(_stages; function(mixed:mixed) stage) {
            result = stage(result);
        }
        return result;
    }

    public Pipeline add_stage(function(mixed:mixed) stage) {
        _stages += ({ stage });
        return this;
    }
}

// Usage
Pipeline text_pipeline = Pipeline(
    lambda(string s) { return lower_case(s); },
    lambda(string s) { return replace(s, " ", "_"); },
    lambda(string s) { return sprintf("processed_%s", s); }
);

string result = text_pipeline->process("Hello World");
write("Processed: %s\n", result);

// Alternative pipeline usage
string result2 = Pipeline(
    lambda(string s) { return upper_case(s); },
    lambda(string s) { return replace(s, "E", "3"); }
)->process("Hello World");

write("Processed 2: %s\n", result2);
```

## Asynchronous Operations

```pike
// Asynchronous callback patterns
#pragma strict_types

// Simulated async operation
function(function(int:void), void) async_operation =
    lambda(function(int:void) callback, int delay) {
        call_out(callback, delay);
    };

// Promise-like implementation
class Promise {
    inherit ProgramWrapper;

    protected function(mixed:void) _resolve;
    protected function(mixed:void) _reject;
    protected mixed _value;
    protected mixed _error;
    protected int _resolved = 0;
    protected int _rejected = 0;

    protected void create(function(function(mixed:void), function(mixed:void)) executor) {
        _resolve = lambda(mixed value) {
            if (!_resolved) {
                _value = value;
                _resolved = 1;
            }
        };

        _reject = lambda(mixed error) {
            if (!_rejected) {
                _error = error;
                _rejected = 1;
            }
        };

        executor(_resolve, _reject);
    }

    public Promise then(function(mixed:mixed) on_fulfilled) {
        return Promise(lambda(function(mixed:void) resolve, function(mixed:void) reject) {
            call_out(lambda() {
                if (_resolved) {
                    mixed result = on_fulfilled(_value);
                    resolve(result);
                }
            }, 0);
        });
    }

    public Promise catch(function(mixed:mixed) on_rejected) {
        return Promise(lambda(function(mixed:void) resolve, function(mixed:void) reject) {
            call_out(lambda() {
                if (_rejected) {
                    mixed result = on_rejected(_error);
                    resolve(result);
                }
            }, 0);
        });
    }
}

// Usage
Promise p = Promise(lambda(function(int:void) resolve, function(mixed:void) reject) {
    async_operation(resolve, 2);
});

p->then(lambda(int value) {
    write("Promise resolved with: %d\n", value);
    return value * 2;
})->then(lambda(int value) {
    write("Final result: %d\n", value);
});
```

## Function Memoization with Cache

```pike
// Advanced memoization with TTL
#pragma strict_types

class MemoizedFunction {
    inherit ProgramWrapper;

    private function(mixed...:mixed) _fn;
    private mapping cache = ([]);
    private int ttl;
    private int default_ttl = 300; // 5 minutes

    void create(function(mixed...:mixed) fn, int|void ttl) {
        _fn = fn;
        if (ttl) {
            ttl = ttl;
        }
    }

    public mixed call(mixed... args) {
        string key = sprintf("%O", args);

        if (cache[key]) {
            mapping entry = cache[key];
            if (time() - entry->timestamp < ttl) {
                return entry->value;
            }
        }

        mixed result = _fn(@args);
        cache[key] = ([
            "value": result,
            "timestamp": time()
        ]);

        return result;
    }

    public void clear_cache() {
        cache = ([]);
    }

    public int get_cache_size() {
        return sizeof(cache);
    }
}

// Usage
MemoizedFunction memoized_fib = MemoizedFunction(
    lambda(int n) {
        if (n <= 1) return n;
        return memoized_fib->call(n - 1) + memoized_fib->call(n - 2);
    }, 60
);

write("Fibonacci 10: %d\n", memoized_fib->call(10));
write("Cache size: %d\n", memoized_fib->get_cache_size());
```