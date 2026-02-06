#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

//! Asynchronous database operations for Pike 8
//!
//! Demonstrates async queries with threads and big_query for streaming
//!
//! @example
//!   // Use big_query for large result sets
//!   object result = db->big_query("SELECT * FROM large_table");
//!   array(mixed) row;
//!   while ((row = result->fetch_row())) {
//!     // Process row
//!   }
//!
//! @note
//!   Async operations use threads internally. Ensure thread safety when
//!   sharing connections between async operations
//!
//! @seealso
//!   @[Thread.Thread], @[big_query]

//! Example: Basic async query with streaming results
//!
//! @note
//!   big_query provides memory-efficient streaming for large result sets
//!
//! @seealso
//!   @[streaming_results_example], @[batch_async_example]

void async_query_example() {
    werror("\n=== Async Query Example ===\n");

    // Create database connection
    Sql.Sql db = Sql.Sql("sqlite://:memory:");

    // Create test table and data
    db->query("CREATE TABLE IF NOT EXISTS users ("
              "id INTEGER PRIMARY KEY, "
              "name TEXT, "
              "age INTEGER)");

    db->query("INSERT INTO users (name, age) VALUES "
              "('Alice', 30), "
              "('Bob', 25), "
              "('Charlie', 35)");

    // Use big_query for streaming results (memory-efficient)
    mixed big_result = db->big_query(
        "SELECT * FROM users WHERE age > :min_age",
        (["min_age": 25])
    );

    // Process results when available
    if (objectp(big_result)) {
        object result = [object]big_result;
        mixed row_data;
        while ((row_data = result->fetch_row())) {
            if (arrayp(row_data)) {
                werror("Row: %s\n", (array(mixed))row_data * ", ");
            }
        }
    }
}

//! Example: Thread-based async query execution
//!
//! Demonstrates using threads for background query execution
//!
//! @seealso
//!   @[streaming_results_example], @[batch_async_example]

class ThreadedQuery {
    private Sql.Sql db;
    private Thread.Queue result_queue;
    private Thread.Mutex lock = Thread.Mutex();

    //! Create threaded query wrapper
    //!
    //! @param db_url
    //!   Database connection URL
    //!
    //! @seealso
    //!   @[query_async]

    void create(string db_url) {
        db = Sql.Sql(db_url);
        result_queue = Thread.Queue();
    }

    //! Execute query in background thread
    //!
    //! @param query
    //!   SQL query string
    //! @param bindings
    //!   Optional parameter bindings
    //!
    //! @seealso
    //!   @[get_result]

    void query_async(string query, mapping|void bindings) {
        Thread.Thread(do_query, query, bindings);
    }

    private void do_query(string query, mapping|void bindings) {
        mixed err = catch {
            array(mapping) result;

            if (bindings) {
                result = db->query(query, bindings);
            } else {
                result = db->query(query);
            }

            result_queue->write(result);
        };

        if (err) {
            result_queue->write(err);
        }
    }

    //! Get result from async query (blocks until ready)
    //!
    //! @returns
    //!   Query result or error
    //!
    //! @seealso
    //!   @[query_async]

    mixed get_result() {
        return result_queue->read();
    }
}

//! Example: Thread-based async query
//!
//! @seealso
//!   @[streaming_results_example], @[batch_async_example]

void threaded_query_example() {
    werror("\n=== Threaded Query Example ===\n");

    ThreadedQuery tq = ThreadedQuery("sqlite://:memory:");

    // Create test table
    tq->query_async("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)");
    mixed result = tq->get_result();

    // Insert data
    tq->query_async("INSERT INTO users (name, age) VALUES ('Alice', 30), ('Bob', 25)");
    result = tq->get_result();

    // Query asynchronously
    tq->query_async("SELECT * FROM users WHERE age > :min_age", (["min_age": 25]));

    // Do other work while query runs...

    // Get result
    result = tq->get_result();

    if (arrayp(result)) {
        array(mapping) result_array = (array(mapping))result;
        werror("Got %d rows\n", sizeof(result_array));
        foreach (result_array, mapping row) {
            mixed name_val = row->name;
            mixed age_val = row->age;
            if (stringp(name_val) && intp(age_val)) {
                werror("  %s: %d\n", [string]name_val, [int]age_val);
            }
        }
    }
}

//! Example: Streaming large results
//!
//! @note
//!   Use big_query for memory-efficient streaming of large datasets
//!
//! @seealso
//!   @[parallel_queries_example], @[batch_async_example]

void streaming_results_example() {
    werror("\n=== Streaming Results Example ===\n");

    Sql.Sql db = Sql.Sql("sqlite://example.db");

    // Create large dataset
    db->query("CREATE TABLE IF NOT EXISTS large_data ("
              "id INTEGER PRIMARY KEY, "
              "data TEXT)");

    db->query("BEGIN TRANSACTION");
    for (int i = 0; i < 1000; i++) {
        db->query("INSERT INTO large_data (data) VALUES (%s)",
                 sprintf("Data item %d", i));
    }
    db->query("COMMIT");

    // Stream results using big_query
    mixed big_result = db->big_query("SELECT * FROM large_data");

    if (objectp(big_result)) {
        object result = [object]big_result;
        int count = 0;
        mixed row_data;

        // Process rows one at a time (memory efficient)
        while ((row_data = result->fetch_row())) {
            if (arrayp(row_data)) {
                array(mixed) row = (array(mixed))row_data;
                count++;
                if (count <= 5 && sizeof(row) > 1) {
                    mixed data_val = row[1];
                    if (stringp(data_val)) {
                        werror("Row %d: %s\n", count, [string]data_val);
                    }
                }
            }
        }

        werror("Total rows processed: %d\n", count);
    }
}

