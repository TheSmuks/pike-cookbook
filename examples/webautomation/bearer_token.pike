#!/usr/bin/env pike
#pragma strict_types
// Bearer token authentication (OAuth2/JWT)

class BearerAuthSession
{
    private string access_token;
    private string token_type = "Bearer";

    void create(string token)
    {
        access_token = token;
    }

    // Get authorization header
    private string get_auth_header()
    {
        return token_type + " " + access_token;
    }

    // Make authenticated GET request
    Protocols.HTTP.Query get(string url, mapping|void extra_headers)
    {
        mapping headers = ([
            "Authorization": get_auth_header(),
            "User-Agent": "Pike BearerAuth/1.0"
        ]);

        if (extra_headers) {
            headers |= extra_headers;
        }

        return Protocols.HTTP.get_url(url, headers);
    }

    // Make authenticated POST request
    Protocols.HTTP.Query post(string url, mapping data, mapping|void extra_headers)
    {
        mapping headers = ([
            "Authorization": get_auth_header(),
            "Content-Type": "application/json",
            "User-Agent": "Pike BearerAuth/1.0"
        ]);

        if (extra_headers) {
            headers |= extra_headers;
        }

        string body = Standards.JSON.encode(data);
        return Protocols.HTTP.do_method("POST", url, ([]), headers, 0, body);
    }

    // Set new token
    void set_token(string token)
    {
        access_token = token;
    }

    // Get current token
    string get_token()
    {
        return access_token;
    }
}

int main()
{
    // Simulate OAuth2 token flow
    write("=== OAuth2 Bearer Token Example ===\n\n");

    // Step 1: Obtain token (in reality, this would be from OAuth server)
    string mock_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
                       "eyJzdWIiOiIxMjM0NTY3ODkwIn0." +
                       "signature";

    BearerAuthSession session = BearerAuthSession(mock_token);

    // Step 2: Use token to access protected resource
    write("Making authenticated request with bearer token...\n");
    Protocols.HTTP.Query q = session->get(
        "https://httpbin.org/bearer",
        (["Accept": "application/json"])
    );

    write("Status: %d\n", q->status);

    if (q->status == 200) {
        mapping response = Standards.JSON.decode(q->data());
        write("Authenticated: %d\n", response->authenticated || 0);
        write("Token: %s\n", response->token || "not echoed");
    } else if (q->status == 401) {
        werror("Unauthorized - token may be invalid\n");
    }

    return 0;
}
