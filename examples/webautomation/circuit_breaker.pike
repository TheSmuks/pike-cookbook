#!/usr/bin/env pike
#pragma strict_types
// Circuit breaker pattern for failing services

class CircuitBreaker
{
    enum State { CLOSED, OPEN, HALF_OPEN };

    private State state = State::CLOSED;
    private int failure_count = 0;
    private int failure_threshold = 5;
    private int success_count = 0;
    private int success_threshold = 2;
    private float timeout = 60.0;  // Seconds to stay open
    private float last_failure_time = 0;
    private string service_name;

    void create(string name, int|void fail_threshold, int|void succ_threshold, float|void tout)
    {
        service_name = name;
        failure_threshold = fail_threshold || 5;
        success_threshold = succ_threshold || 2;
        timeout = tout || 60.0;
    }

    // Execute operation through circuit breaker
    mixed execute(function operation)
    {
        // Check if circuit should transition to half-open
        if (state == State::OPEN) {
            float elapsed = time() - last_failure_time;
            if (elapsed >= timeout) {
                write("[%s] Circuit breaker transitioning to HALF_OPEN\n", service_name);
                state = State::HALF_OPEN;
                success_count = 0;
            } else {
                werror("[%s] Circuit breaker OPEN - rejecting request (%.1fs remaining)\n",
                      service_name, timeout - elapsed);
                return 0;  // Circuit is open
            }
        }

        // Execute operation
        mixed result = operation();

        if (result) {
            on_success();
        } else {
            on_failure();
        }

        return result;
    }

    // Handle success
    void on_success()
    {
        if (state == State::HALF_OPEN) {
            success_count++;
            write("[%s] Success in HALF_OPEN (%d/%d)\n",
                  service_name, success_count, success_threshold);

            if (success_count >= success_threshold) {
                write("[%s] Circuit breaker closing\n", service_name);
                state = State::CLOSED;
                failure_count = 0;
            }
        } else if (state == State::CLOSED) {
            // Reset failure count on success
            failure_count = max(0, failure_count - 1);
        }
    }

    // Handle failure
    void on_failure()
    {
        failure_count++;
        last_failure_time = time();

        write("[%s] Failure recorded (%d/%d)\n",
              service_name, failure_count, failure_threshold);

        if (failure_count >= failure_threshold) {
            if (state != State::OPEN) {
                write("[%s] Circuit breaker opening after %d failures\n",
                      service_name, failure_count);
            }
            state = State::OPEN;
        }
    }

    // Get current state
    State get_state()
    {
        return state;
    }

    // Get state name as string
    string get_state_name()
    {
        switch(state) {
            case State::CLOSED: return "CLOSED";
            case State::OPEN: return "OPEN";
            case State::HALF_OPEN: return "HALF_OPEN";
        }
    }

    // Reset circuit breaker
    void reset()
    {
        state = State::CLOSED;
        failure_count = 0;
        success_count = 0;
        write("[%s] Circuit breaker reset\n", service_name);
    }
}

int main()
{
    write("=== Circuit Breaker Pattern ===\n\n");

    // Create circuit breaker for unreliable service
    CircuitBreaker breaker = CircuitBreaker("API-Service", 3, 2, 10.0);

    write("Circuit breaker configuration:\n");
    write("  Failure threshold: 3\n");
    write("  Success threshold: 2\n");
    write("  Timeout: 10 seconds\n\n");

    // Simulate operation
    int fail_count = 0;
    function unreliable_operation = lambda() {
        fail_count++;

        // Fail first 5 times, then succeed
        if (fail_count <= 5) {
            write("  Operation failed (%d)\n", fail_count);
            return 0;
        }

        write("  Operation succeeded (%d)\n", fail_count);
        return "success";
    };

    // Execute operations through circuit breaker
    write("Executing operations:\n");
    write("---\n");

    for (int i = 1; i <= 10; i++) {
        write("\nAttempt %d (State: %s)\n", i, breaker->get_state_name());

        mixed result = breaker->execute(unreliable_operation);

        if (result) {
            write("  ✓ Result: %s\n", result);
        } else {
            write("  ✗ Circuit blocked or operation failed\n");
        }
    }

    write("\n---\n");
    write("Final state: %s\n", breaker->get_state_name());
    write("Total failures: %d\n", fail_count);

    return 0;
}
