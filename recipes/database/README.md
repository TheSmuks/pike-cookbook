# Database Access in Pike 8

This chapter covers comprehensive database access patterns using Pike 8's modern SQL interface.

## Overview

Pike 8 provides a unified SQL interface through `Sql.Sql` that supports multiple database backends:
- **PostgreSQL** - Full-featured, production-grade database
- **MySQL/MariaDB** - Popular web application database
- **SQLite** - Embedded database for local storage
- **ODBC** - Generic database connectivity

## Key Features in Pike 8

- **Type-safe queries** - Automatic type conversion with `typed_query()`
- **Connection pooling** - Efficient connection reuse
- **Prepared statements** - SQL injection protection and performance
- **Async operations** - Non-blocking database queries with Future/Promise
- **Streaming queries** - Handle large result sets efficiently
- **Transaction management** - ACID guarantees
- **Unicode support** - Full UTF-8 support

## Examples

### 1. Basic Database Connection

```pike
Sql.Sql db = Sql.Sql("pgsql://localhost:5432/mydb");
array(mapping) result = db->query("SELECT * FROM users");
```

### 2. Parameter Binding (SQL Injection Prevention)

```pike
// Safe: using parameter binding
array(mapping) result = db->query(
    "SELECT * FROM users WHERE username = %s AND age > %d",
    username, min_age
);

// Also safe: using named parameters
array(mapping) result = db->query(
    "SELECT * FROM users WHERE username = :username",
    (["username": username])
);
```

### 3. Type-Safe Queries

```pike
// Returns properly typed values (int, float, string, Val.null)
array(mapping(string:mixed)) result = db->typed_query(
    "SELECT id, name, age FROM users WHERE id = :id",
    (["id": user_id])
);

foreach (result, mapping row) {
    // row->id is int, row->name is string, row->age is int
}
```

### 4. Transaction Management

```pike
db->query("BEGIN TRANSACTION");

mixed err = catch {
    db->query("INSERT INTO accounts (user_id, balance) VALUES (%d, %f)",
             user_id, 100.0);
    db->query("UPDATE users SET account_created = 1 WHERE id = %d", user_id);
    db->query("COMMIT");
};

if (err) {
    db->query("ROLLBACK");
    // Handle error
}
```

### 5. Streaming Large Results

```pike
// For large result sets, use big_query
object result = db->big_query("SELECT * FROM large_table");

array(mixed) row;
while ((row = result->fetch_row())) {
    // Process one row at a time
    // Memory efficient!
}
```

### 6. Connection Pooling

```pike
// Create a simple connection pool
class ConnectionPool {
    private array(Sql.Sql) connections;
    private Thread.Queue available;

    void create(string url, int size) {
        connections = allocate(size);
        available = Thread.Queue();

        for (int i = 0; i < size; i++) {
            connections[i] = Sql.Sql(url);
            available->write(i);
        }
    }

    Sql.Sql get() {
        int idx = available->read();
        return connections[idx];
    }

    void release(Sql.Sql conn) {
        int idx = search(connections, conn);
        if (idx >= 0) available->write(idx);
    }
}
```

## Database-Specific Notes

### PostgreSQL

PostgreSQL support in Pike 8 is comprehensive:

```pike
// Connect with SSL and options
Sql.Sql pgsql = Sql.Sql("pgsql://host", "database", "user", "pass", ([
    "use_ssl": 1,
    "reconnect": -1,
    "cache_autoprepared_statements": 1
]));

// PostgreSQL-specific features
pgsql->set_charset("UTF8");
mapping stats = pgsql->getstatistics();
array(string) tables = pgsql->list_tables();
```

**PostgreSQL Advantages:**
- Native protocol (no external dependencies)
- Multiple simultaneous queries on single connection
- NOTIFY/LISTEN support
- Streaming queries
- SSL connections
- SCRAM authentication

### MySQL

```pike
// Standard MySQL connection
Sql.Sql mysql = Sql.Sql("mysql://localhost:3306/mydb");

// With authentication
Sql.Sql mysql = Sql.Sql("mysql://user:pass@localhost:3306/mydb");

// MySQL with SSL
Sql.Sql mysql_ssl = Sql.Sql("mysqls://user:pass@localhost:3306/mydb");
```

### SQLite

```pike
// File-based database
Sql.Sql sqlite = Sql.Sql("sqlite://path/to/database.db");

// In-memory database
Sql.Sql sqlite = Sql.Sql("sqlite://:memory:");
```

## Best Practices

### Security

1. **Always use parameter binding** to prevent SQL injection
2. **Never trust user input** - validate and sanitize
3. **Use least privilege** - connect with minimal permissions
4. **Hash passwords** - never store plaintext
5. **Use SSL** for remote database connections

### Performance

1. **Use indexes** on frequently queried columns
2. **Batch operations** in transactions
3. **Use connection pooling** for web applications
4. **Choose appropriate column types**
5. **Use EXPLAIN** to analyze query plans
6. **Prefer typed_query** for better type handling

### Maintainability

1. **Use repository pattern** for data access
2. **Implement migrations** for schema changes
3. **Log queries** in development
4. **Use prepared statements** for repeated queries
5. **Handle errors** gracefully with proper cleanup

## Error Handling

