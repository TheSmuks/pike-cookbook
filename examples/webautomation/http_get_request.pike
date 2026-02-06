#!/usr/bin/env pike
#pragma strict_types
// Basic HTTP GET request using Protocols.HTTP

int main(int argc, array(string) argv)
{
    if (argc < 2) {
        write("Usage: %s <url>\n", argv[0]);
        write("Running in demo mode with https://httpbin.org/get ...\n");
        argv = ({ argv[0], "https://httpbin.org/get" });
    }

    string url = argv[1];

    // Perform a simple GET request
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    if (q->status == 200) {
        write("Success!\n");
        write("Status: %d %s\n", q->status, q->status_desc);
        mixed ct = q->headers["content-type"];
        write("Content-Type: %s\n", stringp(ct) ? (string)ct : "unknown");
        write("Content-Length: %d bytes\n", sizeof(q->data()));
        write("\n--- Body (first 500 chars) ---\n");
        write(q->data()[0..499]);
        return 0;
    } else {
        werror("HTTP Error: %d %s\n", q->status, q->status_desc);
        return 1;
    }
}
