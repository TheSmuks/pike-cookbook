#!/usr/bin/env pike
#pragma strict_types
// HTTP request with custom headers

int main()
{
    string url = "https://httpbin.org/headers";

    // Custom headers for the request
    mapping(string:string) headers = ([
        "User-Agent": "Pike-WebBot/1.0",
        "Accept": "application/json",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate",
        "X-Custom-Header": "CustomValue"
    ]);

    // Perform GET request with custom headers
    Protocols.HTTP.Query q = Protocols.HTTP.Query();
    q->set_callbacks(
        lambda() { werror("Connection failed\n"); exit(1); },
        lambda(Protocols.HTTP.Query r) {
            write("Status: %d\n", r->status);
            write("Headers sent:\n");
            write(r->data());
            exit(0);
        }
    );

    q->async_request(url, "GET", headers);

    // Wait for async request to complete
    return -1;
}
