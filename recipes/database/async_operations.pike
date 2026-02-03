#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

//! Asynchronous database operations for Pike 8
//! Demonstrates async queries with Future/Promise and PostgreSQL

//! Example: Basic async query with PostgreSQL
void async_query_example() {
    werror("\n=== Async Query Example ===\n");

    Sql.Sql db = Sql.Sql("pgsql://localhost/testdb");

    // PostgreSQL supports async queries through callbacks
    // Note: This is PostgreSQL-specific functionality

    // Create a simple async query
    object result = db->big_query(
        "SELECT * FROM users WHERE age > :min_age",
        (["min_age": 25])
    );

    // Process results when available
    if (result) {
        array(mixed) row;
        while ((row = result->fetch_row())) {
            werror("Row: %s\n", row * ", ");
        }
    }
}

//! Example: Using Future/Promise for async operations
class AsyncDatabase {
    private Sql.Sql db;
    private Thread.Queue queue;

    //! Create async database wrapper
    void create(string db_url) {
        db = Sql.Sql(db_url);
        queue = Thread.Queue();
    }

    //! Execute query asynchronously
    Promise query_async(string query, mapping|void bindings) {
        Promise promise = Promise();

        Thread.Thread(do_query, promise, query, bindings);

        return promise;
    }

    //! Worker thread for query execution
    private void do_query(Promise promise, string query, mapping|void bindings) {
        mixed err = catch {
            array(mapping) result;

            if (bindings) {
                result = db->query(query, bindings);
            } else {
                result = db->query(query);
            }

            promise->success(result);
        };

        if (err) {
            promise->failure(err);
        }
    }

    //! Execute typed query asynchronously
    Promise typed_query_async(string query, mapping|void bindings) {
        Promise promise = Promise();

        Thread.Thread(do_typed_query, promise, query, bindings);

        return promise;
    }

    private void do_typed_query(Promise promise, string query, mapping|void bindings) {
        mixed err = catch {
            array(mapping) result;

            if (bindings) {
                result = db->typed_query(query, bindings);
            } else {
                result = db->typed_query(query);
            }

            promise->success(result);
        };

        if (err) {
            promise->failure(err);
        }
    }
}

void future_promise_example() {
    werror("\n=== Future/Promise Example ===\n");

    AsyncDatabase async_db = AsyncDatabase("sqlite://example.db");

    // Query with Future/Promise
    Promise query_promise = async_db->query_async(
        "SELECT * FROM users LIMIT 5"
    );

    // Use the Future
    Future query_future = query_promise->future();

    // Wait for result (in real app, you'd do other work here)
    mixed result = query_future->get();

    if (arrayp(result)) {
        werror("Got %d rows\n", sizeof(result));
    } else {
        werror("Query failed: %O\n", result);
    }

    // Multiple async queries
    array(Future) futures = ({
        async_db->query_async("SELECT COUNT(*) as count FROM users")->future(),
        async_db->typed_query_async("SELECT AVG(age) as avg_age FROM users")->future(),
    });

    // Wait for all to complete
    foreach (futures, Future f) {
        mixed res = f->get();
        if (arrayp(res) && sizeof(res)) {
            werror("Result: %O\n", res[0]);
        }
    }
}

//! Example: Parallel query execution
void parallel_queries_example() {
    werror("\n=== Parallel Queries Example ===\n");

    AsyncDatabase async_db = AsyncDatabase("sqlite://example.db");

    // Execute multiple queries in parallel
    array(Promise) promises = ({
        async_db->query_async("SELECT * FROM users WHERE age > 30"),
        async_db->query_async("SELECT * FROM users WHERE age <= 30"),
        async_db->typed_query_async("SELECT AVG(age) as avg FROM users"),
    });

    // Process results as they complete
    foreach (promises, Promise p) {
        Future f = p->future();

        // Add callback for when result is ready
        f->on_success(lambda(mixed result) {
            if (arrayp(result)) {
                werror("Query returned %d rows\n", sizeof(result));
            }
        });

        f->on_failure(lambda(mixed error) {
            werror("Query failed: %O\n", error);
        });
    }

    // Wait for all to complete
    foreach (promises, Promise p) {
        p->future()->get();
    }

    werror("All parallel queries completed\n");
}

//! Example: Streaming large results
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
    object result = db->big_query("SELECT * FROM large_data");

    if (result) {
        int count = 0;
        array(mixed) row;

        // Process rows one at a time (memory efficient)
        while ((row = result->fetch_row())) {
            count++;
            if (count <= 5) {
                werror("Row %d: %s\n", count, row[1]);
            }
        }

        werror("Total rows processed: %d\n", count);
    }
}

//! Example: Batch async operations
class BatchProcessor {
    private AsyncDatabase db;
    private int batch_size;

    void create(string db_url, int batch_size) {
        db = AsyncDatabase(db_url);
        this::batch_size = batch_size;
    }

    //! Process data in batches
    array(Future) process_batch(array(mapping) data, string query_template) {
        array(Future) results = ({});

        for (int i = 0; i < sizeof(data); i += batch_size) {
            array(mapping) batch = data[i..i + batch_size - 1];

            Promise p = Promise();
            results += ({p->future()});

            Thread.Thread(do_batch, p, batch, query_template);
        }

        return results;
    }

