#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

//! Database best practices for Pike 8
//!
//! Demonstrates security, performance, and maintainability patterns
//!
//! @example
//!   // Always use parameter binding
//!   db->query("SELECT * FROM users WHERE id = :id", (["id": user_id]));
//!
//! @note
//!   Follow these practices: use parameter binding, validate input,
//!   use transactions for multi-step operations, implement proper error handling
//!
//! @seealso
//!   @[Sql.Sql], @[basic_queries], @[advanced_operations]

//! ============================================================================
//! SECURITY BEST PRACTICES
//! ============================================================================

//! Example: Always use parameter binding (SQL injection prevention)
//!
//! Demonstrates safe parameter binding to prevent SQL injection
//!
//! @note
//!   NEVER concatenate user input directly into SQL queries
//!
//! @seealso
//!   @[security_password_handling], @[security_input_validation]

void security_parameter_binding() {
    werror("\n=== Security: Parameter Binding ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    string username = "admin'; DROP TABLE users; --";

    // BAD: Vulnerable to SQL injection
    // string query = "SELECT * FROM users WHERE username = '" + username + "'";
    // db->query(query);

    // GOOD: Using parameter binding
    array(mapping) result = db->query(
        "SELECT * FROM users WHERE username = %s",
        username
    );

    // GOOD: Using named parameters
    db->query(
        "SELECT * FROM users WHERE username = :username",
        (["username": username])
    );

    werror("Secure query executed: %d rows\n", sizeof(result));
}

//! Example: Proper password handling
//!
//! @note
//!   NEVER store passwords in plain text. Always use salted hashes
//!
//! @seealso
//!   @[security_least_privilege]

void security_password_handling() {
    werror("\n=== Security: Password Handling ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    // NEVER store passwords in plain text
    string password = "secret123";

    // Create password table
    db->query("CREATE TABLE IF NOT EXISTS users_secure ("
              "id INTEGER PRIMARY KEY, "
              "username TEXT UNIQUE, "
              "password_hash TEXT, "
              "salt TEXT)");

    // Generate random salt using Pike's random function
    string salt = MIME.encode_base64(Crypto.Random.random_string(32));

    // Hash password with salt (using SHA-256 for example)
    string password_hash =
        String.string2hex(Crypto.SHA256.hash((string(8bit))(password + salt)));

    // Store hash and salt
    db->query("INSERT INTO users_secure (username, password_hash, salt) "
             "VALUES (%s, %s, %s)",
             "alice", password_hash, salt);

    // Verify password
    string input_password = "secret123";
    array(mapping) user = db->query(
        "SELECT password_hash, salt FROM users_secure WHERE username = %s",
        "alice"
    );

    if (sizeof(user)) {
        string computed_hash =
            String.string2hex(Crypto.SHA256.hash((string(8bit))(input_password + user[0]->salt)));

        if (computed_hash == (string)user[0]->password_hash) {
            werror("Password verified successfully\n");
        } else {
            werror("Invalid password\n");
        }
    }
}

//! Example: Principle of least privilege
//!
//! @note
//!   Connect with application-specific user, not root/admin
//!
//! @seealso
//!   @[security_input_validation]

void security_least_privilege() {
    werror("\n=== Security: Least Privilege ===\n");

    // Connect with limited permissions
    // The application should only have necessary permissions

    // BAD: Connecting as root/superuser
    // Sql.Sql db = Sql.Sql("pgsql://root:password@localhost/db");

    // GOOD: Connecting with application-specific user
    // Sql.Sql db = Sql.Sql(
    //     "pgsql://appuser:apppass@localhost/appdb"
    // );

    // Application user should only have:
    // - SELECT, INSERT, UPDATE, DELETE on application tables
    // - No DROP, ALTER, CREATE, GRANT permissions
    // - No access to system tables

    werror("Connected with least-privilege user\n");
}

//! Example: Validate input before database operations
//!
//! @note
//!   Always validate and sanitize user input before database operations
//!
//! @seealso
//!   @[performance_indexes]

void security_input_validation() {
    werror("\n=== Security: Input Validation ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    // Validate email format
    string email = "user@example.com";

    if (!glob("*@*.*", email)) {
        error("Invalid email format\n");
    }

    // Validate numeric ranges
    string age_str = "25";
    int age = (int)age_str;

    if (age < 0 || age > 150) {
        error("Invalid age\n");
    }

    // Sanitize strings (remove dangerous characters)
    string username = "admin123";
    username = replace(username, ({ "'", ";", "--", "/*", "*/" }), ({ "", "", "", "", "" }));

    // Now use parameter binding (still necessary)
    db->query(
        "SELECT * FROM users WHERE username = %s AND age = %d",
        username, age
    );

    werror("Validated query executed\n");
}

//! ============================================================================
//! PERFORMANCE BEST PRACTICES
//! ============================================================================

//! Example: Use indexes for better query performance
//!
//! @note
//!   Create indexes on frequently queried columns
//!
//! @seealso
//!   @[performance_column_types]

void performance_indexes() {
    werror("\n=== Performance: Indexes ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    // Create table with proper indexes
    db->query("CREATE TABLE IF NOT EXISTS products ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "category TEXT, "
              "price REAL, "
              "created_at TIMESTAMP)");

    // Create indexes on frequently queried columns
    db->query("CREATE INDEX IF NOT EXISTS idx_products_category "
             "ON products(category)");

    db->query("CREATE INDEX IF NOT EXISTS idx_products_price "
             "ON products(price)");

    db->query("CREATE INDEX IF NOT EXISTS idx_products_created "
             "ON products(created_at)");

    // Composite index for multiple column queries
    db->query("CREATE INDEX IF NOT EXISTS idx_products_category_price "
             "ON products(category, price)");

    werror("Indexes created for better performance\n");
}

//! Example: Use appropriate column types
//!
//! @note
//!   Use appropriate data types and constraints for better performance
//!
//! @seealso
//!   @[performance_query_analysis]

void performance_column_types() {
    werror("\n=== Performance: Column Types ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    // GOOD: Use appropriate types
    db->query("CREATE TABLE IF NOT EXISTS orders ("
              "id INTEGER PRIMARY KEY, "
              "user_id INTEGER NOT NULL, "
              "product_id INTEGER NOT NULL, "
              "quantity INTEGER NOT NULL CHECK(quantity > 0), "
              "unit_price REAL NOT NULL CHECK(unit_price > 0), "
              "total_price REAL GENERATED ALWAYS AS (quantity * unit_price) STORED, "
              "order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
              "status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN "
              "('pending', 'processing', 'shipped', 'delivered', 'cancelled')))");

    werror("Table created with optimized types\n");
}

//! Example: Use EXPLAIN to analyze queries
//!
//! @note
//!   Use EXPLAIN QUERY PLAN to analyze and optimize queries
//!
//! @seealso
//!   @[performance_batch_operations]

void performance_query_analysis() {
    werror("\n=== Performance: Query Analysis ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    // Analyze query plan
    array(mapping) plan = db->query(
        "EXPLAIN QUERY PLAN SELECT * FROM products WHERE category = 'Electronics'"
    );

    werror("Query plan:\n");
    foreach (plan, mapping row) {
        werror("  %s\n", (string)(row->detail || row[0] || ""));
    }

    // If plan shows "SCAN TABLE", you need an index
    // If plan shows "SEARCH TABLE USING INDEX", good!
}

//! Example: Batch operations with transactions
//!
//! @note
//!   Use transactions for batch operations to improve performance
//!
//! @seealso
//!   @[performance_connection_pooling]

void performance_batch_operations() {
    werror("\n=== Performance: Batch Operations ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    // SLOW: Individual inserts
    float slow_time = gauge {
        for (int i = 0; i < 100; i++) {
            db->query("INSERT INTO products (name, category, price) "
                     "VALUES (%s, %s, %f)",
                     sprintf("Product %d", i),
                     "Test",
                     10.0 + i);
        }
    };
    werror("Slow individual inserts: %.4f seconds\n", slow_time);

    // FAST: Batch insert with transaction
    db->query("DELETE FROM products WHERE category = 'Test'");

    float fast_time = gauge {
        db->query("BEGIN TRANSACTION");

        for (int i = 0; i < 100; i++) {
            db->query("INSERT INTO products (name, category, price) "
                     "VALUES (%s, %s, %f)",
                     sprintf("Product %d", i),
                     "Test",
                     10.0 + i);
        }

        db->query("COMMIT");
    };
    werror("Fast batch inserts: %.4f seconds\n", fast_time);
    werror("Speedup: %.1fx\n", slow_time / fast_time);
}

//! Example: Connection pooling
//!
//! Thread-safe connection pool implementation
//!
//! @seealso
//!   @[performance_batch_operations]

class ConnectionPool {
    private string db_url;
    private int pool_size;
    private array(Sql.Sql) connections;
    private Thread.Mutex lock = Thread.Mutex();
    private array(int) available;

    //! Create connection pool
    //!
    //! @param db_url
    //!   Database connection URL
    //! @param pool_size
    //!   Number of connections in the pool
    //!
    //! @seealso
    //!   @[acquire], @[release]

    void create(string db_url, int pool_size) {
        this::db_url = db_url;
        this::pool_size = pool_size;

        connections = allocate(pool_size);
        available = ({});

        for (int i = 0; i < pool_size; i++) {
            connections[i] = Sql.Sql(db_url);
            available += ({i});
        }
    }

    //! Acquire connection from pool
    //!
    //! @returns
    //!   Database connection from the pool
    //!
    //! @note
    //!   Blocks until a connection becomes available
    //!
    //! @seealso
    //!   @[release], @[create]

    Sql.Sql acquire() {
        Thread.MutexKey key = lock->lock();

        while (!sizeof(available)) {
            destruct(key);
            sleep(0.01);
            key = lock->lock();
        }

        int idx = available[0];
        available = available[1..];

        Sql.Sql conn = connections[idx];

        // Verify connection
        if (conn->ping() < 0) {
            connections[idx] = Sql.Sql(db_url);
            conn = connections[idx];
        }

        destruct(key);
        return conn;
    }

    //! Release connection back to pool
    //!
    //! @param conn
    //!   Connection to return to the pool
    //!
    //! @seealso
    //!   @[acquire]

    void release(Sql.Sql conn) {
        Thread.MutexKey key = lock->lock();

        int idx = search(connections, conn);
        if (idx >= 0) {
            available += ({idx});
        }

        destruct(key);
    }
}

//! Example: Connection pooling
//!
//! @seealso
//!   @[performance_prepared_statements]

void performance_connection_pooling() {
    werror("\n=== Performance: Connection Pooling ===\n");

    ConnectionPool pool = ConnectionPool("sqlite://:memory:", 5);

    // Use pool
    Sql.Sql conn = pool->acquire();

    array(mapping) result = conn->query("SELECT COUNT(*) as count FROM products");

    werror("Query result: %s\n", (string)result[0]->count);

    pool->release(conn);
}

//! Example: Use prepared statements for repeated queries
//!
//! @note
//!   Compile queries once for reuse with different parameters
//!
//! @seealso
//!   @[maintainability_repository]

void performance_prepared_statements() {
    werror("\n=== Performance: Prepared Statements ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");

    // Compile query once
    mixed compiled = db->compile_query(
        "SELECT * FROM products WHERE category = :category"
    );

    // Execute multiple times
    array(string) categories = ({ "Electronics", "Books", "Clothing" });

    foreach (categories, string category) {
        array(mapping) result = db->query((string)compiled, (["category": category]));
        werror("%s: %d products\n", category, sizeof(result));
    }
}

//! ============================================================================
//! MAINTAINABILITY BEST PRACTICES
//! ============================================================================

//! Example: Use a repository pattern
//!
//! Repository pattern for database operations
//!
//! @seealso
//!   @[MigrationManager]

class UserRepository {
    private Sql.Sql db;

    //! Create user repository
    //!
    //! @param connection
    //!   Database connection
    //!
    //! @seealso
    //!   @[find_all], @[find_by_id]

    void create(string|object(Sql.Sql) connection) {
        if (objectp(connection)) {
            db = [object(Sql.Sql)]connection;
        } else {
            // If called with a string (db URL), create connection
            db = Sql.Sql([string]connection);
        }
    }

    //! Find all users
    //!
    //! @returns
    //!   Array of user mappings
    //!
    //! @seealso
    //!   @[find_by_id]

    array(mapping) find_all() {
        return db->typed_query("SELECT id, username, email FROM users");
    }

    //! Find user by ID
    //!
    //! @param id
    //!   User ID to search for
    //! @returns
    //!   User mapping or 0 if not found
    //!
    //! @seealso
    //!   @[find_by_username]

    mapping find_by_id(int id) {
        array(mapping) result = db->typed_query(
            "SELECT id, username, email FROM users WHERE id = :id",
            (["id": id])
        );

        return sizeof(result) ? result[0] : 0;
    }

    //! Find user by username
    //!
    //! @param username
    //!   Username to search for
    //! @returns
    //!   User mapping or 0 if not found
    //!
    //! @seealso
    //!   @[find_by_id]

    mapping find_by_username(string username) {
        array(mapping) result = db->typed_query(
            "SELECT id, username, email FROM users WHERE username = :username",
            (["username": username])
        );

        return sizeof(result) ? result[0] : 0;
    }

    //! Create new user
    //!
    //! @param username
    //!   Username for new user
    //! @param email
    //!   Email for new user
    //! @returns
    //!   ID of created user
    //!
    //! @seealso
    //!   @[update]

    int create_user(string username, string email) {
        db->query(
            "INSERT INTO users (username, email) VALUES (:username, :email)",
            (["username": username, "email": email])
        );

        // Get last insert ID - method varies by database
        mixed last_id = db->last_insert_id();
        return intp(last_id) ? [int]last_id : 0;
    }

    //! Update user
    //!
    //! @param id
    //!   User ID to update
    //! @param username
    //!   Optional new username
    //! @param email
    //!   Optional new email
    //!
    //! @seealso
    //!   @[create], @[delete]

    void update(int id, string|void username, string|void email) {
        array(string) updates = ({});
        mapping bindings = (["id": id]);

        if (username) {
            updates += ({ "username = :username" });
            bindings->username = username;
        }

        if (email) {
            updates += ({ "email = :email" });
            bindings->email = email;
        }

        if (sizeof(updates)) {
            db->query(sprintf("UPDATE users SET %s WHERE id = :id",
                            updates * ", "),
                     bindings);
        }
    }

    //! Delete user
    //!
    //! @param id
    //!   User ID to delete
    //!
    //! @seealso
    //!   @[update]

    void delete(int id) {
        db->query("DELETE FROM users WHERE id = :id", (["id": id]));
    }
}

//! Example: Repository pattern
//!
//! @seealso
//!   @[maintainability_migrations]

void maintainability_repository() {
    werror("\n=== Maintainability: Repository Pattern ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");
    db->query("CREATE TABLE IF NOT EXISTS users ("
              "id INTEGER PRIMARY KEY, "
              "username TEXT UNIQUE NOT NULL, "
              "email TEXT UNIQUE NOT NULL, "
              "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
             ")");
    UserRepository users = UserRepository(db);

    // Create user
    int user_id = users->create_user("john_doe", "john@example.com");
    werror("Created user with ID: %d\n", user_id);

    // Find user
    mapping user = users->find_by_id(user_id);
    werror("Found user: %s (%s)\n", (string)user->username, (string)user->email);

    // Update user
    users->update(user_id, "john_updated");
    user = users->find_by_id(user_id);
    werror("Updated user: %s\n", (string)user->username);

    // List all users
    array(mapping) all_users = users->find_all();
    werror("Total users: %d\n", sizeof(all_users));

    // Delete user
    users->delete(user_id);
    werror("User deleted\n");
}

//! Example: Database migration system
//!
//! Database migration management system
//!
//! @seealso
//!   @[UserRepository]

class Migration {
    string name = "";
    string up_sql = "";
    string down_sql = "";
}

//! Migration manager for database schema versioning
//!
//! @seealso
//!   @[Migration]

class MigrationManager {
    private Sql.Sql db;
    private array(Migration) migrations = ({});

    //! Create migration manager
    //!
    //! @param db
    //!   Database connection
    //!
    //! @seealso
    //!   @[add_migration], @[migrate]

    void create(Sql.Sql db) {
        this::db = db;

        // Create migrations table
        db->query("CREATE TABLE IF NOT EXISTS schema_migrations ("
                  "id INTEGER PRIMARY KEY, "
                  "name TEXT UNIQUE NOT NULL, "
                  "applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
    }

    //! Add migration to manager
    //!
    //! @param name
    //!   Migration name/identifier
    //! @param up_sql
    //!   SQL to apply migration
    //! @param down_sql
    //!   SQL to rollback migration
    //!
    //! @seealso
    //!   @[migrate], @[rollback]

    void add_migration(string name, string up_sql, string down_sql) {
        Migration m = Migration();
        m->name = name;
        m->up_sql = up_sql;
        m->down_sql = down_sql;
        migrations += ({ m });
    }

    //! Run all pending migrations
    //!
    //! @note
    //!   Skips migrations that have already been applied
    //!
    //! @seealso
    //!   @[rollback], @[add_migration]

    void migrate() {
        // Get applied migrations
        array(mapping) applied = db->query("SELECT name FROM schema_migrations");
        array(string) applied_names = map(applied, lambda(mapping m) {
            return (string)m->name;
        });

        // Apply pending migrations
        foreach (migrations, Migration m) {
            if (!has_value(applied_names, m->name)) {
                werror("Applying migration: %s\n", m->name);

                db->query("BEGIN TRANSACTION");

                mixed err = catch {
                    db->query(m->up_sql);
                    db->query("INSERT INTO schema_migrations (name) VALUES (%s)",
                             m->name);
                    db->query("COMMIT");
                };

                if (err) {
                    db->query("ROLLBACK");
                    werror("Migration failed: %s\n", describe_error(err));
                }
            }
        }
    }

    //! Rollback migrations
    //!
    //! @param steps
    //!   Number of migrations to rollback
    //!
    //! @seealso
    //!   @[migrate]

    void rollback(int steps) {
        // Get applied migrations in reverse order
        array(mapping) applied = db->query(
            "SELECT name FROM schema_migrations ORDER BY applied_at DESC LIMIT %d",
            steps
        );

        foreach (applied, mapping m) {
            Migration migration = search_migration_by_name((string)m->name);

            if (migration) {
                werror("Rolling back migration: %s\n", (string)m->name);

                db->query("BEGIN TRANSACTION");

                mixed err = catch {
                    db->query(migration->down_sql);
                    db->query("DELETE FROM schema_migrations WHERE name = %s",
                             m->name);
                    db->query("COMMIT");
                };

                if (err) {
                    db->query("ROLLBACK");
                    werror("Rollback failed: %s\n", describe_error(err));
                }
            }
        }
    }

    private Migration search_migration_by_name(string name) {
        foreach (migrations, Migration m) {
            if (m->name == name) {
                return m;
            }
        }
        return 0;
    }
}

//! Example: Database migrations
//!
//! @seealso
//!   @[maintainability_logging]

void maintainability_migrations() {
    werror("\n=== Maintainability: Database Migrations ===\n");

    Sql.Sql db = Sql.Sql("sqlite:///tmp/test.db");
    MigrationManager manager = MigrationManager(db);

    // Define migrations
    manager->add_migration(
        "001_create_users_table",
        "CREATE TABLE users ("
        "id INTEGER PRIMARY KEY, "
        "username TEXT UNIQUE NOT NULL, "
        "email TEXT UNIQUE NOT NULL, "
        "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")",
        "DROP TABLE users"
    );

    manager->add_migration(
        "002_create_posts_table",
        "CREATE TABLE posts ("
        "id INTEGER PRIMARY KEY, "
        "user_id INTEGER NOT NULL, "
        "title TEXT NOT NULL, "
        "content TEXT, "
        "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
        "FOREIGN KEY (user_id) REFERENCES users(id)"
        ")",
        "DROP TABLE posts"
    );

    // Run migrations
    manager->migrate();

    werror("Migrations completed\n");
}

//! Example: Logging database operations
//!
//! Database wrapper that logs all queries
//!
//! @seealso
//!   @[UserRepository]

class LoggingDatabase {
    private Sql.Sql db;
    private string log_file;

    //! Create logging database wrapper
    //!
    //! @param db
    //!   Database connection to wrap
    //! @param log_file
    //!   Path to log file
    //!
    //! @seealso
    //!   @[query], @[typed_query]

    void create(Sql.Sql db, string log_file) {
        this::db = db;
        this::log_file = log_file;
    }

    //! Log query to file
    //!
    //! @param query
    //!   SQL query string
    //! @param bindings
    //!   Optional parameter bindings
    //!
    //! @seealso
    //!   @[query]

    private void log_query(string query, mapping|void bindings) {
        string log_entry = sprintf("[%s] Query: %s\n",
                                  Calendar.now()->format_time(), query);

        if (bindings) {
            log_entry += sprintf("Bindings: %O\n", bindings);
        }

        Stdio.append_file(log_file, log_entry);
    }

    //! Execute query with logging
    //!
    //! @param query
    //!   SQL query string
    //! @param extraargs
    //!   Optional parameter bindings
    //! @returns
    //!   Query result array
    //!
    //! @seealso
    //!   @[typed_query]

    array(mapping) query(string query, mixed... extraargs) {
        mapping|void bindings = sizeof(extraargs) && mappingp(extraargs[0]) ?
                               (mapping)extraargs[0] : UNDEFINED;
        log_query(query, bindings);
        return db->query(query, @extraargs);
    }

    //! Execute typed query with logging
    //!
    //! @param query
    //!   SQL query string
    //! @param extraargs
    //!   Optional parameter bindings
    //! @returns
    //!   Typed query result array
    //!
    //! @seealso
    //!   @[query]

    array(mapping) typed_query(string query, mixed... extraargs) {
        mapping|void bindings = sizeof(extraargs) && mappingp(extraargs[0]) ?
                               (mapping)extraargs[0] : UNDEFINED;
        log_query(query, bindings);
        return db->typed_query(query, @extraargs);
    }
}

//! Example: Query logging
//!
//! @seealso
//!   @[UserRepository]

void maintainability_logging() {
    werror("\n=== Maintainability: Query Logging ===\n");

    Sql.Sql raw_db = Sql.Sql("sqlite://example.db");
    LoggingDatabase db = LoggingDatabase(raw_db, "/tmp/db_queries.log");

    // Queries will be logged
    db->query("SELECT * FROM users LIMIT 5");

    werror("Query executed and logged\n");
    werror("Check log file: %s\n", "/tmp/db_queries.log");
}

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    // Security examples
    security_parameter_binding();
    security_password_handling();
    security_least_privilege();
    security_input_validation();

    // Performance examples
    performance_indexes();
    performance_column_types();
    performance_query_analysis();
    performance_batch_operations();
    performance_connection_pooling();
    performance_prepared_statements();

    // Maintainability examples
    maintainability_repository();
    maintainability_migrations();
    maintainability_logging();

    return 0;
}
