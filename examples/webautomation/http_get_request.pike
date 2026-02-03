#!/usr/bin/env pike
#pragma strict_types
// Basic HTTP GET request using Protocols.HTTP

int main(int argc, array(string) argv)
{
    if (argc < 2) {
        werror("Usage: %s <url>\n", argv[0]);
        return 1;
    }

    string url = argv[1];

    // Perform a simple GET request
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    if (q->status == 200) {
        write("Success!\n");
        write("Status: %d %s\n", q->status, q->status_desc);
        write("Content-Type: %s\n", q->headers["content-type"] || "unknown");
        write("Content-Length: %d bytes\n", sizeof(q->data()));
        write("\n--- Body (first 500 chars) ---\n");
        write(q->data()[0..499]);
        return 0;
    } else {
        werror("HTTP Error: %d %s\n", q->status, q->status_desc);
        return 1;
    }
}
