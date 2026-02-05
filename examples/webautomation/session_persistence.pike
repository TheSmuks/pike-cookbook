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
            if (has_value(domain, (string)attrs->domain)) {
                result[name] = attrs->value;
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
        mapping headers = copy_value(default_headers);

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
        mapping headers = copy_value(default_headers);
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
        if (q->headers["set-cookie"]) {
            jar->set_cookie(q->headers["set-cookie"]);
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

    // Step 1: Login
    write("Step 1: Setting session cookie\n");
    Protocols.HTTP.Query q = session->get(
        "https://httpbin.org/cookies/set/session/token12345"
    );
    write("Status: %d\n", q->status);

    // Step 2: Use session
    write("\nStep 2: Accessing protected resource with session\n");
    q = session->get("https://httpbin.org/cookies");
    if (q->status == 200) {
        mapping data = Standards.JSON.decode(q->data());
        write("Session active: %d\n", sizeof(data->cookies) > 0);
    }

    // Step 3: Make authenticated POST request
    write("\nStep 3: Making authenticated POST request\n");
    q = session->post("https://httpbin.org/post", ([
        "action": "update_profile",
        "data": "test data"
    ]));
    write("Status: %d\n", q->status);

    // Step 4: Logout
    write("\nStep 4: Logout (clear session)\n");
    q = session->get("https://httpbin.org/cookies/delete?session");
    write("Status: %d\n", q->status);

    return 0;
}
