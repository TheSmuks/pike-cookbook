#!/usr/bin/env pike
#pragma strict_types
// REST API client with full CRUD operations

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
        mapping(string:string|array(string)) headers = (mapping(string:string|array(string)))get_headers(extra_headers);

        Protocols.HTTP.Query q;

        if (method == "GET") {
            if (data && sizeof(data)) {
                array(string) params = ({});
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
            q = Protocols.HTTP.get_url(url, (mapping(string:string))headers);
        }
        else if (method == "POST") {
            headers["Content-Type"] = "application/json";
            string body = data ? Standards.JSON.encode(data) : "{}";
            q = Protocols.HTTP.do_method("POST", url, ([]), headers, 0, body);
        }
        else if (method == "PUT") {
            headers["Content-Type"] = "application/json";
            string body = data ? Standards.JSON.encode(data) : "{}";
            q = Protocols.HTTP.do_method("PUT", url, ([]), headers, 0, body);
        }
        else if (method == "DELETE") {
            q = Protocols.HTTP.do_method("DELETE", url, ([]), headers);
        }
        else if (method == "PATCH") {
            headers["Content-Type"] = "application/json";
            string body = data ? Standards.JSON.encode(data) : "{}";
            q = Protocols.HTTP.do_method("PATCH", url, ([]), headers, 0, body);
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

int main()
{
    write("=== REST API Client Examples ===\n\n");

    // Example with JSONPlaceholder API
    RESTClient client = RESTClient("https://jsonplaceholder.typicode.com");

    // GET all posts
    write("1. GET all posts\n");
    mapping result = client->get("/posts", (["limit": "3"]));
    if (result->success) {
        mixed data = result->data;
        if (arrayp(data)) {
            write("   ✓ Fetched %d posts\n", sizeof((array)data));
            array data_array = (array)data;
            if (sizeof(data_array)) {
                mixed first = data_array[0];
                if (mappingp(first)) {
                    mixed title = ((mapping)first)->title;
                    write("   First: %s\n", stringp(title) ? (string)title : "N/A");
                }
            }
        } else {
            write("   ✓ Got response\n");
        }
    }

    // GET single post
    write("\n2. GET post #1\n");
    result = client->get("/posts/1");
    if (result->success) {
        mixed data = result->data;
        if (mappingp(data)) {
            mapping post = (mapping)data;
            mixed title = post->title;
            write("   ✓ Title: %s\n", stringp(title) ? (string)title : "N/A");
        }
    }

    // POST new post
    write("\n3. POST new post\n");
    result = client->post("/posts", ([
        "title": "Pike REST Client",
        "body": "Testing REST operations from Pike",
        "userId": 1
    ]));
    if (result->success) {
        mixed data = result->data;
        if (mappingp(data)) {
            mapping created = (mapping)data;
            mixed id = created->id;
            if (intp(id)) {
                write("   ✓ Created with ID: %d\n", (int)id);
            } else {
                write("   ✓ Created\n");
            }
        }
    }

    // PUT update
    write("\n4. PUT update post #1\n");
    result = client->put("/posts/1", ([
        "id": 1,
        "title": "Updated Title",
        "body": "Updated content",
        "userId": 1
    ]));
    if (result->success) {
        write("   ✓ Updated\n");
    }

    // PATCH partial update
    write("\n5. PATCH post #1\n");
    result = client->patch("/posts/1", ([
        "title": "Patched Title"
    ]));
    if (result->success) {
        write("   ✓ Patched\n");
    }

    // DELETE
    write("\n6. DELETE post #1\n");
    result = client->delete("/posts/1");
    if (result->success) {
        write("   ✓ Deleted\n");
    }

    return 0;
}
