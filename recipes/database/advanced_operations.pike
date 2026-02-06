#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

//! Advanced database operations for Pike 8
//!
//! Demonstrates joins, aggregations, subqueries, and performance optimization
//!
//! @example
//!   // INNER JOIN example
//!   array(mapping) result = db->typed_query(
//!       "SELECT e.name, d.name FROM employees e "
//!       "INNER JOIN departments d ON e.department_id = d.id"
//!   );
//!
//! @note
//!   Use EXPLAIN QUERY PLAN to analyze and optimize query performance
//!
//! @seealso
//!   @[Sql.Sql], @[basic_queries], @[best_practices]

//! Example: INNER JOIN
//!
//! Demonstrates joining tables to combine related data
//!
//! @seealso
//!   @[left_join_example], @[aggregation_example]

void join_example() {
    werror("\n=== JOIN Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Create tables
    db->query("CREATE TABLE IF NOT EXISTS departments ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT)");

    db->query("CREATE TABLE IF NOT EXISTS employees ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "department_id INTEGER, "
              "salary REAL, "
              "FOREIGN KEY (department_id) REFERENCES departments(id))");

    // Insert test data
    db->query("INSERT INTO departments (id, name) VALUES "
              "(1, 'Engineering'), "
              "(2, 'Sales'), "
              "(3, 'Marketing')");

    db->query("INSERT INTO employees (name, department_id, salary) VALUES "
              "('Alice', 1, 80000.0), "
              "('Bob', 1, 75000.0), "
              "('Charlie', 2, 65000.0), "
              "('David', 2, 70000.0), "
              "('Eve', 3, 60000.0)");

    // INNER JOIN - only matching records
    array(mapping) inner_join =
        db->typed_query("SELECT e.name as employee, "
                       "d.name as department, "
                       "e.salary "
                       "FROM employees e "
                       "INNER JOIN departments d ON e.department_id = d.id "
                       "ORDER BY e.salary DESC");

    werror("Employees with departments:\n");
    foreach (inner_join, mapping row) {
        werror("  %s - %s: $%.2f\n",
               (string)row->employee, (string)row->department, (float)row->salary);
    }
}

//! Example: LEFT JOIN and RIGHT JOIN
//!
//! @note
//!   LEFT JOIN includes all rows from left table, even if no match in right table
//!
//! @seealso
//!   @[join_example], @[aggregation_example]

void left_join_example() {
    werror("\n=== LEFT JOIN Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Add employee without department
    db->query("INSERT INTO employees (name, department_id, salary) "
             "VALUES ('Frank', NULL, 55000.0)");

    // LEFT JOIN - all employees, even without department
    array(mapping) left_join =
        db->typed_query("SELECT e.name as employee, "
                       "d.name as department "
                       "FROM employees e "
                       "LEFT JOIN departments d ON e.department_id = d.id");

    werror("All employees (including unassigned):\n");
    foreach (left_join, mapping row) {
        werror("  %s - %s\n",
               (string)row->employee, (string)(row->department || "(No department)"));
    }
}

//! Example: GROUP BY and aggregation
//!
//! @note
//!   Use HAVING clause for filtering after aggregation (vs WHERE for before)
//!
//! @seealso
//!   @[join_example], @[union_subquery_example]

void aggregation_example() {
    werror("\n=== Aggregation Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Count employees per department
    array(mapping) count_result =
        db->typed_query("SELECT d.name as department, "
                       "COUNT(e.id) as employee_count, "
                       "AVG(e.salary) as avg_salary, "
                       "MAX(e.salary) as max_salary, "
                       "MIN(e.salary) as min_salary "
                       "FROM departments d "
                       "LEFT JOIN employees e ON d.id = e.department_id "
                       "GROUP BY d.id, d.name "
                       "ORDER BY employee_count DESC");

    werror("Department statistics:\n");
    foreach (count_result, mapping row) {
        werror("  %s: %d employees, avg salary: $%.2f (range: $%.2f - $%.2f)\n",
               (string)row->department, (int)row->employee_count,
               (float)row->avg_salary,
               (float)row->min_salary,
               (float)row->max_salary);
    }

    // HAVING clause
    array(mapping) having_result =
        db->typed_query("SELECT d.name as department, "
                       "AVG(e.salary) as avg_salary "
                       "FROM departments d "
                       "JOIN employees e ON d.id = e.department_id "
                       "GROUP BY d.id, d.name "
                       "HAVING AVG(e.salary) > 60000");

    werror("\nDepartments with avg salary > $60000:\n");
    foreach (having_result, mapping row) {
        werror("  %s: $%.2f\n", (string)row->department, (float)row->avg_salary);
    }
}

//! Example: UNION and subqueries
//!
//! @note
//!   UNION combines result sets. Subqueries allow nested queries
//!
//! @seealso
//!   @[aggregation_example], @[cte_example]

void union_subquery_example() {
    werror("\n=== UNION and Subquery Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Create projects table
    db->query("CREATE TABLE IF NOT EXISTS projects ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "budget REAL)");

    db->query("INSERT INTO projects (name, budget) VALUES "
              "('Project A', 50000.0), "
              "('Project B', 75000.0), "
              "('Project C', 100000.0)");

    // UNION - combine results
    array(mapping) union_result =
        db->typed_query("SELECT name, 'employee' as type, salary as amount "
                       "FROM employees "
                       "UNION "
                       "SELECT name, 'project' as type, budget as amount "
                       "FROM projects "
                       "ORDER BY amount DESC "
                       "LIMIT 5");

    werror("Top 5 by amount (employees + projects):\n");
    foreach (union_result, mapping row) {
        werror("  %s (%s): $%.2f\n", (string)row->name, (string)row->type, (float)row->amount);
    }

    // Subquery
    array(mapping) subquery_result =
        db->typed_query("SELECT name, salary "
                       "FROM employees "
                       "WHERE salary > (SELECT AVG(salary) FROM employees)");

    werror("\nEmployees earning above average:\n");
    foreach (subquery_result, mapping row) {
        werror("  %s: $%.2f\n", (string)row->name, (float)row->salary);
    }

    // EXISTS subquery
    array(mapping) exists_result =
        db->typed_query("SELECT d.name as department "
                       "FROM departments d "
                       "WHERE EXISTS ("
                       "  SELECT 1 FROM employees e "
                       "  WHERE e.department_id = d.id "
                       "  AND e.salary > 70000"
                       ")");

    werror("\nDepartments with employees earning > $70000:\n");
    foreach (exists_result, mapping row) {
        werror("  %s\n", (string)row->department);
    }
}

//! Example: Window functions (PostgreSQL)
//!
//! @note
//!   Window functions require PostgreSQL or other advanced databases
//!
//! @seealso
//!   @[cte_example]

void window_function_example() {
    werror("\n=== Window Function Example (PostgreSQL) ===\n");

    // This example requires PostgreSQL
    // Sql.Sql db = Sql.Sql("pgsql://localhost/testdb");

    // ROW_NUMBER()
    /*array(mapping) row_num =
        db->typed_query("SELECT name, department_id, salary, "
                       "ROW_NUMBER() OVER (PARTITION BY department_id "
                       "ORDER BY salary DESC) as rank "
                       "FROM employees");

    werror("Employee ranking by department:\n");
    foreach (row_num, mapping row) {
        werror("  %s (dept %d): rank %d, salary $%.2f\n",
               row->name, row->department_id, row->rank, row->salary);
    }

    // Running total
    array(mapping) running_total =
        db->typed_query("SELECT name, salary, "
                       "SUM(salary) OVER (ORDER BY salary) as running_total "
                       "FROM employees "
                       "ORDER BY salary");

    werror("\nRunning total of salaries:\n");
    foreach (running_total, mapping row) {
        werror("  %s: $%.2f (total: $%.2f)\n",
               row->name, row->salary, row->running_total);
    }*/
}

//! Example: Common Table Expressions (CTE)
//!
//! @note
//!   CTEs improve readability and enable recursive queries
//!
//! @seealso
//!   @[union_subquery_example], @[query_compilation_example]

void cte_example() {
    werror("\n=== Common Table Expression Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Simple CTE
    array(mapping) cte_result =
        db->typed_query("WITH high_salary_employees AS ("
                       "  SELECT name, salary, department_id "
                       "  FROM employees "
                       "  WHERE salary > 70000"
                       ") "
                       "SELECT e.name, d.name as department "
                       "FROM high_salary_employees e "
                       "JOIN departments d ON e.department_id = d.id");

    werror("High salary employees with departments:\n");
    foreach (cte_result, mapping row) {
        werror("  %s - %s\n", (string)row->name, (string)row->department);
    }

    // Recursive CTE (hierarchical data)
    db->query("CREATE TABLE IF NOT EXISTS categories ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "parent_id INTEGER)");

    db->query("INSERT INTO categories (id, name, parent_id) VALUES "
              "(1, 'Electronics', NULL), "
              "(2, 'Computers', 1), "
              "(3, 'Phones', 1), "
              "(4, 'Laptops', 2), "
              "(5, 'Desktops', 2), "
              "(6, 'Smartphones', 3)");

    array(mapping) hierarchy =
        db->typed_query("WITH RECURSIVE category_tree AS ("
                       "  SELECT id, name, parent_id, 1 as level "
                       "  FROM categories "
                       "  WHERE parent_id IS NULL "
                       "  UNION ALL "
                       "  SELECT c.id, c.name, c.parent_id, ct.level + 1 "
                       "  FROM categories c "
                       "  JOIN category_tree ct ON c.parent_id = ct.id"
                       ") "
                       "SELECT name, level "
                       "FROM category_tree "
                       "ORDER BY level, name");

    werror("\nCategory hierarchy:\n");
    foreach (hierarchy, mapping row) {
        int indent = (int)row->level * 2;
        string indent_str = " " * indent;
        werror("  %s%s\n", indent_str, (string)row->name);
    }
}

//! Example: Query compilation and caching
//!
//! @note
//!   Compile queries once for reuse with different parameters
//!
//! @seealso
//!   @[cte_example], @[performance_monitoring_example]

void query_compilation_example() {
    werror("\n=== Query Compilation Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Compile a query for reuse
    string|object compiled_query = db->compile_query(
        "SELECT * FROM employees WHERE department_id = :dept_id"
    );

    // Execute compiled query multiple times
    for (int dept_id = 1; dept_id <= 3; dept_id++) {
        array(mapping) result = db->query(compiled_query,
                                         (["dept_id": dept_id]));
        werror("Department %d: %d employees\n",
               dept_id, sizeof(result));
    }
}

//! Example: Performance monitoring
//!
//! @note
//!   Use EXPLAIN QUERY PLAN to analyze query performance
//!
//! @seealso
//!   @[query_compilation_example], @[batch_operations_example]

void performance_monitoring_example() {
    werror("\n=== Performance Monitoring Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Time a query
    array(float) times = ({});
    for (int i = 0; i < 10; i++) {
        mixed start = gauge {
            db->query("SELECT * FROM employees WHERE salary > :min_salary",
                     (["min_salary": 60000]));
        };
        times += ({(float)start});
    }

    float avg_time = (float)(`+( @times) / sizeof(times));
    werror("Average query time: %.6f seconds\n", avg_time);

    // Explain query plan (SQLite)
    array(mapping) plan = db->query("EXPLAIN QUERY PLAN "
                                   "SELECT * FROM employees "
                                   "WHERE salary > 60000");

    werror("\nQuery plan:\n");
    foreach (plan, mapping row) {
        // Access fields by string keys for compatibility
        werror("  %s\n", (string)(row->detail || row[0] || ""));
    }
}

//! Example: Batch operations
//!
//! @note
//!   Use transactions for batch operations to improve performance
//!
//! @seealso
//!   @[performance_monitoring_example], @[introspection_example]

void batch_operations_example() {
    werror("\n=== Batch Operations Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Batch insert using transaction
    db->query("BEGIN TRANSACTION");

    for (int i = 0; i < 100; i++) {
        db->query("INSERT INTO employees (name, department_id, salary) "
                 "VALUES (%s, %d, %f)",
                 sprintf("Employee %d", i),
                 random(3) + 1,
                 50000.0 + random(30000));
    }

    db->query("COMMIT");
    werror("Inserted 100 employees\n");

    // Batch update
    db->query("BEGIN TRANSACTION");
    db->query("UPDATE employees SET salary = salary * 1.1 WHERE salary < 60000");
    db->query("COMMIT");
    werror("Updated salaries in batch\n");
}

//! Example: Database introspection
//!
//! @note
//!   Query database metadata to list tables and fields
//!
//! @seealso
//!   @[batch_operations_example]

void introspection_example() {
    werror("\n=== Database Introspection Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // List all tables
    array(string) tables = db->list_tables();
    werror("Tables: %s\n", tables * ", ");

    // List fields in a table
    array(mapping) fields = db->list_fields("employees");
    werror("\nFields in 'employees':\n");
    foreach (fields, mapping field) {
        // Check if flags exists and has not_null field
        mixed flags = field->flags;
        string not_null_suffix = "";
        if (mappingp(flags)) {
            mapping flags_map = (mapping)flags;
            if (flags_map->not_null) {
                not_null_suffix = " NOT NULL";
            }
        }
        werror("  %s: %s%s\n",
               (string)field->name,
               (string)field->type,
               not_null_suffix);
    }

    // List databases (PostgreSQL/MySQL)
    if (db->list_dbs) {
        array(string) databases = db->list_dbs();
        werror("\nDatabases: %s\n", databases * ", ");
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
    join_example();
    left_join_example();
    aggregation_example();
    union_subquery_example();
    // window_function_example(); // Requires PostgreSQL
    cte_example();
    query_compilation_example();
    performance_monitoring_example();
    batch_operations_example();
    introspection_example();

    return 0;
}
