#!/usr/bin/env pike
#pragma strict_types
// Retry strategies for unreliable network conditions

class RetryConfig
{
    int max_retries;
    float base_delay;
    float max_delay;
    int backoff_multiplier;

    void create(int|void max_ret, float|void base_d, float|void max_d, int|void mult)
    {
        max_retries = max_ret || 3;
        base_delay = base_d || 1.0;
        max_delay = max_d || 60.0;
        backoff_multiplier = mult || 2;
    }
}

class RetryStrategy
{
    private RetryConfig config;

    void create(RetryConfig|void cfg)
    {
        config = cfg || RetryConfig();
    }

    // Execute with exponential backoff retry
    mixed retry(function f, array|void args, int|void max_retries)
    {
        max_retries = max_retries || config->max_retries;
        int attempt = 0;
        float delay = config->base_delay;

        while (attempt < max_retries) {
            mixed result = f(@(args || ({})));

            // Check if successful (no error thrown)
            if (result) {
                return result;
            }

            attempt++;
            if (attempt >= max_retries) {
                break;
            }

            // Calculate delay with exponential backoff
            float sleep_time = min(delay, config->max_delay);
            write("Attempt %d failed, retrying in %.1f seconds...\n",
                  attempt + 1, sleep_time);
            sleep((int)(sleep_time * 1000));

            // Increase delay for next attempt
            delay = delay * config->backoff_multiplier;
        }

        return 0;  // All retries failed
    }

    // HTTP request with retry
    Protocols.HTTP.Query http_request(string method, string url,
                                       mapping|void headers,
                                       mapping|void data)
    {
        mixed result = retry(lambda() {
            Protocols.HTTP.Query q;

            if (method == "GET") {
                mapping(string:string) get_headers = (mapping(string:string))(headers || ([]));
                q = Protocols.HTTP.get_url(url, get_headers);
            } else if (method == "POST") {
                mapping(string:string|array(string)) post_headers = (mapping(string:string|array(string)))(headers || ([]));
                mixed content_type = post_headers["Content-Type"];
                if (stringp(content_type) && ((string)content_type) == "application/json") {
                    string body = Standards.JSON.encode(data);
                    q = Protocols.HTTP.do_method("POST", url, ([]), post_headers, 0, body);
                } else {
                    // Build form data mapping
                    mapping(string:array(string)|string) post_data = ([]);
                    if (data && mappingp(data)) {
                        mapping data_map = (mapping)data;
                        foreach(data_map; mixed k; mixed v) {
                            if (stringp(k) && stringp(v)) {
                                post_data[(string)k] = (string)v;
                            } else if (stringp(k) && intp(v)) {
                                post_data[(string)k] = (string)(int)v;
                            }
                        }
                    }
                    q = Protocols.HTTP.post_url(url, post_data, (mapping(string:array(string)|string))post_headers);
                }
            }

            // Retry on server errors (5xx) and network errors
            if (q && q->status >= 500) {
                return;  // Will trigger retry by returning undefined
            }

            return q;
        });

        if (objectp(result)) {
            return [object(Protocols.HTTP.Query)]result;
        }
        return 0;
    }
}

int main()
{
    write("=== Retry Strategy Example ===\n\n");

    RetryStrategy retry = RetryStrategy();

    // Example 1: Retry flaky function
    write("Example 1: Retrying flaky operation\n");

    int attempt_count = 0;
    function flaky_operation = lambda() {
        attempt_count++;
        write("  Attempt %d...\n", attempt_count);

        if (attempt_count < 3) {
            return 0;  // Fail first 2 times
        }
        return "success!";
    };

    mixed result = retry->retry(flaky_operation);
    string result_str = stringp(result) ? (string)result : "failed after all retries";
    write("  Result: %s\n\n", result_str);

    // Example 2: HTTP request with retry
    write("Example 2: HTTP request with retry\n");

    // Use a URL that might rate limit or fail intermittently
    string url = "https://httpbin.org/status/500";  // Always returns 500

    Protocols.HTTP.Query q = retry->http_request("GET", url);

    if (q && q->status < 500) {
        write("  Success: %d\n", q->status);
    } else {
        write("  Failed after all retries (expected for 500 error)\n");
    }

    // Example 3: Working URL
    write("\nExample 3: Successful request\n");

    url = "https://httpbin.org/get";
    q = retry->http_request("GET", url);

    if (q) {
        write("  Success: %d\n", q->status);
        if (q->status == 200) {
            write("  Data received: %d bytes\n", sizeof(q->data()));
        }
    }

    // Example 4: Custom retry configuration
    write("\nExample 4: Aggressive retry strategy\n");

    RetryConfig aggressive = RetryConfig(10, 0.5, 10.0, 1);

    write("  Max retries: %d\n", aggressive->max_retries);
    write("  Base delay: %.1fs\n", aggressive->base_delay);
    write("  Max delay: %.1fs\n", aggressive->max_delay);
    write("  Multiplier: %d\n", aggressive->backoff_multiplier);

    return 0;
}
