#!/usr/bin/env pike
#pragma strict_types
// High-level JSON API wrapper with error handling

class APIResponse
{
    int success;
    int status;
    mixed data;
    string error;
    mapping headers;

    void create(int s, int st, mixed d, string|void e, mapping|void h)
    {
        success = s;
        status = st;
        data = d;
        error = e;
        headers = h || ([]);
    }

    string to_string()
    {
        if (success) {
            return sprintf("APIResponse(status=%d, data=%O)", status, data);
        } else {
            return sprintf("APIResponse(status=%d, error=%s)", status, error);
        }
    }
}

class JSONAPIClient
{
    private RESTClient rest;

    void create(string base_url, string|void token)
    {
        rest = RESTClient(base_url, token);
    }

    // Get with automatic pagination
    array(mapping) get_all(string endpoint, mapping|void params)
    {
        array(mapping) all_items = ({});
        int page = 1;
        int per_page = 100;

        while (1) {
            mapping p = params || ([]);
            p->page = (string)page;
            p->per_page = (string)per_page;

            APIResponse resp = fetch("GET", endpoint, p);

            if (!resp->success) {
                werror("Error fetching page %d: %s\n", page, resp->error);
                break;
            }

            array items = resp->data;
            if (!arrayp(items) || !sizeof(items)) {
                break;
            }

            all_items += items;

            if (sizeof(items) < per_page) {
                break;  // Last page
            }

            page++;
        }

        return all_items;
    }

    // Fetch with retry logic
    APIResponse fetch_with_retry(string method, string endpoint,
                                  mapping|void data,
                                  int|void max_retries)
    {
        max_retries = max_retries || 3;
        int attempt = 0;

        while (attempt < max_retries) {
            APIResponse resp = fetch(method, endpoint, data);

            if (resp->success) {
                return resp;
            }

            // Don't retry client errors (4xx)
            if (resp->status >= 400 && resp->status < 500) {
                return resp;
            }

            // Retry server errors (5xx)
            attempt++;
            if (attempt < max_retries) {
                write("Attempt %d failed, retrying in %d seconds...\n",
                      attempt, attempt);
                sleep(attempt);
            }
        }

        return APIResponse(0, 0, 0, "Max retries exceeded");
    }

    // Generic fetch method
    APIResponse fetch(string method, string endpoint, mapping|void data)
    {
        mapping result;

        switch(method)
        {
            case "GET":
                result = rest->get(endpoint, data);
                break;
            case "POST":
                result = rest->post(endpoint, data || ([]));
                break;
            case "PUT":
                result = rest->put(endpoint, data || ([]));
                break;
            case "DELETE":
                result = rest->delete(endpoint);
                break;
            case "PATCH":
                result = rest->patch(endpoint, data || ([]));
                break;
            default:
                return APIResponse(0, 0, 0, "Unknown method: " + method);
        }

        return APIResponse(
            result->success,
            result->status,
            result->data,
            result->error
        );
    }

    // Convenience methods
    APIResponse get(string endpoint, mapping|void params)
    {
        return fetch("GET", endpoint, params);
    }

    APIResponse post(string endpoint, mapping data)
    {
        return fetch("POST", endpoint, data);
    }

    APIResponse put(string endpoint, mapping data)
    {
        return fetch("PUT", endpoint, data);
    }

    APIResponse delete(string endpoint)
    {
        return fetch("DELETE", endpoint);
    }
}

int main()
{
    write("=== JSON API Client Example ===\n\n");

    JSONAPIClient api = JSONAPIClient("https://jsonplaceholder.typicode.com");

    // Simple GET
    write("1. Fetching user #1\n");
    APIResponse resp = api->get("/users/1");

    if (resp->success) {
        mapping user = resp->data;
        write("   ✓ Name: %s\n", user->name);
        write("   ✓ Email: %s\n", user->email);
    } else {
        werror("   ✗ Error: %s\n", resp->error);
    }

    // GET with retry
    write("\n2. Fetching posts with retry logic\n");
    resp = api->fetch_with_retry("GET", "/posts", (["_limit": "5"]), 2);

    if (resp->success) {
        write("   ✓ Fetched %d posts\n", sizeof(resp->data));
    }

    // POST new item
    write("\n3. Creating new comment\n");
    resp = api->post("/comments", ([
        "postId": 1,
        "name": "Pike Tester",
        "email": "pike@example.com",
        "body": "Test comment from Pike"
    ]));

    if (resp->success) {
        write("   ✓ Created comment with ID: %d\n", resp->data->id);
    }

    // GET all with pagination simulation
    write("\n4. Fetching all posts (paginated)\n");
    array posts = api->get_all("/posts", (["_limit": "10"]));
    write("   ✓ Total posts fetched: %d\n", sizeof(posts));

    return 0;
}
