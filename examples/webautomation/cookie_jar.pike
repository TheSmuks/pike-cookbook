#!/usr/bin/env pike
#pragma strict_types
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
            write("Stored cookie: %s=%s (domain: %s)\n",
                  name, value, cookie_domain);
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
            if (has_value(domain, attrs->domain)) {
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

    // Display all cookies
    void dump()
    {
        write("\n=== Cookie Jar ===\n");
        foreach(cookies; string name; mapping attrs) {
            write("%s: %s\n", name, attrs->value);
            write("  Domain: %s\n", attrs->domain);
            write("  Path: %s\n", attrs->path);
            write("  Secure: %s\n", attrs->secure ? "yes" : "no");
        }
        write("==================\n\n");
    }
}

int main()
{
    CookieJar jar = CookieJar();

    // Simulate receiving cookies
    jar->set_cookie("session=abc123; Path=/; Domain=.example.com", "example.com");
    jar->set_cookie("user=john; Path=/; Domain=.example.com", "example.com");
    jar->set_cookie("pref=dark; Path=/settings; Domain=.example.com", "example.com");

    jar->dump();

    // Make request with cookies
    string url = "https://example.com/api/data";
    string cookie_header = jar->cookie_header(url);

    if (cookie_header) {
        write("Cookie header for %s:\n", url);
        write("  %s\n", cookie_header);
    }

    // Test with Protocols.HTTP
    write("\nMaking request with cookies...\n");
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(
        "https://httpbin.org/cookies",
        (["Cookie": cookie_header])
    );

    if (q->status == 200) {
        mapping response = Standards.JSON.decode(q->data());
        write("Server received cookies:\n");
        foreach(response->cookies; string _; mapping c) {
            write("  %s = %s\n", c->Name, c->Value);
        }
    }

    return 0;
}