```pike
mixed err = catch {
    db->query("INSERT INTO users (name) VALUES (%s)", username);
};

if (err) {
    // Get database-specific error
    string db_error = db->error();
    werror("Database error: %s\n", db_error);

    // Get SQLSTATE error code
    string sqlstate = db->sqlstate();
    werror("SQLSTATE: %s\n", sqlstate);
}
```

## Type Mapping

### Typed Mode

| SQL Type | Pike Type |
|----------|-----------|
| INTEGER | int |
| BIGINT | int |
| REAL/FLOAT | float |
| DOUBLE | float |
| TEXT/VARCHAR | string |
| BLOB | string (binary) |
| NULL | Val.null |
| BOOLEAN | int (0/1) |
| TIMESTAMP | int (unix time) |

### Untyped Mode (legacy)

All values returned as strings except NULL which is 0.

## Working with NULL

```pike
// Check for NULL
if (row->column == Val.null) {
    // Handle NULL value
}

// COALESCE in SQL
array(mapping) result = db->query(
    "SELECT COALESCE(name, 'Unknown') as name FROM users"
);
```

## Date/Time Handling

```pike
// Encode time for database
string time_str = db->encode_time(time());  // Current time

// Encode date
string date_str = db->encode_date(time());

// Decode from database
int timestamp = db->decode_datetime("2024-01-15 10:30:00");
```

## Full Example: User Management System

```pike
#pragma strict_types
#pike 8.0

class UserManager {
    private Sql.Sql db;

    void create(string db_url) {
        db = Sql.Sql(db_url);
        initialize_schema();
    }

    private void initialize_schema() {
        db->query("CREATE TABLE IF NOT EXISTS users ("
                  "id INTEGER PRIMARY KEY, "
                  "username TEXT UNIQUE NOT NULL, "
                  "email TEXT UNIQUE NOT NULL, "
                  "password_hash TEXT NOT NULL, "
                  "salt TEXT NOT NULL, "
                  "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");

        db->query("CREATE INDEX IF NOT EXISTS idx_users_username "
                 "ON users(username)");
    }

    // Create user with password hashing
    int create_user(string username, string email, string password) {
        string salt = MIME.encode_base64(Crypto.Random.random_string(32));
        string hash = String.string2hex(Crypto.SHA256.hash(password + salt));

        db->query("INSERT INTO users (username, email, password_hash, salt) "
                 "VALUES (%s, %s, %s, %s)",
                 username, email, hash, salt);

        return db->master_sql->last_insert_id();
    }

    // Verify user credentials
    mapping verify_user(string username, string password) {
        array(mapping) result = db->typed_query(
            "SELECT id, password_hash, salt FROM users WHERE username = %s",
            username
        );

        if (!sizeof(result)) {
            return 0;  // User not found
        }

        string computed_hash = String.string2hex(
            Crypto.SHA256.hash(password + result[0]->salt)
        );

        if (computed_hash == result[0]->password_hash) {
            return (["id": result[0]->id]);
        }

        return 0;  // Invalid password
    }

    // Get user by ID (type-safe)
    mapping get_user(int user_id) {
        array(mapping) result = db->typed_query(
            "SELECT id, username, email, created_at FROM users WHERE id = %d",
            user_id
        );

        return sizeof(result) ? result[0] : 0;
    }

    // List users with pagination
    array(mapping) list_users(int page, int per_page) {
        int offset = (page - 1) * per_page;

        return db->typed_query(
            "SELECT id, username, email, created_at FROM users "
            "ORDER BY created_at DESC LIMIT %d OFFSET %d",
            per_page, offset
        );
    }
}

// Usage
int main() {
    UserManager users = UserManager("sqlite://users.db");

    // Create user
    int user_id = users->create_user("alice", "alice@example.com", "secret123");

    // Verify login
    mapping auth = users->verify_user("alice", "secret123");
    if (auth) {
        werror("Login successful for user ID: %d\n", auth->id);
    }

    // Get user details
    mapping user = users->get_user(user_id);
    werror("User: %s (%s)\n", user->username, user->email);

    // List users
    array(mapping) user_list = users->list_users(1, 10);
    werror("Found %d users\n", sizeof(user_list));

    return 0;
}
```

## Resources

- **Source Code Examples:**
  - `dbconnection.pike` - Connection management and pooling
  - `basic_queries.pike` - Query execution and results
  - `advanced_operations.pike` - Joins, aggregations, CTEs
  - `async_operations.pike` - Asynchronous database operations
  - `best_practices.pike` - Security and performance patterns

- **Pike 8 Documentation:**
  - `Sql.Sql` - Generic SQL interface
  - `Sql.pgsql` - PostgreSQL driver
  - `Sql.sqlite` - SQLite driver
  - `Sql.mysql` - MySQL driver

## Testing the Examples

Most examples use SQLite for easy testing:

```bash
# Run connection examples
pike recipes/database/dbconnection.pike

# Run basic queries
pike recipes/database/basic_queries.pike

# Run advanced operations
pike recipes/database/advanced_operations.pike

# Run async operations
pike recipes/database/async_operations.pike

# Run best practices examples
pike recipes/database/best_practices.pike
```

For PostgreSQL or MySQL examples, ensure the database is running and update connection URLs.
