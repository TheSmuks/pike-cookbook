---
id: sockets
title: Sockets
sidebar_label: Sockets
---

# 17. Sockets

## Introduction

```pike
//-----------------------------
//Pike doesn't normally use packed IP addresses. Strings such as "204.148.40.9" are used literally.
//
//-----------------------------
//DNS lookups can be done with gethostbyname() and gethostbyaddr()
[string host,array ip,array alias] = gethostbyname("www.example.com");
//ip[0] is a string "192.0.32.10"
//
//-----------------------------
```

## Writing a TCP Client

```pike
//-----------------------------
Stdio.File sock=Stdio.File();
if (!sock->connect(remote_host,remote_port)) //Connection failed. Error code is in sock->errno().
{
    werror("Couldn't connect to %s:%d: %s\n",remote_host,remote_port,strerror(sock->errno()));
    return 1;
}
sock->write("Hello, world!"); //Send something to the socket
string answer=sock->read(); //Read until the remote side disconnects. Use sock->read(1024,1) to read only some (up to 1KB here).
sock->close(); //Not necessary if the sock object goes out of scope here.
//
//-----------------------------
```

## Writing a TCP Server

```pike
//-----------------------------
Stdio.Port mainsock=Stdio.Port();
if (!mainsock->bind(server_port))
{
    werror("Couldn't be a tcp server on port %d: %s\n",server_port,strerror(mainsock->errno()));
    return 1;
}
while (1)
{
    Stdio.File sock=mainsock->accept();
    if (!sock) break;
    //sock is the new connection
    //if you don't do anything and just let sock expire, the client connection will be closed
}
//
//-----------------------------
```

## Communicating over TCP

```pike
//-----------------------------
sock->write("What is your name?\n");
string response=sock->read(1024,1); //Reads up to 1KB or whatever is available (minimum 1 byte).
//Buffered reads:
Stdio.FILE sock2=Stdio.FILE(); sock2->assign(sock);
string response=sock2->gets();
//
//-----------------------------
```

## Setting Up a UDP Client

```pike
//-----------------------------
// UDP Client (Pike 8)
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

    //Create UDP socket
    Stdio.UDP udp = Stdio.UDP();
    if (!udp) {
        werror("Failed to create UDP socket: %s\n", strerror(errno()));
        return 1;
    }

    //Send datagram
    udp->send(host, port, msg);
    write("Sent '%s' to %s:%d\n", msg, host, port);

    //Wait for response (with timeout)
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
//
//-----------------------------
```

## Setting Up a UDP Server

```pike
//-----------------------------
// UDP Server (Pike 8)
//-----------------------------
#pragma strict_types
#require constant(Stdio.UDP)

int main(int argc, array(string) argv)
{
    int port = argc > 1 ? (int)argv[1] : 8080;

    //Create and bind UDP socket
    Stdio.UDP udp = Stdio.UDP();
    if (!udp->bind(port)) {
        werror("Failed to bind to port %d: %s\n", port, strerror(udp->errno()));
        return 1;
    }

    write("UDP server listening on port %d\n", port);

    //Enable broadcast
    udp->set_option(Stdio.PORT_BROADCAST, 1);

    while (1) {
        //Read datagram
        mixed data = udp->read();
        if (!data) {
            werror("Read error: %s\n", strerror(udp->errno()));
            continue;
        }

        string msg = data[0];
        string from = data[1];
        write("Received '%s' from %s\n", msg, from);

        //Send echo response
        array addr = from / " ";
        udp->send(addr[0], (int)addr[1], "Echo: " + msg);
    }

    udp->close();
    return 0;
}
//
//-----------------------------
```

## Using UNIX Domain Sockets

```pike
//-----------------------------
// UNIX Domain Socket Client (Pike 8)
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
//
//-----------------------------
```

## UNIX Domain Socket Server

