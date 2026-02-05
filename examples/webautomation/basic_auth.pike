#!/usr/bin/env pike
#pragma strict_types
// HTTP Basic Authentication

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


int main()
{
    string url = "https://httpbin.org/basic-auth/user/pass";

    // Prepare Basic Auth header
    // Format: "Basic base64(username:password)"
    string credentials = "user:pass";
    string encoded = MIME.encode_base64(credentials);

    mapping(string:string) headers = ([
        "Authorization": "Basic " + encoded,
        "User-Agent": "Pike AuthClient/1.0"
    ]);

    // Make authenticated request
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, headers);

    if (q->status == 200) {
        write("Authentication successful!\n");
        write("Response:\n");
        write("%s\n", q->data());
        return 0;
    } else if (q->status == 401) {
        werror("Authentication failed\n");
        return 1;
    } else {
        werror("Unexpected status: %d\n", q->status);
        return 1;
    }
}

// Helper class for authenticated sessions
class AuthenticatedSession
{
    private string username;
    private string password;
    private CookieJar jar = CookieJar();

    void create(string user, string pass)
    {
        username = user;
        password = pass;
    }

    // Get auth header
    private string get_auth_header()
    {
        string creds = username + ":" + password;
        return "Basic " + MIME.encode_base64(creds);
    }

    // Make authenticated GET request
    Protocols.HTTP.Query get(string url)
    {
        mapping headers = ([
            "Authorization": get_auth_header(),
            "User-Agent": "Pike AuthSession/1.0"
        ]);

        string cookie_str = jar->cookie_header(url);
        if (cookie_str) {
            headers["Cookie"] = cookie_str;
        }

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, headers);
        return q;
    }

    // Make authenticated POST request
    Protocols.HTTP.Query post(string url, mapping data)
    {
        mapping headers = ([
            "Authorization": get_auth_header(),
            "Content-Type": "application/json",
            "User-Agent": "Pike AuthSession/1.0"
        ]);

        string body = Standards.JSON.encode(data);
        return Protocols.HTTP.do_method("POST", url, ([]), headers, 0, body);
    }
}

// Example usage of authenticated session
void authenticated_session_example()
{
    AuthenticatedSession session = AuthenticatedSession("user", "pass");

    Protocols.HTTP.Query q = session->get(
        "https://httpbin.org/basic-auth/user/pass"
    );

    if (q->status == 200) {
        write("Authenticated request successful!\n");
        write("%s\n", q->data());
    }
}
