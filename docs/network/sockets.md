---
id: sockets
title: Sockets
sidebar_label: Sockets
---

# Sockets

## Introduction

Socket programming enables network communication between applications. Pike 8 provides comprehensive support for TCP, UDP, UNIX domain sockets, and SSL/TLS through the `Stdio.Port`, `Stdio.File`, and `SSL` modules.

**What this covers:**
- TCP/UDP client and server programming
- UNIX domain sockets for local IPC
- SSL/TLS secure communication
- Non-blocking I/O and async operations
- Socket options and configuration

**Why use it:**
- Build networked applications and services
- Implement custom protocols
- Create real-time communication systems
- Develop client-server architectures

:::tip
Pike's socket API provides both synchronous and asynchronous modes, making it easy to choose the right approach for your application.
:::

---

## Writing a TCP Client

### Basic TCP Connection

```pike
//-----------------------------
// Recipe: Connect to TCP server
//-----------------------------

Stdio.File sock = Stdio.File();
string remote_host = "example.com";
int remote_port = 80;

if (!sock->connect(remote_host, remote_port)) {
    werror("Couldn't connect to %s:%d: %s\n",
          remote_host, remote_port, strerror(sock->errno()));
    exit(1);
}

// Send request
sock->write("GET / HTTP/1.0\r\nHost: " + remote_host + "\r\n\r\n");

// Read response
string answer = sock->read();
write("Received %d bytes\n", sizeof(answer));

sock->close();
```

---

## Writing a TCP Server

### Basic TCP Server

```pike
//-----------------------------
// Recipe: Create TCP server
//-----------------------------

int server_port = 8080;
Stdio.Port mainsock = Stdio.Port();

if (!mainsock->bind(server_port)) {
    werror("Couldn't be a tcp server on port %d: %s\n",
          server_port, strerror(mainsock->errno()));
    exit(1);
}

write("Server listening on port %d\n", server_port);

while (1) {
    Stdio.File sock = mainsock->accept();
    if (!sock) break;

    // Handle connection
    string data = sock->read(1024, 1);
    if (data) {
        write("Received: %s\n", data);
        sock->write("Acknowledged\n");
    }

    sock->close();
}
```

:::tip
Set `Stdio.PORT_REUSE_ADDRESS` option to allow quick server restarts.
:::

---

## Communicating over TCP

### Bidirectional Communication

```pike
//-----------------------------
// Recipe: Send and receive data
//-----------------------------

Stdio.File sock = Stdio.File();
if (!sock->connect("example.com", 80)) {
    werror("Connection failed\n");
    exit(1);
}

// Send data
sock->write("What is your name?\n");

// Read response (up to 1KB or whatever is available)
string response = sock->read(1024, 1);
write("Response: %s\n", response);

// Buffered reads with Stdio.FILE
Stdio.FILE sock2 = Stdio.FILE();
sock2->assign(sock);
response = sock2->gets();
write("Line: %s\n", response);

sock->close();
```

---

## Setting Up a UDP Client

### UDP Communication

```pike
//-----------------------------
// Recipe: UDP Client (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(Stdio.UDP)

int main(int argc, array(string) argv)
{
    if (argc < 3) {
        werror("Usage: %s host port [message]\n", argv[0]);
        return 1;
    }

    string host = argv[1];
    int port = (int)argv[2];
    string msg = argc > 3 ? argv[3] : "Hello, UDP!";

    // Create UDP socket
    Stdio.UDP udp = Stdio.UDP();
    if (!udp) {
        werror("Failed to create UDP socket: %s\n", strerror(errno()));
        return 1;
    }

    // Send datagram
    udp->send(host, port, msg);
    write("Sent '%s' to %s:%d\n", msg, host, port);

    // Wait for response (with timeout)
    mixed response = udp->read(1024, ".", 5.0);
    if (response) {
        string data = response[0];
        string from = response[1];
        write("Received '%s' from %s\n", data, from);
    } else {
        write("No response (timeout)\n");
    }

    udp->close();
    return 0;
}
```

---

## Setting Up a UDP Server

### UDP Server Implementation

```pike
//-----------------------------
// Recipe: UDP Server (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(Stdio.UDP)

int main(int argc, array(string) argv)
{
    int port = argc > 1 ? (int)argv[1] : 8080;

    // Create and bind UDP socket
    Stdio.UDP udp = Stdio.UDP();
    if (!udp->bind(port)) {
        werror("Failed to bind to port %d: %s\n", port, strerror(udp->errno()));
        return 1;
    }

    write("UDP server listening on port %d\n", port);

    // Enable broadcast
    udp->set_option(Stdio.PORT_BROADCAST, 1);

    while (1) {
        // Read datagram
        mixed data = udp->read();
        if (!data) {
            werror("Read error: %s\n", strerror(udp->errno()));
            continue;
        }

        string msg = data[0];
        string from = data[1];
        write("Received '%s' from %s\n", msg, from);

        // Send echo response
        array addr = from / " ";
        udp->send(addr[0], (int)addr[1], "Echo: " + msg);
    }

    udp->close();
    return 0;
}
```