```pike
//-----------------------------
// UNIX Domain Socket Server (Pike 8)
//-----------------------------
#pragma strict_types
#require constant(Stdio.Port)

int main(int argc, array(string) argv)
{
    string socket_path = argc > 1 ? argv[1] : "/tmp/mysocket";

    //Remove old socket file if exists
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

    //Cleanup
    port->close();
    rm(socket_path);
    return 0;
}
//
//-----------------------------
```

## Identifying the Other End of a Socket

```pike
//-----------------------------
string other_end=sock->query_address(); //eg "10.1.1.1 123"
//
//-----------------------------
```

## Finding Your Own Name and Address

```pike
//-----------------------------
// Finding Your Own Address (Pike 8)
//-----------------------------
#pragma strict_types

//Get local address of a socket
string local_addr = sock->query_address(1);
write("Local address: %s\n", local_addr);

//Get hostname and local IP addresses
string hostname = gethostname();
write("Hostname: %s\n", hostname);

[string host, array ips, array aliases] = gethostbyname(hostname);
foreach(ips, string ip) {
    write("Local IP: %s\n", ip);
}
//
//-----------------------------
```

## SSL/TLS Sockets

```pike
//-----------------------------
// SSL/TLS Client (Pike 8)
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

    //Create SSL context
    SSL.Context ctx = SSL.Context();

    //Connect to server
    Stdio.File sock = Stdio.File();
    if (!sock->connect(host, port)) {
        werror("Connection failed: %s\n", strerror(sock->errno()));
        return 1;
    }

    //Create SSL connection
    SSL.File ssl = SSL.File(sock, ctx);
    int result = ssl->connect();
    if (result < 0) {
        werror("SSL handshake failed\n");
        return 1;
    }

    //Send HTTPS request
    ssl->write("GET / HTTP/1.0\r\nHost: " + host + "\r\n\r\n");

    //Read response
    string response = ssl->read();
    write("%s\n", response);

    ssl->close();
    return 0;
}
//
//-----------------------------
```

## SSL/TLS Server

```pike
//-----------------------------
// SSL/TLS Server (Pike 8)
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

    //Create SSL context with certificates
    SSL.Context ctx = SSL.Context();
    if (file_stat(cert_file)) {
        ctx->certificates = (([{
            "cert_file": cert_file,
            "key_file": key_file
        }]));
    }

    //Create SSL port
    SSL.Port ssl_port = SSL.Port(ctx);
    if (!ssl_port->bind(port, handle_ssl_client)) {
        werror("Failed to bind SSL port: %s\n", strerror(ssl_port->errno()));
        return 1;
    }

    write("SSL server listening on port %d\n", port);

    //Keep server running
    while (1) {
        sleep(1);
    }

    return 0;
}
//
//-----------------------------
```

## Closing a Socket After Forking

```pike
//-----------------------------
sock->close("r");   //Close the read direction
sock->close("w");   //Close the write direction
sock->close("rw");  //Shut down both directions
sock->close();      //Close completely
//
//-----------------------------
```

## Writing Bidirectional Clients

```pike
//-----------------------------
// Bidirectional Client (Pike 8)
//-----------------------------
#pragma strict_types
#require constant(Stdio.File)

void read_from_server(Stdio.File sock)
{
    while (1) {
        string data = sock->read(1024, 1);
        if (!data || !sizeof(data)) break;
        write("Server: %s\n", data);
    }
    sock->close("r");
}

int main(int argc, array(string) argv)
{
    if (argc < 3) {
        werror("Usage: %s host port\n", argv[0]);
        return 1;
    }

    Stdio.File sock = Stdio.File();
    if (!sock->connect(argv[1], (int)argv[2])) {
        werror("Connection failed\n");
        return 1;
    }

    //Start thread to read from server
    Thread.Thread create_thread = Thread.Thread(read_from_server, sock);

    //Read from stdin and send to server
    while (string line = Stdio.stdin->gets()) {
        sock->write(line + "\n");
    }

    sock->close("w");
    create_thread->wait();
    return 0;
}
//
//-----------------------------
```

