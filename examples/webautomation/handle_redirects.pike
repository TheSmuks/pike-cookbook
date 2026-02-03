#!/usr/bin/env pike
#pragma strict_types
// Following HTTP redirects

int main()
{
    string url = "https://httpbin.org/redirect/3";

    // Protocols.HTTP follows redirects by default
    // Max redirects can be controlled
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    write("Final URL: %s\n", q->url);  // Where we ended up
    write("Status: %d\n", q->status);
    write("Redirects followed: %d\n", q->redirects || 0);

    // To disable redirects, use low-level Query object
    Protocols.HTTP.Query q2 = Protocols.HTTP.Query();
    q2->follow_redirects = 0;
    q2->sync_request(url, "GET", ([]));

    write("\nWithout following redirect:\n");
    write("Status: %d\n", q2->status);
    write("Location: %s\n", q2->headers["location"] || "none");

    return 0;
}
