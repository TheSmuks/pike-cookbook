#!/usr/bin/env pike
#pragma strict_types
// Following HTTP redirects

int main()
{
    string url = "https://httpbin.org/redirect/3";

    // Protocols.HTTP follows redirects by default
    // Max redirects can be controlled
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    write("Final URL: %s\n", (string)(q->url || "unknown"));  // Where we ended up
    write("Status: %d\n", q->status);
    write("Redirects followed: %d\n", (int)(q->redirects || 0));

    return 0;
}
