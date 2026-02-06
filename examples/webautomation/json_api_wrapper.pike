#!/usr/bin/env pike
#pragma strict_types
// High-level JSON API wrapper with error handling

// RESTClient class (from rest_api_client.pike)
class RESTClient
{
    private string base_url;
    private string|void auth_token;
    private mapping(string:string) default_headers = ([
        "User-Agent": "Pike RESTClient/1.0",
        "Accept": "application/json"
    ]);

    void create(string url, string|void token)
    {
        base_url = url;
        auth_token = token;
    }

    // Build headers with auth
    private mapping(string:string) get_headers(mapping|void extra_headers)
    {
        mapping(string:string) headers = copy_value(default_headers);

        if (auth_token) {
            headers["Authorization"] = "Bearer " + auth_token;
        }

        if (extra_headers) {
            headers |= (mapping(string:string))extra_headers;
        }

        return headers;
    }

    // Generic request method
    private Protocols.HTTP.Query request(string method, string endpoint,
                                          mapping|void data,
                                          mapping|void extra_headers)
    {
        string url = base_url + endpoint;
        mapping(string:string) headers = get_headers(extra_headers);

        Protocols.HTTP.Query q;

        if (method == "GET") {
            if (data && sizeof(data)) {
                array(string) params =({});
                foreach(indices(data), mixed key) {
                    if (stringp(key)) {
                        mixed val = data[key];
                        string val_str = stringp(val) ? (string)val : sprintf("%O", val);
                        params += ({ Protocols.HTTP.uri_encode((string)key) + "=" +
                                     Protocols.HTTP.uri_encode(val_str) });
                    }
                }
                url += "?" + (params * "&");
            }
            q = Protocols.HTTP.get_url(url, (mapping(string:int|array(string)|string))headers);
        }
        else if (method == "POST") {
            headers["Content-Type"] = "application/json";
            string body = data ? Standards.JSON.encode(data) : "{}";
            q = Protocols.HTTP.do_method("POST", url, ([]), (mapping(string:array(string)|string))headers, 0, body);
        }
        else if (method == "PUT") {
            headers["Content-Type"] = "application/json";
            string body = data ? Standards.JSON.encode(data) : "{}";
            q = Protocols.HTTP.do_method("PUT", url, ([]), (mapping(string:array(string)|string))headers, 0, body);
        }
        else if (method == "DELETE") {
            q = Protocols.HTTP.do_method("DELETE", url, ([]), (mapping(string:array(string)|string))headers);
        }
        else if (method == "PATCH") {
            headers["Content-Type"] = "application/json";
            string body = data ? Standards.JSON.encode(data) : "{}";
            q = Protocols.HTTP.do_method("PATCH", url, ([]), (mapping(string:array(string)|string))headers, 0, body);
        }

        return q;
    }

    // GET request
    mapping get(string endpoint, mapping|void params)
    {
        Protocols.HTTP.Query q = request("GET", endpoint, params);

        if (q->status >= 200 && q->status < 300) {
            return ([
                "success": 1,
                "status": q->status,
                "data": Standards.JSON.decode(q->data())
            ]);
        } else {
            return ([
                "success": 0,
                "status": q->status,
                "error": q->status_desc
            ]);
        }
    }

    // POST request
    mapping post(string endpoint, mapping data)
    {
        Protocols.HTTP.Query q = request("POST", endpoint, data);

        if (q->status >= 200 && q->status < 300) {
            return ([
                "success": 1,
                "status": q->status,
                "data": Standards.JSON.decode(q->data())
            ]);
        } else {
            return ([
                "success": 0,
                "status": q->status,
                "error": q->status_desc
            ]);
        }
    }

    // PUT request
    mapping put(string endpoint, mapping data)
    {
        Protocols.HTTP.Query q = request("PUT", endpoint, data);

        if (q->status >= 200 && q->status < 300) {
            return ([
                "success": 1,
                "status": q->status,
                "data": Standards.JSON.decode(q->data())
            ]);
        } else {
            return ([
                "success": 0,
                "status": q->status,
                "error": q->status_desc
            ]);
        }
    }

    // DELETE request
    mapping delete(string endpoint)
    {
        Protocols.HTTP.Query q = request("DELETE", endpoint);

        if (q->status >= 200 && q->status < 300) {
            return ([
                "success": 1,
                "status": q->status,
                "data": Standards.JSON.decode(q->data() || "{}")
            ]);
        } else {
            return ([
                "success": 0,
                "status": q->status,
                "error": q->status_desc
            ]);
        }
    }

    // PATCH request
    mapping patch(string endpoint, mapping data)
    {
        Protocols.HTTP.Query q = request("PATCH", endpoint, data);

        if (q->status >= 200 && q->status < 300) {
            return ([
                "success": 1,
                "status": q->status,
                "data": Standards.JSON.decode(q->data())
            ]);
        } else {
            return ([
                "success": 0,
                "status": q->status,
                "error": q->status_desc
            ]);
        }
    }
}

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

            // Check if data is an array (could be mapping for single items)
            mixed data = resp->data;
            if (!arrayp(data)) {
                break;
            }

            array items_array = (array)data;
            if (!sizeof(items_array)) {
                break;
            }

            all_items += items_array;

            if (sizeof(items_array) < per_page) {
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

        mixed success = result->success;
        mixed status = result->status;
        mixed response_data = result->data;
        mixed error = result->error;

        return APIResponse(
            intp(success) ? (int)success : 0,
            intp(status) ? (int)status : 0,
            response_data,
            stringp(error) ? (string)error : 0
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
        mixed data = resp->data;
        if (mappingp(data)) {
            mapping user = (mapping)data;
            mixed name = user->name;
            mixed email = user->email;
            write("   ✓ Name: %s\n", stringp(name) ? (string)name : "N/A");
            write("   ✓ Email: %s\n", stringp(email) ? (string)email : "N/A");
        }
    } else {
        mixed error = resp->error;
        werror("   ✗ Error: %s\n", stringp(error) ? (string)error : "Unknown error");
    }

    // GET with retry
    write("\n2. Fetching posts with retry logic\n");
    resp = api->fetch_with_retry("GET", "/posts", (["_limit": "5"]), 2);

    if (resp->success) {
        mixed data = resp->data;
        if (arrayp(data)) {
            array data_array = (array)data;
            write("   ✓ Fetched %d posts\n", sizeof(data_array));
        } else {
            write("   ✓ Got response (not an array)\n");
        }
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
        mixed data = resp->data;
        if (mappingp(data)) {
            mapping result_map = (mapping)data;
            mixed id = result_map->id;
            if (intp(id)) {
                write("   ✓ Created comment with ID: %d\n", (int)id);
            } else {
                write("   ✓ Created comment\n");
            }
        }
    }

    // GET all with pagination simulation
    write("\n4. Fetching all posts (paginated)\n");
    array posts = api->get_all("/posts", (["_limit": "10"]));
    write("   ✓ Total posts fetched: %d\n", sizeof(posts));

    return 0;
}