## Non-Blocking I/O with select()

```pike
//-----------------------------
// Non-blocking I/O with select() (Pike 8)
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
        //Build read set
        array read_fds = clients + (({listen_sock}));

        //Wait for activity
        mixed ready = Stdio.select(read_fds);
        if (!ready || !sizeof(ready[0])) continue;

        //Check for new connections
        if (has_value(ready[0], listen_sock)) {
            Stdio.File new_client = listen_sock->accept();
            if (new_client) {
                clients += (({new_client}));
                write("New client: %s\n", new_client->query_address());
            }
        }

        //Check clients for data
        foreach(clients, int i, Stdio.File client) {
            if (has_value(ready[0], client)) {
                string data = client->read(1024, 1);
                if (!data || !sizeof(data)) {
                    //Client disconnected
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
//
//-----------------------------
```

## Forking Servers

```pike
//-----------------------------

//Forking is generally unnecessary in Pike, as the driver works more efficiently with other models.
//
//-----------------------------
```

## Socket Options and Configuration

```pike
//-----------------------------
// Socket Options and Configuration (Pike 8)
//-----------------------------
#pragma strict_types

//Creating a socket with options
Stdio.Port port = Stdio.Port();

//Set SO_REUSEADDR to allow quick restart
port->set_option(Stdio.PORT_REUSE_ADDRESS, 1);

//Set SO_KEEPALIVE for connection monitoring
Stdio.File sock = Stdio.File();
sock->set_option(Stdio.KEEPALIVE, 1);

//Set TCP_NODELAY to disable Nagle's algorithm (for real-time apps)
sock->set_option(Stdio.NO_DELAY, 1);

//Set socket buffer sizes
sock->set_buffer(65536, 65536); //read_buf, write_buf

//Set socket timeout
sock->set_nonblocking(1, 0, 0); //nonblocking mode

//Enable broadcast for UDP
Stdio.UDP udp = Stdio.UDP();
udp->set_option(Stdio.PORT_BROADCAST, 1);
udp->set_option(Stdio.MULTICAST, 1);

//Bind to specific interface
port->bind(8080, 0, "127.0.0.1");

//
//-----------------------------
```

## Modern Async with Concurrent.Future

```pike
//-----------------------------
// Modern async socket I/O with Concurrent.Future (Pike 8)
//-----------------------------
#pragma strict_types
#require constant(Concurrent.Future)
#require constant(Stdio.File)

//Async HTTP GET using Future
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
    //Use the future
    Concurrent.Future f = async_http_get("example.com", 80);

    f->on_success(lambda(string response) {
        write("Got response of %d bytes\n", sizeof(response));
    });

    f->on_failure(lambda(mapping err) {
        werror("Request failed: %s\n", err->error);
    });

    //Wait for completion
    mixed result = f->wait();
    return 0;
}
//
//-----------------------------
```

## Pre-Forking Servers

```pike
//-----------------------------
// Connection Pool (Pike 8)
//-----------------------------
#pragma strict_types
#require constant(Stdio.File)
#require constant(Thread.Mutex)

class ConnectionPool {
    private string host;
    private int port;
    private array(Stdio.File) connections = (({}));
    private int max_size;
    private Thread.Mutex lock = Thread.Mutex();

    void create(string _host, int _port, int _max_size)
    {
        host = _host;
        port = _port;
        max_size = _max_size;
    }

    Stdio.File acquire()
    {
        mixed key = lock->lock();
        Stdio.File sock;

        if (sizeof(connections)) {
            sock = connections[0];
            connections = connections[1..];
        } else {
            sock = Stdio.File();
            if (!sock->connect(host, port)) {
                lock->unlock();
                return 0;
            }
        }

        lock->unlock();
        return sock;
    }

    void release(Stdio.File sock)
    {
        mixed key = lock->lock();

        if (sizeof(connections) < max_size) {
            connections += (({sock}));
        } else {
            sock->close();
        }

        lock->unlock();
    }
}
//
//-----------------------------
```

