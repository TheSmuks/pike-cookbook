#!/usr/bin/env pike
#pragma strict_types
// Discover and use hidden API endpoints from JS-heavy sites

class APIDiscovery
{
    private string base_url;

    void create(string url)
    {
        base_url = url;
    }

    // Extract API endpoints from JavaScript
    array(string) find_endpoints()
    {
        Protocols.HTTP.Query q = Protocols.HTTP.get_url(base_url);
        if (q->status != 200) {
            return ({});
        }

        string html = q->data();
        array(string) endpoints = ({});
        set(string) seen = (<>);  // Deduplicate

        // Patterns for API endpoints
        array(string) patterns = ({
            // fetch('/api/...')
            "fetch\\(\\s*['\"]([^'\"]*api[^'\"]*)['\"]",
            // axios.get('/api/...')
            "\\.(get|post|put|delete)\\(\\s*['\"]([^'\"]+)['\"]",
            // url: '/api/...'
            "[\"']url[\"']:\\s*[\"']([^'\"]+)[\"']",
            // endpoint: '/...'
            "[\"']endpoint[\"']:\\s*[\"']([^'\"]+)[\"']",
        });

        foreach(patterns, string pattern) {
            object re = Regexp.PCRE.Simple(pattern, ["DOTALL"]);
            int pos = 0;

            while (pos < sizeof(html)) {
                array(string) match = re->match(html, pos);
                if (!match) break;

                string endpoint = match[sizeof(match) - 1];

                // Convert relative URLs to absolute
                if (has_prefix(endpoint, "/")) {
                    string base = Standards.URI(base_url)->get_base_url();
                    endpoint = base + endpoint;
                }

                if (!seen[endpoint]) {
                    seen[endpoint] = 1;
                    endpoints += ({ endpoint });
                }

                pos = html->search(match[0], pos) + sizeof(match[0]);
            }
        }

        return endpoints;
    }

    // Try discovered endpoints
    void test_endpoints(array(string) endpoints)
    {
        write("\nTesting discovered endpoints:\n");
        write("================================\n");

        foreach(endpoints, string endpoint) {
            write("\nTrying: %s\n", endpoint);

            Protocols.HTTP.Query q = Protocols.HTTP.get_url(
                endpoint,
                (["Accept": "application/json"])
            );

            write("  Status: %d\n", q->status);

            if (q->status >= 200 && q->status < 300) {
                // Try to parse as JSON
                mixed data = Standards.JSON.decode(q->data());
                if (mappingp(data)) {
                    write("  ✓ JSON response - valid API endpoint!\n");
                    write("  Keys: %s\n", String.imode(indices(data)));
                }
            } else if (q->status == 401) {
                write("  ⚠ Requires authentication\n");
            } else if (q->status == 404) {
                write("  ✗ Not found\n");
            }
        }
    }
}

int main(int argc, array(string) argv)
{
    if (argc < 2) {
        werror("Usage: %s <url>\n", argv[0]);
        werror("Example: %s https://example.com\n", argv[0]);
        return 1;
    }

    string url = argv[1];

    write("=== API Endpoint Discovery ===\n\n");
    write("Target: %s\n", url);

    APIDiscovery discovery = APIDiscovery(url);

    write("\nDiscovering API endpoints...\n");
    array(string) endpoints = discovery->find_endpoints();

    write("\nFound %d potential endpoints:\n", sizeof(endpoints));
    foreach(endpoints, string ep) {
        write("  - %s\n", ep);
    }

    if (sizeof(endpoints)) {
        discovery->test_endpoints(endpoints);
    }

    return 0;
}
