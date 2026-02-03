#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

//! Database connection examples for Pike 8
//! Demonstrates connection to PostgreSQL, MySQL, and SQLite

constant DB_POSTGRESQL = 1;
constant DB_MYSQL = 2;
constant DB_SQLITE = 3;

class DatabaseManager {
    private Sql.Sql con;
    private string db_type;

    //! Create a new database connection
    //! @param url - Database URL format: dbtype://[user[:password]@]host[:port]/database
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
    private string get_db_type(string url) {
        sscanf(url, "%s://", string type);
        return upper_case(type);
    }

    //! Check if connection is alive
    int ping() {
        return con->ping();
    }

    //! Get connection status
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
    string server_info() {
        return con->server_info();
    }

    //! Get host information
    string host_info() {
        return con->host_info();
    }

    //! Close the connection
    void close() {
        destruct(con);
    }

    //! Get the raw connection for direct operations
    Sql.Sql get_connection() {
        return con;
    }
}

//! Example: PostgreSQL connection with connection pooling
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
void sqlite_example() {
    werror("\n=== SQLite Connection Example ===\n");

    // SQLite uses file path as database
    Sql.Sql sqlite = Sql.Sql("sqlite://test.db");

    // In-memory SQLite database
    Sql.Sql sqlite_memory = Sql.Sql("sqlite://:memory:");

    werror("SQLite database: %s\n", sqlite->server_info());
}

//! Example: Database manager usage
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
class ConnectionPool {
    private string db_url;
    private int max_connections;
    private array(Sql.Sql) connections;
    private Thread.Mutex lock = Thread.Mutex();

    //! Create a connection pool
    //! @param db_url - Database URL
    //! @param max_connections - Maximum number of connections
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

void connection_pool_example() {
    werror("\n=== Connection Pool Example ===\n");

    // Create a pool of 5 connections
    ConnectionPool pool = ConnectionPool("sqlite://pool.db", 5);

    // Get connections from pool
    Sql.Sql conn1 = pool->get_connection();
    Sql.Sql conn2 = pool->get_connection();

    werror("Got connection 1: %s\n", conn1->server_info());
    werror("Got connection 2: %s\n", conn2->server_info());

    pool->close();
}

int main(int argc, array(string) argv) {
    // Run examples
    postgresql_example();
    mysql_example();
    sqlite_example();
    database_manager_example();
    connection_pool_example();

    return 0;
}