---

## Using UNIX Domain Sockets

### UNIX Domain Socket Client

```pike
//-----------------------------
// Recipe: UNIX Domain Socket Client (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(Stdio.File)

int main(int argc, array(string) argv)
{
    string socket_path = argc > 1 ? argv[1] : "/tmp/mysocket";

    Stdio.File sock = Stdio.File();
    if (!sock->connect(socket_path)) {
        werror("Couldn't connect to %s: %s\n",
              socket_path, strerror(sock->errno()));
        return 1;
    }

    sock->write("Hello via UNIX socket!\n");
    string response = sock->read();
    write("Server response: %s\n", response);

    sock->close();
    return 0;
}
```

---

## UNIX Domain Socket Server

### UNIX Socket Server

```pike
//-----------------------------
// Recipe: UNIX Domain Socket Server (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(Stdio.Port)

int main(int argc, array(string) argv)
{
    string socket_path = argc > 1 ? argv[1] : "/tmp/mysocket";

    // Remove old socket file if exists
    if (file_stat(socket_path)) {
        rm(socket_path);
    }

    Stdio.Port port = Stdio.Port();
    if (!port->bind(socket_path)) {
        werror("Couldn't bind to %s: %s\n",
              socket_path, strerror(port->errno()));
        return 1;
    }

    write("UNIX domain socket server listening on %s\n", socket_path);

    while (1) {
        Stdio.File sock = port->accept();
        if (!sock) continue;

        string data = sock->read(1024, 1);
        if (data) {
            write("Received: %s\n", data);
            sock->write("Acknowledged\n");
        }
        sock->close();
    }

    // Cleanup
    port->close();
    rm(socket_path);
    return 0;
}
```

---

## SSL/TLS Sockets

### SSL Client

```pike
//-----------------------------
// Recipe: SSL/TLS Client (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(SSL.File)
#require constant(SSL.Context)

int main(int argc, array(string) argv)
{
    if (argc < 3) {
        werror("Usage: %s host port\n", argv[0]);
        return 1;
    }

    string host = argv[1];
    int port = (int)argv[2];

    // Create SSL context
    SSL.Context ctx = SSL.Context();

    // Connect to server
    Stdio.File sock = Stdio.File();
    if (!sock->connect(host, port)) {
        werror("Connection failed: %s\n", strerror(sock->errno()));
        return 1;
    }

    // Create SSL connection
    SSL.File ssl = SSL.File(sock, ctx);
    int result = ssl->connect();
    if (result < 0) {
        werror("SSL handshake failed\n");
        return 1;
    }

    // Send HTTPS request
    ssl->write("GET / HTTP/1.0\r\nHost: " + host + "\r\n\r\n");

    // Read response
    string response = ssl->read();
    write("%s\n", response);

    ssl->close();
    return 0;
}
```

---

## SSL/TLS Server

### SSL Server Implementation

```pike
//-----------------------------
// Recipe: SSL/TLS Server (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(SSL.Port)
#require constant(SSL.Context)

void handle_ssl_client(SSL.File ssl)
{
    string data = ssl->read(4096, 1);
    if (data) {
        write("Received: %s\n", data);
        ssl->write("HTTP/1.0 200 OK\r\n\r\nSSL Connection Successful!\n");
    }
    ssl->close();
}

int main(int argc, array(string) argv)
{
    int port = argc > 1 ? (int)argv[1] : 8443;
    string cert_file = "server.pem";
    string key_file = "server.key";

    // Create SSL context with certificates
    SSL.Context ctx = SSL.Context();
    if (file_stat(cert_file)) {
        ctx->certificates = (([{
            "cert_file": cert_file,
            "key_file": key_file
        }]));
    }

    // Create SSL port
    SSL.Port ssl_port = SSL.Port(ctx);
    if (!ssl_port->bind(port, handle_ssl_client)) {
        werror("Failed to bind SSL port: %s\n", strerror(ssl_port->errno()));
        return 1;
    }

    write("SSL server listening on port %d\n", port);

    // Keep server running
    while (1) {
        sleep(1);
    }

    return 0;
}
```

:::warning
Always use proper SSL certificates in production. Self-signed certificates are only for testing.
:::

---

## Identifying the Other End of a Socket

### Get Peer Address

```pike
//-----------------------------
// Recipe: Get remote socket address
//-----------------------------

Stdio.File sock = Stdio.File();
if (sock->connect("example.com", 80)) {
    // Get remote address
    string other_end = sock->query_address();
    write("Connected to: %s\n", other_end);

    sock->close();
}
```