## Non-Forking Servers

```pike
//-----------------------------

//Incomplete. There's multiple ways to do this, including:
//1) Threaded server (works like forking but clients can share global state if desired)
//2) Multiplexing using select()
//3) Callback mode (puts the sockets under the control of a Backend which uses select())
//
//-----------------------------
```

## Writing a Multi-Homed Server

```pike
//-----------------------------
Stdio.Port mainsock=Stdio.Port();
if (!mainsock->bind(server_port))
{
    werror("Couldn't be a tcp server on port %d: %s\n",server_port,strerror(mainsock->errno()));
    return 1;
}
while (1)
{
    Stdio.File sock=mainsock->accept();
    if (!sock) break;
    string localaddr=sock->query_address(1); //Is the IP address and port connected to.
    //The IP will be that of one of your interfaces, and the port should be equal to server_port
}
//
//-----------------------------
```

## Making a Daemon Server

```pike
//-----------------------------
if (!System.chroot("/var/daemon")) werror("Unable to chroot to /var/daemon: %s\n",strerror(errno()));
//Incomplete (I don't fork in Pike). See predef::fork() and Process.create_process() for details.
//
//-----------------------------
```

## Restarting a Server on Demand

```pike
//-----------------------------
//The best way to restart the server is to adopt a microkernel concept and restart only the parts of
//the server that need updating. However, if you must reload, see Process.exec()
//
//-----------------------------
```

## Program: backsniff

```pike
//-----------------------------
// backsniff - Simple port scanner detector (Pike 8)
//-----------------------------
#pragma strict_types
#require constant(Stdio.Port)

int main(int argc, array(string) argv)
{
    int port = argc > 1 ? (int)argv[1] : 8080;

    Stdio.Port listen = Stdio.Port();
    if (!listen->bind(port)) {
        werror("Bind failed\n");
        return 1;
    }

    write("backsniff listening on port %d\n", port);

    while (1) {
        Stdio.File sock = listen->accept();
        if (!sock) continue;

        string remote = sock->query_address();
        write("Connection from: %s at %s\n", remote, ctime(time()));

        //Log and close
        sock->close();
    }

    return 0;
}
//
//-----------------------------
```

## Program: fwdport

```pike
//-----------------------------
// fwdport - TCP port forwarder (Pike 8)
//-----------------------------
#pragma strict_types
#require constant(Stdio.Port)
#require constant(Stdio.File)

void forward_data(Stdio.File client, Stdio.File target)
{
    string data = client->read(8192, 1);
    while (data && sizeof(data)) {
        target->write(data);
        data = client->read(8192, 1);
    }
    target->close("w");
}

void handle_client(Stdio.File client, string target_host, int target_port)
{
    Stdio.File target = Stdio.File();
    if (!target->connect(target_host, target_port)) {
        werror("Failed to connect to target\n");
        client->close();
        return;
    }

    //Create threads for bidirectional forwarding
    Thread.Thread t1 = Thread.Thread(forward_data, client, target);
    ;
    Thread.Thread t2 = Thread.Thread(forward_data, target, client);
    ;

    t1->wait();
    t2->wait();

    client->close();
    target->close();
}

int main(int argc, array(string) argv)
{
    if (argc < 4) {
        werror("Usage: %s listen_port target_host target_port\n", argv[0]);
        return 1;
    }

    int listen_port = (int)argv[1];
    string target_host = argv[2];
    int target_port = (int)argv[3];

    Stdio.Port listen = Stdio.Port();
    if (!listen->bind(listen_port)) {
        werror("Bind failed on port %d\n", listen_port);
        return 1;
    }

    write("Forwarding %d -> %s:%d\n", listen_port, target_host, target_port);

    while (1) {
        Stdio.File client = listen->accept();
        if (!client) continue;

        //Handle client in thread
        Thread.Thread(handle_client, client, target_host, target_port);
    }

    return 0;
}
//
//-----------------------------
```