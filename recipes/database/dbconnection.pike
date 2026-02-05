#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

//! Database connection examples for Pike 8
//!
//! Demonstrates connection to PostgreSQL, MySQL, and SQLite
//!
//! @example
//!   // Simple SQLite connection
//!   Sql.Sql db = Sql.Sql("sqlite://test.db");
//!
//!   // PostgreSQL with authentication
//!   Sql.Sql pgsql = Sql.Sql("pgsql://user:pass@localhost:5432/db");
//!
//! @note
//!   Connection URL format: dbtype://[user[:password]@]host[:port]/database
//!   For SQLite, use: sqlite://path/to/database.db or sqlite://:memory: for in-memory
//!
//! @seealso
//!   @[Sql.Sql], @[basic_queries], @[advanced_operations]

constant DB_POSTGRESQL = 1;
constant DB_MYSQL = 2;
constant DB_SQLITE = 3;

//! Database connection manager
//!
//! Provides a wrapper around Sql.Sql with enhanced connection management
//!
//! @example
//!   DatabaseManager db = DatabaseManager("sqlite://test.db");
//!   int status = db->ping();
//!   db->close();
//!
//! @seealso
//!   @[ConnectionPool]

class DatabaseManager {
    private Sql.Sql con;
    private string db_type;

    //! Create a new database connection
    //!
    //! @param url
    //!   Database URL format: dbtype://[user[:password]@]host[:port]/database
    //!
    //! @note
    //!   Automatically sets charset to unicode for proper string handling
    //!
    //! @throws
    //!   Error if connection fails

    void create(string url) {
        db_type = get_db_type(url);
        con = Sql.Sql(url);

        if (!con) {
            error("Failed to connect to database: %s\n", url);
        }

        // Set charset to unicode for proper string handling
        if (con->get_charset) {
            con->set_charset("unicode");
        }

        werror("Connected to %s database\n", db_type);
    }

    //! Get database type from URL
    //!
    //! @param url
    //!   Database connection URL
    //! @returns
    //!   Uppercase database type (e.g., "PGSQL", "MYSQL", "SQLITE")
    //!
    //! @seealso
    //!   @[create]

    private string get_db_type(string url) {
        sscanf(url, "%s://", string type);
        return upper_case(type);
    }

    //! Check if connection is alive
    //!
    //! @returns
    //!   0 if connected, 1 if reconnected, -1 if disconnected/error
    //!
    //! @seealso
    //!   @[status], @[server_info]

    int ping() {
        return con->ping();
    }

    //! Get connection status
    //!
    //! @returns
    //!   String describing connection status: "connected", "reconnected", or "disconnected"
    //!
    //! @seealso
    //!   @[ping], @[server_info]

    string status() {
        int ping_result = ping();

        if (ping_result == 0) {
            return "connected";
        } else if (ping_result == 1) {
            return "reconnected";
        } else {
            return "disconnected";
        }
    }

    //! Get server information
    //!
    //! @returns
    //!   Server version and information string
    //!
    //! @seealso
    //!   @[host_info], @[ping]

    string server_info() {
        return con->server_info();
    }

    //! Get host information
    //!
    //! @returns
    //!   Host connection information string
    //!
    //! @seealso
    //!   @[server_info], @[ping]

    string host_info() {
        return con->host_info();
    }

    //! Close the connection
    //!
    //! @note
    //!   After calling close(), the connection object becomes invalid
    //!
    //! @seealso
    //!   @[create]

    void close() {
        destruct(con);
    }

    //! Get the raw connection for direct operations
    //!
    //! @returns
    //!   The underlying Sql.Sql connection object
    //!
    //! @note
    //!   Use this for advanced operations not covered by DatabaseManager methods
    //!
    //! @seealso
    //!   @[Sql.Sql]

    Sql.Sql get_connection() {
        return con;
    }
}

//! Example: PostgreSQL connection with connection pooling
//!
//! @note
//!   PostgreSQL supports SSL connections using the mysqls:// scheme
//!
//! @seealso
//!   @[mysql_example], @[sqlite_example]

void postgresql_example() {
    werror("\n=== PostgreSQL Connection Example ===\n");

    // Connect to PostgreSQL
    Sql.Sql pgsql = Sql.Sql(
        "pgsql://localhost:5432/testdb"
    );

    // Alternative: connect with authentication
    Sql.Sql pgsql_auth = Sql.Sql(
        "pgsql://user:password@localhost:5432/testdb"
    );

    // Alternative: use options mapping
    Sql.Sql pgsql_options = Sql.Sql("pgsql://host", "database",
        "user", "password", ([
            "use_ssl": 1,
            "reconnect": -1,
            "cache_autoprepared_statements": 1
        ]));

    werror("PostgreSQL server: %s\n", pgsql->server_info());
    werror("PostgreSQL host: %s\n", pgsql->host_info());

    // Check connection status
    int ping_result = pgsql->ping();
    werror("Connection status: %d\n", ping_result);
}

//! Example: MySQL connection
//!
//! @note
//!   MySQL SSL connections use the mysqls:// scheme
//!
//! @seealso
//!   @[postgresql_example], @[sqlite_example]

