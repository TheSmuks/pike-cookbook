---
id: database-access
title: Database Access
sidebar_label: Database Access
---

## Introduction to Database Access in Pike 8

Pike 8 provides a comprehensive SQL interface through the `Sql.Sql` class, supporting multiple database backends including PostgreSQL, MySQL, and SQLite. The interface offers type-safe queries, prepared statements, connection pooling, and asynchronous operations.

### Supported Databases

| Database | URL Format | Features |
|----------|------------|----------|
| PostgreSQL | `pgsql://host:port/database` | Full featured, SSL, async queries, NOTIFY/LISTEN |
| MySQL | `mysql://host:port/database` | Widely used, SSL support via mysqls:// |
| SQLite | `sqlite://path/to/database.db` | Embedded, in-memory databases supported |

### Basic Connection

```pike
#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

// PostgreSQL connection
Sql.Sql db = Sql.Sql("pgsql://localhost:5432/mydb");

// MySQL connection
Sql.Sql db = Sql.Sql("mysql://localhost:3306/mydb");

// SQLite connection
Sql.Sql db = Sql.Sql("sqlite://example.db");

// With authentication
Sql.Sql db = Sql.Sql("pgsql://user:password@localhost:5432/mydb");

// With options
Sql.Sql db = Sql.Sql("pgsql://host", "database", "user", "password", ([
    "use_ssl": 1,
    "reconnect": -1,
    "cache_autoprepared_statements": 1
]));
```

For complete working examples, see the recipe files in `recipes/database/`:
- `dbconnection.pike` - Connection management and pooling
- `basic_queries.pike` - Query execution and results
- `advanced_operations.pike` - Joins, aggregations, CTEs
- `async_operations.pike` - Asynchronous database operations
- `best_practices.pike` - Security and performance patterns

## Executing SQL Queries

### Simple SELECT Query

```pike
// Basic query - returns array of mappings
array(mapping(string:mixed)) result = db->query("SELECT * FROM users");

foreach (result, mapping(string:mixed) row) {
    werror("User: %s, Email: %s\n", row->name, row->email);
}
```

### Type-Safe Queries (Pike 8)

Use `typed_query()` for automatic type conversion:

```pike
// Returns properly typed values (int, float, string, Val.null)
array(mapping(string:mixed)) result =
    db->typed_query("SELECT id, name, age FROM users WHERE age > %d", 28);

foreach (result, mapping row) {
    // row->id is int, row->name is string, row->age is int
    werror("%s (ID: %d) is %d years old\n",
           row->name, row->id, row->age);
}
```

### Parameter Binding (SQL Injection Prevention)

**CRITICAL:** Always use parameter binding to prevent SQL injection:

```pike
// SAFE: Using sprintf-style parameters
string username = "alice";
int min_age = 25;

array(mapping) result = db->query(
    "SELECT * FROM users WHERE username = %s AND age > %d",
    username, min_age
);

// SAFE: Using named parameters
array(mapping) result = db->query(
    "SELECT * FROM users WHERE username = :username AND age > :min_age",
    (["username": username, "min_age": min_age])
);

// DANGEROUS: Never do this!
// string query = "SELECT * FROM users WHERE username = '" + username + "'";
// This is vulnerable to SQL injection attacks
```

### Large Result Sets (Streaming)

For large result sets, use `big_query()` to fetch rows one at a time:

```pike
// Stream results - memory efficient
object result = db->big_query("SELECT * FROM large_table");

if (result) {
    array(mixed) row;
    while ((row = result->fetch_row())) {
        // Process one row at a time
        process_row(row);
    }

    // Get metadata
    werror("Total rows: %d\n", result->num_rows());
}
```

## INSERT, UPDATE, DELETE Operations

### INSERT Operations

```pike
// Simple insert
db->query("INSERT INTO users (name, email, age) VALUES (%s, %s, %d)",
         "Alice", "alice@example.com", 30);

// Insert with named parameters
db->query("INSERT INTO users (name, email, age) "
         "VALUES (:name, :email, :age)",
         (["name": "Bob", "email": "bob@example.com", "age": 25]));

// Get last insert ID (SQLite, MySQL, PostgreSQL)
int last_id = db->master_sql->last_insert_id();
```

### UPDATE Operations

