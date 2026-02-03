#!/usr/bin/env pike
#pragma strict_types
// Automated login simulation

class LoginSession
{
    private mapping(string:string) cookies = ([]);
    private string user_agent = "Pike AuthBot/1.0";

    // Make request with cookie persistence
    Protocols.HTTP.Query request(string method, string url,
                                 mapping|void data, mapping|void extra_headers)
    {
        mapping(string:string) headers = ([
            "User-Agent": user_agent
        ]);

        // Add cookies
        if (sizeof(cookies)) {
            array(string) cookie_pairs = ({});
            foreach(cookies; string name; string value) {
                cookie_pairs += ({ name + "=" + value });
            }
            headers["Cookie"] = cookie_pairs * "; ";
        }

        if (extra_headers) {
            headers |= extra_headers;
        }

        Protocols.HTTP.Query q;

        if (method == "GET") {
            string full_url = url;
            if (data && sizeof(data)) {
                array(string) params = map(indices(data), lambda(string key) {
                    return Protocols.HTTP.uri_encode(key) + "=" +
                           Protocols.HTTP.uri_encode(data[key]);
                });
                full_url += "?" + (params * "&");
            }
            q = Protocols.HTTP.get_url(full_url, headers);
        } else if (method == "POST") {
            if (headers["Content-Type"] == "application/json") {
                string body = Standards.JSON.encode(data);
                q = Protocols.HTTP.do_method("POST", url, ([]), headers, 0, body);
            } else {
                q = Protocols.HTTP.post_url(url, data || ([]), headers);
            }
        }

        // Extract cookies from response
        if (q->headers["set-cookie"]) {
            parse_cookies(q->headers["set-cookie"]);
        }

        return q;
    }

    // Parse Set-Cookie header
    void parse_cookies(string cookie_header)
    {
        // Handle multiple cookies
        array(string) cookie_strings = cookie_header / "\n";

        foreach(cookie_strings, string cookie_str) {
            // Parse: name=value; attributes
            array(string) parts = cookie_str / ";";
            if (sizeof(parts)) {
                array(string) nv = parts[0] / "=";
                if (sizeof(nv) == 2) {
                    cookies[nv[0]] = nv[1];
                }
            }
        }
    }

    // Check if logged in (has session cookie)
    int is_authenticated()
    {
        return has_index(cookies, "session") || has_index(cookies, "session_id");
    }
}

int main()
{
    LoginSession session = LoginSession();

    // Simulate login flow
    write("=== Login Flow Simulation ===\n\n");

    // 1. GET login page
    write("1. Fetching login page...\n");
    Protocols.HTTP.Query q = session->request("GET", "https://httpbin.org/cookies/set/session/abc123");
    write("   Status: %d\n", q->status);

    // 2. Check authentication
    write("\n2. Checking authentication...\n");
    if (session->is_authenticated()) {
        write("   ✓ Authenticated\n");
    } else {
        write("   ✗ Not authenticated\n");
    }

    // 3. Access protected resource
    write("\n3. Accessing protected resource...\n");
    q = session->request("GET", "https://httpbin.org/cookies");
    write("   Status: %d\n", q->status);
    if (q->status == 200) {
        write("   Cookies sent:\n");
        mapping response = Standards.JSON.decode(q->data());
        foreach(response->cookies; string cookie; mapping data) {
            write("     %s: %s\n", data->Name, data->Value);
        }
    }

    return 0;
}
