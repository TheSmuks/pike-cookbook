#!/usr/bin/env pike
#pragma strict_types
// Session persistence across multiple requests

// Cookie jar for persistent session management
class CookieJar
{
    private mapping(string:mapping(string:mixed)) cookies = ([]);

    // Store cookie from Set-Cookie header
    void set_cookie(string cookie_str, string|void domain)
    {
        // Parse: name=value; Expires=date; Path=/; Domain=.example.com; Secure
        array(string) parts = cookie_str / ";";

        string name;
        string value;
        string cookie_domain = domain;
        string path = "/";
        int secure = 0;

        foreach(parts, string part) {
            part = (part - " " - "\t" - "\n" - "\r");
            array(string) nv = part / "=";

            if (sizeof(nv) == 2) {
                string key = (nv[0] - " " - "\t" - "\n" - "\r");
                string val = (nv[1] - " " - "\t" - "\n" - "\r");

                switch(lower_case(key))
                {
                    case "domain":
                        cookie_domain = val;
                        break;
                    case "path":
                        path = val;
                        break;
                    case "secure":
                        secure = 1;
                        break;
                    default:
                        // First attribute is name=value
                        if (!name) {
                            name = key;
                            value = val;
                        }
                        break;
                }
            } else if (lower_case(part) == "secure") {
                secure = 1;
            }
        }

        if (name && cookie_domain) {
            cookies[name] = ([
                "value": value,
                "domain": cookie_domain,
                "path": path,
                "secure": secure
            ]);
        }
    }

    // Get cookies for a request
    mapping(string:string) get_cookies(string url)
    {
        mapping(string:string) result = ([]);

        // Extract domain from URL
        Standards.URI uri = Standards.URI(url);
        string domain = uri->host;

        foreach(cookies; string name; mapping attrs) {
            // Simple domain matching (should be more robust)
            mixed domain_val = attrs->domain;
            if (domain_val && has_value(domain, (string)domain_val)) {
                result[name] = (string)attrs->value;
            }
        }

        return result;
    }

    // Format cookies for Cookie header
    string cookie_header(string url)
    {
        mapping(string:string) cookies_map = get_cookies(url);
        if (!sizeof(cookies_map)) {
            return 0;
        }

        array(string) pairs = ({});
        foreach(cookies_map; string name; string value) {
            pairs += ({ name + "=" + value });
        }
        return pairs * "; ";
    }

    // Clear all cookies
    void clear()
    {
        cookies = ([]);
    }
}


class WebSession
{
    private CookieJar jar = CookieJar();
    private mapping(string:string) default_headers = ([
        "User-Agent": "Pike SessionBot/1.0",
        "Accept": "application/json"
    ]);

    // Perform GET request with session
    Protocols.HTTP.Query get(string url)
    {
        mapping(string:string|int|array(string)) headers = copy_value(default_headers);

        string cookie_str = jar->cookie_header(url);
        if (cookie_str) {
            headers["Cookie"] = cookie_str;
        }

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, headers);

        // Store any new cookies
        update_cookies(q);

        return q;
    }

    // Perform POST request with session
    Protocols.HTTP.Query post(string url, mapping data)
    {
        mapping(string:string|array(string)) headers = copy_value(default_headers);
        headers["Content-Type"] = "application/json";

        string cookie_str = jar->cookie_header(url);
        if (cookie_str) {
            headers["Cookie"] = cookie_str;
        }

        string body = Standards.JSON.encode(data);
        Protocols.HTTP.Query q = Protocols.HTTP.do_method(
            "POST", url, ([]), headers, 0, body
        );

        update_cookies(q);

        return q;
    }

    // Update cookie jar from response
    void update_cookies(Protocols.HTTP.Query q)
    {
        mixed set_cookie_header = q->headers["set-cookie"];
        if (set_cookie_header) {
            jar->set_cookie((string)set_cookie_header);
        }
    }

    // Check if session is active
    int has_session()
    {
        // Check for common session cookie names
        return sizeof(jar->get_cookies("https://example.com")) > 0;
    }
}

int main()
{
    WebSession session = WebSession();

    write("=== Multi-step workflow with session ===\n\n");
    write("Note: This example uses httpbin.org for testing.\n");

    // Step 1: Login
    write("Step 1: Setting session cookie\n");
    Protocols.HTTP.Query q = 0;

    mixed err = catch {
        q = session->get(
            "https://httpbin.org/cookies/set/session/token12345"
        );
    };

    if (err || !q) {
        write("Network unavailable - skipping network-dependent steps\n");
        write("With network access, this would demonstrate:\n");
        write("  1. Setting session cookies via HTTP headers\n");
        write("  2. Maintaining cookies across requests\n");
        write("  3. Making authenticated API calls\n");
        write("  4. Session cleanup on logout\n");
        return 0;
    }

    write("Status: %d\n", q->status);

    // Step 2: Use session
    write("\nStep 2: Accessing protected resource with session\n");
    q = session->get("https://httpbin.org/cookies");
    if (q && q->status == 200) {
        mixed parse_err = catch {
            mixed json_result = Standards.JSON.decode(q->data());
            // Check if JSON result is a mapping (not array or other type)
            if (mappingp(json_result)) {
                mapping data = (mapping)json_result;
                mixed cookies_val = data->cookies;
                // Handle both mapping and array for cookies
                if (mappingp(cookies_val)) {
                    write("Session active: %d\n", sizeof((mapping)cookies_val) > 0);
                } else if (arrayp(cookies_val)) {
                    write("Session active: %d\n", sizeof((array)cookies_val) > 0);
                } else {
                    write("Session active: 0\n");
                }
            } else {
                write("Session active: 0\n");
            }
        };
        if (parse_err) {
            write("Note: Could not parse response\n");
        }
    }

    // Step 3: Make authenticated POST request
    write("\nStep 3: Making authenticated POST request\n");
    q = session->post("https://httpbin.org/post", ([
        "action": "update_profile",
        "data": "test data"
    ]));
    if (q) {
        write("Status: %d\n", q->status);
    }

    // Step 4: Logout
    write("\nStep 4: Logout (clear session)\n");
    q = session->get("https://httpbin.org/cookies/delete?session");
    if (q) {
        write("Status: %d\n", q->status);
    }

    return 0;
}