void mysql_example() {
    werror("\n=== MySQL Connection Example ===\n");

    // Connect to MySQL
    Sql.Sql mysql = Sql.Sql(
        "mysql://localhost:3306/testdb"
    );

    // Alternative: connect with authentication
    Sql.Sql mysql_auth = Sql.Sql(
        "mysql://root:password@localhost:3306/testdb"
    );

    // Alternative: MySQL with SSL
    Sql.Sql mysql_ssl = Sql.Sql(
        "mysqls://user:password@localhost:3306/testdb"
    );

    werror("MySQL server: %s\n", mysql->server_info());
    werror("MySQL host: %s\n", mysql->host_info());
}

//! Example: SQLite connection (file-based)
//!
//! @note
//!   SQLite supports in-memory databases using sqlite://:memory:
//!
//! @seealso
//!   @[postgresql_example], @[mysql_example]

void sqlite_example() {
    werror("\n=== SQLite Connection Example ===\n");

    // SQLite uses file path as database
    Sql.Sql sqlite = Sql.Sql("sqlite://test.db");

    // In-memory SQLite database
    Sql.Sql sqlite_memory = Sql.Sql("sqlite://:memory:");

    werror("SQLite database: %s\n", sqlite->server_info());
}

//! Example: Database manager usage
//!
//! @seealso
//!   @[connection_pool_example]

void database_manager_example() {
    werror("\n=== Database Manager Example ===\n");

    // Use SQLite for this example
    DatabaseManager db = DatabaseManager("sqlite://example.db");

    werror("Connection status: %s\n", db.status());
    werror("Server info: %s\n", db.server_info());
    werror("Host info: %s\n", db.host_info());

    // Check if still alive
    int ping_result = db.ping();
    werror("Ping result: %d\n", ping_result);

    db->close();
}

//! Example: Connection pooling simulation
//!
//! Connection pool for managing multiple database connections
//!
//! @example
//!   ConnectionPool pool = ConnectionPool("sqlite://test.db", 5);
//!   Sql.Sql conn = pool->get_connection();
//!   // ... use connection ...
//!   pool->release(conn);
//!
//! @note
//!   This is a simplified example. Production pools need more sophisticated
//!   connection tracking and error handling
//!
//! @seealso
//!   @[DatabaseManager]

class ConnectionPool {
    private string db_url;
    private int max_connections;
    private array(Sql.Sql) connections;
    private Thread.Mutex lock = Thread.Mutex();

    //! Create a connection pool
    //!
    //! @param db_url
    //!   Database connection URL
    //! @param max_connections
    //!   Maximum number of connections in the pool
    //!
    //! @note
    //!   All connections are created immediately upon pool initialization
    //!
    //! @seealso
    //!   @[get_connection], @[close]

    void create(string db_url, int max_connections) {
        this::db_url = db_url;
        this::max_connections = max_connections;
        connections = allocate(max_connections);

        // Initialize connections
        for (int i = 0; i < max_connections; i++) {
            connections[i] = Sql.Sql(db_url);
        }
    }

    //! Get a connection from the pool
    //!
    //! @returns
    //!   A valid Sql.Sql connection object
    //!
    //! @note
    //!   Simple round-robin for demonstration. Production use requires
    //!   proper pool management with connection tracking
    //!
    //! @seealso
    //!   @[release], @[close]

    Sql.Sql get_connection() {
        // Simple round-robin for demonstration
        // In production, use proper pool management
        Thread.MutexKey key = lock->lock();
        Sql.Sql conn = connections[random(max_connections)];
        destruct(key);

        // Verify connection is alive
        if (conn->ping() < 0) {
            // Reconnect if dead
            conn = Sql.Sql(db_url);
        }

        return conn;
    }

    //! Close all connections
    //!
    //! @note
    //!   Closes all connections in the pool and clears the connection array
    //!
    //! @seealso
    //!   @[create], @[get_connection]

    void close() {
        Thread.MutexKey key = lock->lock();
        foreach (connections, Sql.Sql conn) {
            if (conn) {
                destruct(conn);
            }
        }
        connections = ({});
        destruct(key);
    }
}

//! Example: Connection pool usage
//!
//! @seealso
//!   @[database_manager_example]

void connection_pool_example() {
    werror("\n=== Connection Pool Example ===\n");

    // Create a pool of 5 connections
    ConnectionPool pool = ConnectionPool("sqlite://pool.db", 5);

    // Get connections from pool
    Sql.Sql conn1 = pool->get_connection();
    Sql.Sql conn2 = pool->get_connection();

    werror("Got connection 1: %s\n", conn1 ? conn1->server_info() : "null");
    werror("Got connection 2: %s\n", conn2 ? conn2->server_info() : "null");

    pool->close();
}

int main(int argc, array(string) argv) {
    //! @param argc
    //!   Number of command line arguments
    //! @param argv
    //!   Array of command line argument strings
    //! @returns
    //!   Exit code (0 for success)
    //!
    //! @note
    //!   This example demonstrates multiple connection patterns
    //!
    //! @seealso
    //!   @[DatabaseManager], @[ConnectionPool]
    // Run examples
    postgresql_example();
    mysql_example();
    sqlite_example();
    database_manager_example();
    connection_pool_example();

    return 0;
}
