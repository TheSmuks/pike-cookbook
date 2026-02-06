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
                array(string) params = (array(string))map(indices(data), lambda(mixed key) {
                    return Protocols.HTTP.uri_encode((string)key) + "=" +
                           Protocols.HTTP.uri_encode((string)data[key]);
                });
                full_url += "?" + (params * "&");
            }
            q = Protocols.HTTP.get_url(full_url, headers);
        } else if (method == "POST") {
            if (headers["Content-Type"] == "application/json") {
                string body = Standards.JSON.encode(data);
                q = Protocols.HTTP.do_method("POST", url, ([]), headers, 0, body);
            } else {
                mapping(string:string|int|array(string)) post_data = (mapping(string:string|int|array(string)))(data || ([]));
                q = Protocols.HTTP.post_url(url, post_data, headers);
            }
        }

        // Extract cookies from response
        mixed set_cookie = q->headers["set-cookie"];
        if (set_cookie) {
            parse_cookies(set_cookie);
        }

        return q;
    }

    // Parse Set-Cookie header
    void parse_cookies(mixed cookie_header)
    {
        // Handle multiple cookies (may be array or string)
        array(string) cookie_strings;
        if (arrayp(cookie_header)) {
            // Cast each element to string
            cookie_strings = Array.map((array)cookie_header, lambda(mixed item) {
                if (stringp(item)) return (string)item;
                return sprintf("%O", item);
            });
        } else if (stringp(cookie_header)) {
            cookie_strings = ((string)cookie_header) / "\n";
        } else {
            return;
        }

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
    if (!q) {
        werror("   Failed to connect (network error)\n");
        write("   This example requires network access to httpbin.org\n");
        return 0;
    }
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
    if (!q) {
        werror("   Failed to connect (network error)\n");
        return 0;
    }
    write("   Status: %d\n", q->status);
    if (q->status == 200) {
        write("   Cookies sent:\n");
        mixed result = catch {
            mixed decoded = Standards.JSON.decode(q->data());
            if (mappingp(decoded)) {
                mapping response = (mapping)decoded;
                if (response->cookies) {
                    if (mappingp(response->cookies)) {
                        mapping cookie_map = (mapping)response->cookies;
                        foreach(values(cookie_map), mixed data) {
                            if (mappingp(data)) {
                                mapping cookie_data = (mapping)data;
                                write("     %s: %s\n", (string)cookie_data->Name, (string)cookie_data->Value);
                            }
                        }
                    }
                }
            }
        };
        if (result) {
            werror("   Failed to parse response\n");
        }
    }

    return 0;
}