```pike
// Update single record
db->query("UPDATE users SET age = :new_age WHERE name = :name",
         (["new_age": 31, "name": "Alice"]));

// Update multiple records
int affected = db->query("UPDATE users SET age = age + 1 WHERE age < 30");

// Check affected rows (varies by database)
werror("Updated %d records\n", affected ? sizeof(affected) : 0);
```

### DELETE Operations

```pike
// Delete with condition
db->query("DELETE FROM users WHERE age > :max_age",
         (["max_age": 50]));

// Delete single record
db->query("DELETE FROM users WHERE id = %d", user_id);

// Delete all (use with caution)
db->query("DELETE FROM users");
```

## Transaction Management

Transactions ensure ACID properties for multi-step operations:

```pike
// Basic transaction pattern
db->query("BEGIN TRANSACTION");

mixed err = catch {
    // Multiple operations
    db->query("INSERT INTO accounts (user_id, balance) VALUES (%d, %f)",
             user_id, 100.0);
    db->query("UPDATE users SET account_created = 1 WHERE id = %d", user_id);

    // Commit if all successful
    db->query("COMMIT");
    werror("Transaction committed successfully\n");
};

if (err) {
    // Rollback on error
    db->query("ROLLBACK");
    werror("Transaction rolled back: %s\n", err[0]);
}
```

### Transaction with Error Handling

```pike
// Robust transaction with proper cleanup
class Transaction {
    private Sql.Sql db;
    private int in_progress = 0;

    void create(Sql.Sql db) {
        this::db = db;
        begin();
    }

    void begin() {
        db->query("BEGIN TRANSACTION");
        in_progress = 1;
    }

    void commit() {
        if (in_progress) {
            db->query("COMMIT");
            in_progress = 0;
        }
    }

    void rollback() {
        if (in_progress) {
            db->query("ROLLBACK");
            in_progress = 0;
        }
    }

    void destroy() {
        if (in_progress) {
            rollback();
        }
    }
}

// Usage
Transaction tx = Transaction(db);

mixed err = catch {
    db->query("INSERT INTO ...");
    db->query("UPDATE ...");
    tx->commit();
};

if (err) {
    tx->rollback();
    // Handle error
}
```

## Connection Pooling

For web applications and high-load scenarios, use connection pooling:

```pike
#pragma strict_types
#pike 8.0

class ConnectionPool {
    private string db_url;
    private int pool_size;
    private array(Sql.Sql) connections;
    private Thread.Queue available;
    private Thread.Mutex lock = Thread.Mutex();

    void create(string db_url, int pool_size) {
        this::db_url = db_url;
        this::pool_size = pool_size;

        connections = allocate(pool_size);
        available = Thread.Queue();

        // Initialize connections
        for (int i = 0; i < pool_size; i++) {
            connections[i] = Sql.Sql(db_url);
            available->write(i);
        }
    }

    // Get connection from pool
    Sql.Sql acquire() {
        int idx = available->read();
        Sql.Sql conn = connections[idx];

        // Verify connection is alive
        if (conn->ping() < 0) {
            Thread.MutexKey key = lock->lock();
            connections[idx] = Sql.Sql(db_url);
            conn = connections[idx];
            destruct(key);
        }

        return conn;
    }

    // Return connection to pool
    void release(Sql.Sql conn) {
        Thread.MutexKey key = lock->lock();
        int idx = search(connections, conn);
        if (idx >= 0) {
            available->write(idx);
        }
        destruct(key);
    }

    // Execute query with automatic connection management
    array(mapping) query(string q, mixed... extraargs) {
        Sql.Sql conn = acquire();
        mixed err = catch {
            array(mapping) result = conn->query(q, @extraargs);
            release(conn);
            return result;
        };

        release(conn);
        throw(err);
    }
}

// Usage
ConnectionPool pool = ConnectionPool("pgsql://localhost/appdb", 10);

// Use pool for queries
array(mapping) users = pool->query(
    "SELECT * FROM users WHERE active = 1"
);
```

## Advanced Query Features

### JOIN Operations

```pike
// INNER JOIN
array(mapping) result = db->typed_query(
    "SELECT e.name, d.department "
    "FROM employees e "
    "INNER JOIN departments d ON e.department_id = d.id"
);

// LEFT JOIN
array(mapping) result = db->typed_query(
    "SELECT e.name, d.department "
    "FROM employees e "
    "LEFT JOIN departments d ON e.department_id = d.id"
);
```

### GROUP BY and Aggregation

