#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

//! Basic SQL query examples for Pike 8
//!
//! Demonstrates query execution, result handling, and prepared statements
//!
//! @example
//!   // Simple query
//!   Sql.Sql db = Sql.Sql("sqlite://test.db");
//!   array(mapping) result = db->query("SELECT * FROM users");
//!
//! @note
//!   Always use parameter binding (%s, %d, or :name) to prevent SQL injection
//!
//! @seealso
//!   @[Sql.Sql], @[typed_query], @[big_query]

//! Example: Simple SELECT query
//!
//! Demonstrates basic query execution and result iteration
//!
//! @seealso
//!   @[typed_query_example], @[big_query_example]

void simple_select_example() {
    werror("\n=== Simple SELECT Query ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Create test table
    db->query("CREATE TABLE IF NOT EXISTS users ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "email TEXT, "
              "age INTEGER)");

    // Insert test data
    db->query("INSERT INTO users (name, email, age) VALUES "
              "('Alice', 'alice@example.com', 30),"
              "('Bob', 'bob@example.com', 25),"
              "('Charlie', 'charlie@example.com', 35)");

    // Simple query - returns array of mappings
    array(mapping(string:mixed)) result = db->query("SELECT * FROM users");

    werror("Found %d users:\n", sizeof(result));
    foreach (result, mapping(string:mixed) row) {
        werror("  %s: %s (age %d)\n",
               row->name, row->email, (int)row->age);
    }
}

//! Example: Typed query for better type safety
//!
//! @note
//!   typed_query returns values with proper types (int, float, string)
//!   instead of everything as strings
//!
//! @seealso
//!   @[simple_select_example], @[big_query_example]

void typed_query_example() {
    werror("\n=== Typed Query Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // typed_query returns properly typed values
    array(mapping(string:mixed)) result =
        db->typed_query("SELECT name, age FROM users WHERE age > :min_age",
                       (["min_age": 28]));

    werror("Users over 28:\n");
    foreach (result, mapping(string:mixed) row) {
        // age is returned as int, not string
        werror("  %s: %d (type: %s)\n",
               row->name, row->age, sprintf("%t", row->age));
    }
}

//! Example: Using big_query for large result sets
//!
//! @note
//!   big_query is memory-efficient for large datasets as it streams results
//!
//! @seealso
//!   @[simple_select_example], @[prepared_statement_example]

void big_query_example() {
    werror("\n=== Big Query Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // big_query returns a result object for streaming
    object res = db->big_query("SELECT * FROM users");

    if (res) {
        werror("Field names: %s\n", res->fetch_fields()->name * ", ");

        // Fetch rows one at a time
        array(mixed) row;
        while ((row = res->fetch_row())) {
            werror("Row: %s\n", row * ", ");
        }

        // Get number of rows
        werror("Total rows: %d\n", res->num_rows());
    }
}

//! Example: Prepared statements with parameter binding
//!
//! @note
//!   Parameter binding prevents SQL injection attacks
//!
//! @seealso
//!   @[sql_injection_prevention]

void prepared_statement_example() {
    werror("\n=== Prepared Statement Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Using named parameters
    array(mapping(string:mixed)) result1 =
        db->query("SELECT * FROM users WHERE age > :min_age AND name = :name",
                 (["min_age": 25, "name": "Alice"]));

    werror("Query result (named params): %d rows\n", sizeof(result1));

    // Using positional parameters (sprintf-style)
    array(mapping(string:mixed)) result2 =
        db->query("SELECT * FROM users WHERE age > %d", 28);

    werror("Query result (positional params): %d rows\n", sizeof(result2));
}

//! Example: INSERT operations
//!
//! @seealso
//!   @[update_example], @[delete_example]

void insert_example() {
    werror("\n=== INSERT Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Simple insert
    db->query("INSERT INTO users (name, email, age) "
             "VALUES ('David', 'david@example.com', 40)");

    // Insert with parameters (safe from SQL injection)
    db->query("INSERT INTO users (name, email, age) "
             "VALUES (%s, %s, %d)",
             "Eve", "eve@example.com", 28);

    // Insert with named parameters
    db->query("INSERT INTO users (name, email, age) "
             "VALUES (:name, :email, :age)",
             (["name": "Frank", "email": "frank@example.com", "age": 33]));

    // Check inserted data
    array(mapping) count = db->query("SELECT COUNT(*) as count FROM users");
    werror("Total users: %s\n", count[0]->count);
}

//! Example: UPDATE operations
//!
//! @note
//!   UPDATE returns the number of affected rows
//!
//! @seealso
//!   @[insert_example], @[delete_example]

void update_example() {
    werror("\n=== UPDATE Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Update single record
    db->query("UPDATE users SET age = :new_age WHERE name = :name",
             (["new_age": 31, "name": "Alice"]));

    // Update multiple records
    int affected = db->query("UPDATE users SET age = age + 1 WHERE age < 30");

    werror("Updated %d records\n", affected ? sizeof(affected) : 0);

    // Verify update
    array(mapping) result =
        db->typed_query("SELECT name, age FROM users WHERE name = 'Alice'");
    if (sizeof(result)) {
        werror("Alice's new age: %d\n", (int)result[0]->age);
    }
}

//! Example: DELETE operations
//!
//! @note
//!   Always use WHERE clause with DELETE to avoid deleting all rows
//!
//! @seealso
//!   @[insert_example], @[update_example]

void delete_example() {
    werror("\n=== DELETE Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Delete with condition
    db->query("DELETE FROM users WHERE age > :max_age", (["max_age": 50]));

    // Delete single record
    db->query("DELETE FROM users WHERE name = %s", "Eve");

    // Get remaining count
    array(mapping) count = db->query("SELECT COUNT(*) as count FROM users");
    werror("Remaining users: %s\n", count[0]->count);
}

//! Example: Transaction management
//!
//! @note
//!   Use BEGIN TRANSACTION, COMMIT, and ROLLBACK for atomic operations
//!
//! @seealso
//!   @[error_handling_example]

void transaction_example() {
    werror("\n=== Transaction Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Begin transaction
    db->query("BEGIN TRANSACTION");

    mixed err = catch {
        // Multiple operations
        db->query("INSERT INTO users (name, email, age) "
                 "VALUES ('Grace', 'grace@example.com', 29)");
        db->query("UPDATE users SET age = age + 1 WHERE name = 'Bob'");

        // Commit if all successful
        db->query("COMMIT");
        werror("Transaction committed successfully\n");
    };

    if (err) {
        // Rollback on error
        db->query("ROLLBACK");
        werror("Transaction rolled back: %s\n", err[0]);
    }
}

//! Example: Error handling
//!
//! @note
//!   Always wrap database operations in catch blocks for proper error handling
//!
//! @seealso
//!   @[transaction_example]

void error_handling_example() {
    werror("\n=== Error Handling Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Try to query non-existent table
    mixed err = catch {
        db->query("SELECT * FROM nonexistent_table");
    };

    if (err) {
        werror("Caught error: %s\n", err[0]);

        // Get last database error
        if (db->error) {
            werror("Database error: %s\n", db->error());
        }
    }

    // Try invalid SQL
    err = catch {
        db->query("INVALID SQL STATEMENT");
    };

    if (err) {
        werror("Caught SQL error: %s\n", err[0]);
    }
}

//! Example: SQL injection prevention
//!
//! @note
//!   NEVER concatenate user input into SQL queries. Always use parameter binding
//!
//! @seealso
//!   @[prepared_statement_example]

void sql_injection_prevention() {
    werror("\n=== SQL Injection Prevention ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // DANGEROUS: Direct string concatenation (vulnerable to SQL injection)
    string unsafe_input = "'; DROP TABLE users; --";
    // This would be dangerous:
    // string bad_query = "SELECT * FROM users WHERE name = '" + unsafe_input + "'";

    // SAFE: Using parameter binding
    string user_input = "Alice";

    // Using sprintf-style parameters
    array(mapping) result1 =
        db->query("SELECT * FROM users WHERE name = %s", user_input);
    werror("Safe query 1: %d rows\n", sizeof(result1));

    // Using named parameters
    array(mapping) result2 =
        db->query("SELECT * FROM users WHERE name = :name",
                 (["name": user_input]));
    werror("Safe query 2: %d rows\n", sizeof(result2));

    // Manual quoting (when needed)
    string quoted = db->quote(unsafe_input);
    werror("Quoted string: %s\n", quoted);
}

//! Example: Working with NULL values
//!
//! @note
//!   NULL values are represented as Val.null in Pike
//!
//! @seealso
//!   @[insert_example]

void null_handling_example() {
    werror("\n=== NULL Handling Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Create table with nullable column
    db->query("CREATE TABLE IF NOT EXISTS products ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "description TEXT, "
              "price REAL)");

    // Insert with NULL value
    db->query("INSERT INTO products (name, description, price) "
             "VALUES ('Widget', NULL, 9.99)");

    // Query and check for NULL
    array(mapping) result = db->query("SELECT * FROM products");

    foreach (result, mapping row) {
        if (row->description == Val.null) {
            werror("%s has no description (NULL)\n", row->name);
        } else {
            werror("%s: %s\n", row->name, row->description || "(none)");
        }
    }
}

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    // Run all examples
    simple_select_example();
    typed_query_example();
    big_query_example();
    prepared_statement_example();
    insert_example();
    update_example();
    delete_example();
    transaction_example();
    error_handling_example();
    sql_injection_prevention();
    null_handling_example();

    return 0;
}
