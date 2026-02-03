#!/usr/bin/env pike
#pragma strict_types
// Form submission with POST method

int main()
{
    // POST form submission - data in body
    string url = "https://httpbin.org/post";

    mapping(string:string) form_data = ([
        "username": "testuser",
        "password": "secretpass",
        "remember": "yes"
    ]);

    // POST with form-encoded data
    Protocols.HTTP.Query q = Protocols.HTTP.post_url(
        url,
        form_data,
        ([
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Pike FormBot/1.0"
        ])
    );

    if (q->status >= 200 && q->status < 300) {
        write("Form submitted successfully!\n");
        write("Status: %d\n", q->status);

        // Parse JSON response if applicable
        mapping response = Standards.JSON.decode(q->data());
        write("\nForm data received:\n");
        foreach(form_data; string key; string value) {
            write("  %s: %s\n", key, response->form[key] || "not found");
        }
        return 0;
    } else {
        werror("Form submission failed: %d %s\n", q->status, q->status_desc);
        return 1;
    }
}
