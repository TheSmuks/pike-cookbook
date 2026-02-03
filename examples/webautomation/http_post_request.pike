#!/usr/bin/env pike
#pragma strict_types
// HTTP POST request with form data

int main(int argc, array(string) argv)
{
    // POST form data to a URL
    string url = "https://httpbin.org/post";

    mapping(string:string) form_data = ([
        "username": "testuser",
        "email": "test@example.com",
        "message": "Hello from Pike!"
    ]);

    // Create POST query with form-encoded data
    Protocols.HTTP.Query q = Protocols.HTTP.post_url(
        url,
        form_data,
        (["User-Agent": "Pike/8.0 WebAutomation"])
    );

    if (q->status >= 200 && q->status < 300) {
        write("POST successful!\n");
        write("Status: %d\n", q->status);
        write("\nResponse:\n");
        write(q->data());
        return 0;
    } else {
        werror("POST failed: %d %s\n", q->status, q->status_desc);
        return 1;
    }
}