---

## Finding Your Own Name and Address

### Local Address Information

```pike
//-----------------------------
// Recipe: Get local address (Pike 8)
//-----------------------------

#pragma strict_types

// Get local address of a socket
string local_addr = sock->query_address(1);
write("Local address: %s\n", local_addr);

// Get hostname and local IP addresses
string hostname = gethostname();
write("Hostname: %s\n", hostname);

[string host, array ips, array aliases] = gethostbyname(hostname);
foreach(ips; string ip) {
    write("Local IP: %s\n", ip);
}
```

---

## Non-Blocking I/O with select()

### Multiplexed Server

```pike
//-----------------------------
// Recipe: Non-blocking I/O with select() (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(Stdio.File)

int main(int argc, array(string) argv)
{
    int port = argc > 1 ? (int)argv[1] : 8080;

    Stdio.Port listen_sock = Stdio.Port();
    if (!listen_sock->bind(port)) {
        werror("Bind failed: %s\n", strerror(listen_sock->errno()));
        return 1;
    }

    array(Stdio.File) clients = (({}));
    write("Multiplexed server on port %d\n", port);

    while (1) {
        // Build read set
        array read_fds = clients + (({listen_sock}));

        // Wait for activity
        mixed ready = Stdio.select(read_fds);
        if (!ready || !sizeof(ready[0])) continue;

        // Check for new connections
        if (has_value(ready[0], listen_sock)) {
            Stdio.File new_client = listen_sock->accept();
            if (new_client) {
                clients += (({new_client}));
                write("New client: %s\n", new_client->query_address());
            }
        }

        // Check clients for data
        foreach(clients, int i, Stdio.File client) {
            if (has_value(ready[0], client)) {
                string data = client->read(1024, 1);
                if (!data || !sizeof(data)) {
                    // Client disconnected
                    write("Client disconnected\n");
                    client->close();
                    clients = clients[..i-1] + clients[i+1..];
                } else {
                    write("Received: %s\n", data);
                    client->write("Echo: " + data);
                }
            }
        }
    }

    return 0;
}
```

---

## Modern Async with Concurrent.Future

### Async Socket I/O

```pike
//-----------------------------
// Recipe: Modern async socket I/O with Concurrent.Future (Pike 8)
//-----------------------------

#pragma strict_types
#require constant(Concurrent.Future)
#require constant(Stdio.File)

// Async HTTP GET using Future
Concurrent.Future async_http_get(string host, int port)
{
    Concurrent.Promise result = Concurrent.Promise();

    thread_create(lambda() {
        Stdio.File sock = Stdio.File();
        if (!sock->connect(host, port)) {
            result->failure(([{"error": "Connection failed"}]));
            return;
        }

        sock->write("GET / HTTP/1.0\r\nHost: " + host + "\r\n\r\n");
        string response = sock->read();
        sock->close();

        result->success(response);
    });

    return result->future();
}

int main()
{
    // Use the future
    Concurrent.Future f = async_http_get("example.com", 80);

    f->on_success(lambda(string response) {
        write("Got response of %d bytes\n", sizeof(response));
    });

    f->on_failure(lambda(mapping err) {
        werror("Request failed: %s\n", err->error);
    });

    // Wait for completion
    mixed result = f->wait();
    return 0;
}
```

---

## Socket Options and Configuration

### Socket Options

```pike
//-----------------------------
// Recipe: Socket options and configuration (Pike 8)
//-----------------------------

#pragma strict_types

// Creating a socket with options
Stdio.Port port = Stdio.Port();

// Set SO_REUSEADDR to allow quick restart
port->set_option(Stdio.PORT_REUSE_ADDRESS, 1);

// Set SO_KEEPALIVE for connection monitoring
Stdio.File sock = Stdio.File();
sock->set_option(Stdio.KEEPALIVE, 1);

// Set TCP_NODELAY to disable Nagle's algorithm (for real-time apps)
sock->set_option(Stdio.NO_DELAY, 1);

// Set socket buffer sizes
sock->set_buffer(65536, 65536); // read_buf, write_buf

// Set socket timeout
sock->set_nonblocking(1, 0, 0); // nonblocking mode

// Enable broadcast for UDP
Stdio.UDP udp = Stdio.UDP();
udp->set_option(Stdio.PORT_BROADCAST, 1);
udp->set_option(Stdio.MULTICAST, 1);

// Bind to specific interface
port->bind(8080, 0, "127.0.0.1");
```

---

## See Also

- [Web Automation](/docs/network/web-automation) - HTTP clients and web scraping
- [CGI Programming](/docs/network/cgi-programming) - Web scripting
- [Internet Services](/docs/network/internet-services) - Email, FTP, DNS
- [Process Management](/docs/advanced/processes) - Inter-process communication
