#!/usr/bin/env pike
#pragma strict_types
// Multiple concurrent HTTP requests using async operations

// Concurrent fetching with Future/Promise pattern
int main(int argc, array(string) argv)
{
    if (argc < 2) {
        write("Usage: %s <url1> <url2> ...\n", argv[0]);
        write("Running in demo mode with example URLs ...\n");
        argv = ({ argv[0], "https://httpbin.org/get", "https://httpbin.org/delay/1", "https://example.com" });
    }

    array(string) urls = argv[1..];
    write("Fetching %d URLs concurrently...\n", sizeof(urls));

    // Create async requests for all URLs
    array(function|Concurrent.Future) requests = map(urls, lambda(string url) {
        Concurrent.Promise p = Concurrent.Promise();

        Thread.Thread(lambda() {
            Protocols.HTTP.Query q = Protocols.HTTP.get_url(
                url,
                (["User-Agent": "Pike AsyncClient/1.0"])
            );

            if (q && q->status == 200) {
                p->success((["url": url, "status": q->status,
                            "size": sizeof(q->data()), "data": q->data()]));
            } else {
                p->fail("Failed to fetch: " + url);
            }
        });

        return p->future();
    });

    // Wait for all requests to complete
    Concurrent.Future results = Concurrent.results(requests);

    // Process results when all complete
    results->on_success(lambda(mixed all_results) {
        write("\n--- Results ---\n");
        if (arrayp(all_results)) {
            foreach((array)all_results, mixed result) {
                if (mappingp(result)) {
                    mapping r = (mapping)result;
                    write("%s: %d (%d bytes)\n",
                          (string)r->url, (int)r->status, (int)r->size);
                }
            }
        }
        exit(0);
    });

    results->on_failure(lambda(mixed err) {
        werror("Error: %O\n", err);
        exit(1);
    });

    return -1;  // Keep running until async completes
}
