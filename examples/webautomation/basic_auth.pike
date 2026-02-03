#!/usr/bin/env pike
#pragma strict_types
// HTTP Basic Authentication

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