    private void do_batch(Promise promise, array(mapping) batch,
                         string query_template) {
        mixed err = catch {
            Sql.Sql db = Sql.Sql("sqlite://example.db");

            db->query("BEGIN TRANSACTION");

            foreach (batch, mapping row) {
                string query = sprintf(query_template,
                                     row->name, row->email, row->age);
                db->query(query);
            }

            db->query("COMMIT");

            promise->success(sizeof(batch));
        };

        if (err) {
            promise->failure(err);
        }
    }
}

void batch_async_example() {
    werror("\n=== Batch Async Operations Example ===\n");

    // Prepare batch data
    array(mapping) batch_data = ({});
    for (int i = 0; i < 50; i++) {
        batch_data += ([([
            "name": sprintf("User%d", i),
            "email": sprintf("user%d@example.com", i),
            "age": 20 + random(40)
        ])]);
    }

    BatchProcessor processor = BatchProcessor("sqlite://example.db", 10);

    // Process in batches of 10
    array(Future) futures = processor->process_batch(
        batch_data,
        "INSERT INTO users (name, email, age) VALUES ('%s', '%s', %d)"
    );

    // Wait for all batches
    int total_inserted = 0;
    foreach (futures, Future f) {
        mixed result = f->get();
        if (intp(result)) {
            total_inserted += result;
        }
    }

    werror("Total inserted: %d\n", total_inserted);
}

//! Example: Connection pool with async support
class AsyncConnectionPool {
    private string db_url;
    private int max_connections;
    private array(Sql.Sql) connections;
    private Thread.Queue available;
    private Thread.Mutex lock = Thread.Mutex();

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

    //! Get connection from pool (async-friendly)
    Sql.Sql get_connection() {
        int idx = available->read();
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
    void release_connection(Sql.Sql conn) {
        // Find connection index
        Thread.MutexKey key = lock->lock();
        int idx = search(connections, conn);
        if (idx >= 0) {
            available->write(idx);
        }
        destruct(key);
    }

    //! Execute query with pooled connection
    Promise pooled_query(string query, mapping|void bindings) {
        Promise promise = Promise();

        Thread.Thread(do_pooled_query, promise, query, bindings);

        return promise;
    }

    private void do_pooled_query(Promise promise, string query,
                                 mapping|void bindings) {
        Sql.Sql conn = get_connection();

        mixed err = catch {
            array(mapping) result;

            if (bindings) {
                result = conn->query(query, bindings);
            } else {
                result = conn->query(query);
            }

            release_connection(conn);
            promise->success(result);
        };

        if (err) {
            release_connection(conn);
            promise->failure(err);
        }
    }
}

void async_pool_example() {
    werror("\n=== Async Connection Pool Example ===\n");

    AsyncConnectionPool pool = AsyncConnectionPool("sqlite://example.db", 5);

    // Execute multiple queries using pool
    array(Promise) promises = ({
        pool->pooled_query("SELECT COUNT(*) as count FROM users"),
        pool->pooled_query("SELECT AVG(age) as avg_age FROM users"),
        pool->pooled_query("SELECT * FROM users LIMIT 5"),
    });

    // Process results
    foreach (promises, Promise p) {
        mixed result = p->future()->get();
        if (arrayp(result)) {
            werror("Query completed: %d rows\n", sizeof(result));
        }
    }
}

//! Example: Async query with timeout
class QueryWithTimeout {
    private AsyncDatabase db;

    void create(string db_url) {
        db = AsyncDatabase(db_url);
    }

    //! Execute query with timeout
    Promise query_with_timeout(string query, void|mapping bindings,
                               int timeout_seconds) {
        Promise promise = Promise();
        Future query_future = db->query_async(query, bindings)->future();

        // Create timeout thread
        Thread.Thread(timeout_thread, promise, query_future, timeout_seconds);

        return promise;
    }

    private void timeout_thread(Promise promise, Future query_future,
                               int timeout_seconds) {
        int start = time();

        while ((time() - start) < timeout_seconds) {
            if (query_future->ready()) {
                // Query completed
                mixed result = query_future->get();
                if (arrayp(result)) {
                    promise->success(result);
                } else {
                    promise->failure(result);
                }
                return;
            }
            sleep(0.1);
        }

        // Timeout reached
        promise->failure(("Query timeout after %d seconds\n", timeout_seconds));
    }
}

void timeout_example() {
    werror("\n=== Query Timeout Example ===\n");

    QueryWithTimeout db = QueryWithTimeout("sqlite://example.db");

    // Query with 5 second timeout
    Promise p = db->query_with_timeout(
        "SELECT * FROM users",
        0,
        5
    );

    Future f = p->future();

    mixed result = f->get();
    if (arrayp(result)) {
        werror("Query completed: %d rows\n", sizeof(result));
    } else {
        werror("Query failed or timed out: %O\n", result);
    }
}

int main(int argc, array(string) argv) {
    // Run examples
    async_query_example();
    future_promise_example();
    parallel_queries_example();
    streaming_results_example();
    batch_async_example();
    async_pool_example();
    timeout_example();

    return 0;
}
