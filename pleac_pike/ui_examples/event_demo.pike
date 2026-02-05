#!/usr/bin/env pike
#pragma strict_types
// Recipe: Event-Driven Programming with Pike

// Event-driven timer example using call_out
class TimerDemo {
    int count = 0;

    void create() {
        // Add repeating timer using Pike's call_out
        call_out(tick, 1.0);
    }

    void tick() {
        count++;
        write(sprintf("Tick %d\n", count));

        if (count >= 5) {
            write("Stopping after 5 ticks\n");
        } else {
            // Reschedule
            call_out(tick, 1.0);
        }
    }
}

// Simple timeout example
class TimeoutExample {
    void create() {
        write("Starting 3-second countdown...\n");
        call_out(show_timeout, 3.0);
    }

    void show_timeout() {
        write("Timeout occurred after 3 seconds!\n");
    }
}

// Periodic task example
class PeriodicTask {
    int iterations = 0;

    void create() {
        write("Starting periodic task (every 0.5 seconds)...\n");
        call_out(perform_task, 0.5);
    }

    void perform_task() {
        iterations++;
        write(sprintf("Task iteration #%d\n", iterations));

        if (iterations < 10) {
            call_out(perform_task, 0.5);
        } else {
            write("Periodic task completed after 10 iterations\n");
        }
    }
}

int main(int argc, array(string) argv) {
    // Demonstrate timer-based event loop
    write("=== Timer Demo ===\n");
    TimerDemo timers = TimerDemo();

    // Wait for timers to complete
    sleep(6);

    write("\n=== Timeout Example ===\n");
    TimeoutExample timeout = TimeoutExample();
    sleep(4);

    write("\n=== Periodic Task Example ===\n");
    PeriodicTask periodic = PeriodicTask();
    sleep(6);

    write("\nAll demos completed!\n");
    return 0;
}