//! Example: Batch operations with threading
//!
//! Process data in batches using multiple threads
//!
//! @seealso
//!   @[ThreadedQuery], @[batch_async_example]

class BatchProcessor {
    private string db_url;
    private int batch_size;

    //! Create batch processor
    //!
    //! @param db_url
    //!   Database connection URL
    //! @param batch_size
    //!   Number of operations per batch
    //!
    //! @seealso
    //!   @[process_batch]

    void create(string db_url, int batch_size) {
        this::db_url = db_url;
        this::batch_size = batch_size;
    }

    //! Process data in batches
    //!
    //! @param data
    //!   Array of data mappings to process
    //! @param query_template
    //!   sprintf-style query template
    //!
    //! @seealso
    //!   @[create]

    void process_batch(array(mapping) data, string query_template) {
        for (int i = 0; i < sizeof(data); i += batch_size) {
            array(mapping) batch = data[i..i + batch_size - 1];

            Thread.Thread(do_batch, batch, query_template);
        }
    }

    private void do_batch(array(mapping) batch, string query_template) {
        mixed err = catch {
            Sql.Sql db = Sql.Sql(db_url);

            db->query("BEGIN TRANSACTION");

            foreach (batch, mapping row) {
                string query = sprintf(query_template,
                                     row->name, row->email, row->age);
                db->query(query);
            }

            db->query("COMMIT");

            werror("Batch completed: %d records\n", sizeof(batch));
        };

        if (err) {
            if (arrayp(err)) {
                array(mixed) err_arr = (array(mixed))err;
                if (sizeof(err_arr) > 0 && stringp(err_arr[0])) {
                    werror("Batch error: %s\n", [string]err_arr[0]);
                } else {
                    werror("Batch error: %O\n", err);
                }
            } else {
                werror("Batch error: %s\n", describe_error(err));
            }
        }
    }
}

//! Example: Batch operations
//!
//! @seealso
//!   @[streaming_results_example], *[async_pool_example]

void batch_async_example() {
    werror("\n=== Batch Operations Example ===\n");

    // Prepare batch data
    array(mapping) batch_data = ({});
    for (int i = 0; i < 50; i++) {
        batch_data += ([
            "name": sprintf("User%d", i),
            "email": sprintf("user%d@example.com", i),
            "age": 20 + random(40)
        ]);
    }

    BatchProcessor processor = BatchProcessor("sqlite://:memory:", 10);

    // Process in batches of 10
    processor->process_batch(
        batch_data,
        "INSERT INTO users (name, email, age) VALUES ('%s', '%s', %d)"
    );

    // Wait for threads to complete
    sleep(1);

    werror("Batch processing initiated\n");
}

//! Example: Connection pool
//!
//! Thread-safe connection pool for database operations
//!
//! @seealso
//!   @[ThreadedQuery], @[BatchProcessor]

class ConnectionPool {
    private string db_url;
    private int max_connections;
    private array(Sql.Sql) connections;
    private Thread.Queue available;
    private Thread.Mutex lock = Thread.Mutex();

    //! Create connection pool
    //!
    //! @param db_url
    //!   Database connection URL
    //! @param max_connections
    //!   Maximum number of connections in pool
    //!
    //! @seealso
    //!   @[get_connection], @[pooled_query]

    void create(string db_url, int max_connections) {
        this::db_url = db_url;
        this::max_connections = max_connections;

        connections = allocate(max_connections);
        available = Thread.Queue();

        // Initialize connections
        for (int i = 0; i < max_connections; i++) {
            connections[i] = Sql.Sql(db_url);
            available->write(i);
        }
    }

    //! Get connection from pool
    //!
    //! @returns
    //!   Valid database connection from the pool
    //!
    //! @note
    //!   Automatically reconnects if connection is dead
    //!
    //! @seealso
    //!   @[release_connection]

    Sql.Sql get_connection() {
        mixed idx_data = available->read();
        if (!intp(idx_data)) {
            error("Invalid connection index from queue");
        }
        int idx = (int)idx_data;
        Sql.Sql conn = connections[idx];

        // Verify connection
        if (conn->ping() < 0) {
            Thread.MutexKey key = lock->lock();
            conn = connections[idx] = Sql.Sql(db_url);
            destruct(key);
        }

        return conn;
    }

    //! Return connection to pool
    //!
    //! @param conn
    //!   Connection to return to the pool
    //!
    //! @seealso
    //!   @[get_connection]

    void release_connection(Sql.Sql conn) {
        Thread.MutexKey key = lock->lock();
        int idx = search(connections, conn);
        if (idx >= 0) {
            available->write(idx);
        }
        destruct(key);
    }
}

//! Example: Connection pool
//!
//! @seealso
//!   @[batch_async_example]

void pool_example() {
    werror("\n=== Connection Pool Example ===\n");

    ConnectionPool pool = ConnectionPool("sqlite://:memory:", 5);

    // Get connection and execute query
    Sql.Sql conn = pool->get_connection();
    array(mapping) result = conn->query("SELECT 1 as test");

    werror("Query result: %O\n", result);

    pool->release_connection(conn);
}

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    // Run examples
    async_query_example();
    threaded_query_example();
    streaming_results_example();
    batch_async_example();
    pool_example();

    return 0;
}