```pike
// Count and average
array(mapping) stats = db->typed_query(
    "SELECT department, COUNT(*) as count, AVG(salary) as avg_salary "
    "FROM employees "
    "GROUP BY department"
);

// HAVING clause
array(mapping) high_salary = db->typed_query(
    "SELECT department, AVG(salary) as avg "
    "FROM employees "
    "GROUP BY department "
    "HAVING AVG(salary) > 60000"
);
```

### Common Table Expressions (CTE)

```pike
// Simple CTE
array(mapping) result = db->typed_query("
    WITH high_paid AS (
        SELECT name, salary, department_id
        FROM employees
        WHERE salary > 70000
    )
    SELECT e.name, d.department
    FROM high_paid e
    JOIN departments d ON e.department_id = d.id
");

// Recursive CTE (hierarchical data)
array(mapping) hierarchy = db->typed_query("
    WITH RECURSIVE category_tree AS (
        SELECT id, name, parent_id, 1 as level
        FROM categories
        WHERE parent_id IS NULL
        UNION ALL
        SELECT c.id, c.name, c.parent_id, ct.level + 1
        FROM categories c
        JOIN category_tree ct ON c.parent_id = ct.id
    )
    SELECT name, level FROM category_tree ORDER BY level
");
```

## Asynchronous Database Operations

Pike 8 supports asynchronous database operations using Future/Promise:

```pike
// Async query with Future/Promise
class AsyncDatabase {
    private Sql.Sql db;

    void create(string db_url) {
        db = Sql.Sql(db_url);
    }

    Promise query_async(string query, mapping|void bindings) {
        Promise promise = Promise();
        Thread.Thread(do_query, promise, query, bindings);
        return promise;
    }

    private void do_query(Promise promise, string query, mapping|void bindings) {
        mixed err = catch {
            array(mapping) result = bindings ?
                db->query(query, bindings) : db->query(query);
            promise->success(result);
        };

        if (err) {
            promise->failure(err);
        }
    }
}

// Usage
AsyncDatabase async_db = AsyncDatabase("sqlite://example.db");
Promise p = async_db->query_async("SELECT * FROM users");
Future f = p->future();

// Do other work here...

// Get result when ready
mixed result = f->get();
if (arrayp(result)) {
    werror("Got %d rows\n", sizeof(result));
}
```

## Database Best Practices

### Security Best Practices

- Always use parameter binding to prevent SQL injection
- Validate and sanitize user input
- Use least privilege database accounts
- Hash passwords with salt (never store plaintext)
- Use SSL for remote database connections

### Performance Best Practices

- Use indexes on frequently queried columns
- Batch operations in transactions
- Use connection pooling for web applications
- Prefer typed_query for better type handling
- Use EXPLAIN to analyze query performance
- Stream large results with big_query

### Maintainability Best Practices

- Use repository pattern for data access
- Implement migrations for schema changes
- Log queries in development environments
- Use prepared statements for repeated queries
- Handle errors gracefully with proper cleanup

### Example Repository Pattern

```pike
class UserRepository {
    private Sql.Sql db;

    void create(Sql.Sql db) {
        this::db = db;
    }

    array(mapping) find_all() {
        return db->typed_query("SELECT id, username, email FROM users");
    }

    mapping find_by_id(int id) {
        array(mapping) result = db->typed_query(
            "SELECT id, username, email FROM users WHERE id = :id",
            (["id": id])
        );
        return sizeof(result) ? result[0] : 0;
    }

    int create(string username, string email) {
        db->query(
            "INSERT INTO users (username, email) VALUES (:username, :email)",
            (["username": username, "email": email])
        );
        return db->master_sql->last_insert_id();
    }

    void update(int id, string|void username, string|void email) {
        if (username) {
            db->query("UPDATE users SET username = :username WHERE id = :id",
                     (["username": username, "id": id]));
        }
        if (email) {
            db->query("UPDATE users SET email = :email WHERE id = :id",
                     (["email": email, "id": id]));
        }
    }

    void delete(int id) {
        db->query("DELETE FROM users WHERE id = :id", (["id": id]));
    }
}

// Usage
Sql.Sql db = Sql.Sql("sqlite://app.db");
UserRepository users = UserRepository(db);

int user_id = users->create("alice", "alice@example.com");
mapping user = users->find_by_id(user_id);
users->update(user_id, "alice_updated");
array(mapping) all_users = users->find_all();
users->delete(user_id);
```