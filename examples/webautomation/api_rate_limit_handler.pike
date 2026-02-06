#!/usr/bin/env pike
#pragma strict_types
// Rate limiting for API requests

// Simple JSON API client
class JSONAPIClient
{
    private string base_url;
    private string|void token;

    void create(string url, string|void tok)
    {
        base_url = url;
        token = tok;
    }

    APIResponse get(string endpoint, mapping|void params)
    {
        string url = base_url + endpoint;
        mapping headers = ([
            "User-Agent": "Pike APIClient/1.0",
            "Accept": "application/json"
        ]);

        if (token) {
            headers["Authorization"] = "Bearer " + token;
        }

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, (mapping(string:string))headers);

        return APIResponse(q->status == 200, (string)q->data(), q->status);
    }

    APIResponse post(string endpoint, mapping data)
    {
        string url = base_url + endpoint;
        mapping headers = ([
            "User-Agent": "Pike APIClient/1.0",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]);

        if (token) {
            headers["Authorization"] = "Bearer " + token;
        }

        string body = Standards.JSON.encode(data);
        Protocols.HTTP.Query q = Protocols.HTTP.do_method("POST", url, ([]), (mapping(string:string))headers, 0, body);

        return APIResponse(q->status == 200, (string)q->data(), q->status);
    }

    APIResponse put(string endpoint, mapping data)
    {
        string url = base_url + endpoint;
        mapping headers = ([
            "User-Agent": "Pike APIClient/1.0",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]);

        if (token) {
            headers["Authorization"] = "Bearer " + token;
        }

        string body = Standards.JSON.encode(data);
        Protocols.HTTP.Query q = Protocols.HTTP.do_method("PUT", url, ([]), (mapping(string:string))headers, 0, body);

        return APIResponse(q->status == 200, (string)q->data(), q->status);
    }

    APIResponse delete(string endpoint)
    {
        string url = base_url + endpoint;
        mapping headers = ([
            "User-Agent": "Pike APIClient/1.0",
            "Accept": "application/json"
        ]);

        if (token) {
            headers["Authorization"] = "Bearer " + token;
        }

        Protocols.HTTP.Query q = Protocols.HTTP.do_method("DELETE", url, ([]), (mapping(string:string))headers, 0, 0);

        return APIResponse(q->status == 200 || q->status == 204, (string)q->data(), q->status);
    }
}

// API response wrapper
class APIResponse
{
    public int success;
    public mixed data;
    public int status;

    void create(int succ, mixed d, int stat)
    {
        success = succ;
        status = stat;

        // Ensure data is always a string before JSON decode
        if (stringp(d)) {
            string s = (string)d;
            mixed parsed = Standards.JSON.decode(s);
            if (mappingp(parsed)) {
                data = parsed;
            } else {
                data = s;
            }
        } else {
            data = "";
        }
    }
}


class RateLimiter
{
    private int requests_per_second;
    private int last_request_time = 0;
    private float min_interval;

    void create(int rps)
    {
        requests_per_second = rps;
        min_interval = 1.0 / (float)rps;
    }

    // Wait if necessary to maintain rate limit
    void throttle()
    {
        int current_time = time();
        float elapsed = (float)(current_time - last_request_time);

        if (elapsed < min_interval) {
            float sleep_time = min_interval - elapsed;
            write("Rate limit: sleeping %.2f seconds\n", sleep_time);
            System.usleep((int)(sleep_time * 1000000));  // Convert to microseconds
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

        if (resp->success && mappingp(resp->data)) {
            mapping post = (mapping)resp->data;
            write("  ✓ %s\n", (string)post->title || "(no title)");
        }
    }

    write("\nAll requests completed with rate limiting!\n");

    return 0;
}
