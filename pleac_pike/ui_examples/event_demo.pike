#!/usr/bin/env pike
#pragma strict_types
// Recipe: Event-Driven Programming with Pike

// Event-driven architecture using Pike's backend
class EventLoop {
    mapping handlers = ([]);
    int running = 0;

    // Add a timer event
    int add_timer(float delay, function callback) {
        return Pike.Backend()->call_out(callback, delay);
    }

    // Remove timer
    void remove_timer(int id) {
        Pike.Backend()->remove_call_out(id);
    }

    // Monitor file descriptor for events
    void add_io(Stdio.File file, function callback, int|void events) {
        int ev = events || Pike.POLLIN;
        file->set_callback(callback);
        file->set_nonblocking(1, 0, ev);
    }

    // Run the event loop
    void run() {
        running = 1;
        while (running) {
            Pike.Backend()->wait(1.0);  // Wait up to 1 second
        }
    }

    // Stop the event loop
    void stop() {
        running = 0;
    }
}

// Simple event-driven application
class ChatClient {
    inherit EventLoop;

    Stdio.File socket;
    string buffer = "";

    void create(string host, int port) {
        // Connect to server
        socket = Stdio.File();
        if (!socket->connect(host, port)) {
            write("Failed to connect to %s:%d\n", host, port);
            return;
        }

        // Set up I/O callback
        add_io(socket, receive_data);

        // Add keepalive timer
        add_timer(30.0, keepalive);

        write("Connected to %s:%d\n", host, port);
    }

    void receive_data(mixed id, string data) {
        buffer += data;

        // Process complete lines
        while (has_value(buffer, "\n")) {
            array(string) parts = buffer / "\n";
            string line = parts[0];
            buffer = parts[1..] * "\n";

            handle_message(line);
        }
    }

    void handle_message(string line) {
        write("Received: %s\n", line);

        // Handle special commands
        if (line == "PING") {
            send("PONG");
        } else if (sscanf(line, "MSG %s", string msg)) {
            // Display message
            write("\rMessage: %-50s\n> ", msg);
        }
    }

    void send(string data) {
        socket->write(data + "\n");
    }

    void keepalive() {
        send("PING");
        // Reschedule
        add_timer(30.0, keepalive);
    }
}

// Event-driven timer example
class TimerDemo {
    inherit EventLoop;

    int count = 0;
    int timer_id;

    void create() {
        // Add repeating timer
        timer_id = add_timer(1.0, tick);
    }

    void tick() {
        count++;
        write("Tick %d\n", count);

        if (count >= 5) {
            write("Stopping after 5 ticks\n");
            stop();
        } else {
            // Reschedule
            add_timer(1.0, tick);
        }
    }
}

// Async file operations
class AsyncFileProcessor {
    inherit EventLoop;

    void process_file(string path, function callback) {
        Stdio.File file = Stdio.File(path, "r");

        if (!file) {
            write("Failed to open file: %s\n", path);
            return;
        }

        string content = "";
        int total = file->stat()->size;
        int received = 0;

        // Async read callback
        void read_callback(mixed id, string data) {
            if (!data || sizeof(data) == 0) {
                // EOF
                callback(content);
                return;
            }

            content += data;
            received += sizeof(data);
            write("\rProgress: %d/%d bytes (%.1f%%)",
                  received, total,
                  (100.0 * received) / total);

            // Continue reading
            file->set_nonblocking(read_callback, 0, 0);
        }

        file->set_nonblocking(read_callback, 0, 0);
    }
}

int main(int argc, array(string) argv) {
    // Demonstrate timer-based event loop
    write("=== Timer Demo ===\n");
    TimerDemo timers = TimerDemo();
    timers->run();

    write("\n=== Async File Processing Demo ===\n");
    if (argc > 1) {
        AsyncFileProcessor processor = AsyncFileProcessor();

        processor->process_file(argv[1], lambda(string content) {
            write("\nFile processed, size: %d bytes\n", sizeof(content));
            processor->stop();
        });

        processor->run();
    } else {
        write("Usage: %s <filename>\n", argv[0]);
    }

    return 0;
}
