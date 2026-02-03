#!/usr/bin/env pike
#pragma strict_types
// Multiple concurrent HTTP requests using async operations

// Concurrent fetching with Future/Promise pattern
int main(int argc, array(string) argv)
{
    if (argc < 2) {
        werror("Usage: %s <url1> <url2> ...\n", argv[0]);
        return 1;
    }

    array(string) urls = argv[1..];
    write("Fetching %d URLs concurrently...\n", sizeof(urls));

    // Create async requests for all URLs
    array(function|Concurrent.Future requests = map(urls, lambda(string url) {
        Concurrent.Promise p = Concurrent.Promise();

        Protocols.HTTP.Query q = Protocols.HTTP.Query();
        q->set_callbacks(
            lambda() { p->fail("Failed to fetch: " + url); },
            lambda(Protocols.HTTP.Query r) {
                p->success((["url": url, "status": r->status,
                            "size": sizeof(r->data()), "data": r->data()]));
            }
        );
        q->async_request(url, "GET", ([]));

        return p->future();
    });

    // Wait for all requests to complete
    Concurrent.Future results = Concurrent.results(requests);

    // Process results when all complete
    results->on_success(lambda(array results) {
        write("\n--- Results ---\n");
        foreach(results, mapping result) {
            write("%s: %d (%d bytes)\n",
                  result->url, result->status, result->size);
        }
        exit(0);
    });

    results->on_failure(lambda(mixed err) {
        werror("Error: %O\n", err);
        exit(1);
    });

    return -1;  // Keep running until async completes
}
