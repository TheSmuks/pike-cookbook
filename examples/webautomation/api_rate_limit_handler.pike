#!/usr/bin/env pike
#pragma strict_types
// Rate limiting for API requests

class RateLimiter
{
    private int requests_per_second;
    private int last_request_time = 0;
    private float min_interval;

    void create(int rps)
    {
        requests_per_second = rps;
        min_interval = 1.0 / rps;
    }

    // Wait if necessary to maintain rate limit
    void throttle()
    {
        int current_time = time();
        float elapsed = current_time - last_request_time;

        if (elapsed < min_interval) {
            float sleep_time = min_interval - elapsed;
            write("Rate limit: sleeping %.2f seconds\n", sleep_time);
            sleep((int)(sleep_time * 1000000) / 1000);  // Convert to microseconds
        }

        last_request_time = time();
    }
}

// API client with built-in rate limiting
class RateLimitedAPIClient
{
    private JSONAPIClient api;
    private RateLimiter limiter;

    void create(string base_url, int rps, string|void token)
    {
        api = JSONAPIClient(base_url, token);
        limiter = RateLimiter(rps);
    }

    APIResponse get(string endpoint, mapping|void params)
    {
        limiter->throttle();
        return api->get(endpoint, params);
    }

    APIResponse post(string endpoint, mapping data)
    {
        limiter->throttle();
        return api->post(endpoint, data);
    }

    APIResponse put(string endpoint, mapping data)
    {
        limiter->throttle();
        return api->put(endpoint, data);
    }

    APIResponse delete(string endpoint)
    {
        limiter->throttle();
        return api->delete(endpoint);
    }
}

int main()
{
    write("=== Rate Limited API Client ===\n\n");

    // Create client limited to 2 requests per second
    RateLimitedAPIClient client = RateLimitedAPIClient(
        "https://jsonplaceholder.typicode.com",
        2  // 2 requests per second
    );

    write("Fetching multiple posts with rate limiting...\n\n");

    // Fetch multiple posts
    for (int i = 1; i <= 5; i++) {
        write("Fetching post %d...\n", i);
        APIResponse resp = client->get("/posts/" + i);

        if (resp->success) {
            mapping post = resp->data;
            write("  ✓ %s\n", post->title);
        }
    }

    write("\nAll requests completed with rate limiting!\n");

    return 0;
}
