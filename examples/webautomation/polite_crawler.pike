#!/usr/bin/env pike
#pragma strict_types
// Polite web crawler with rate limiting and robots.txt respect

class PoliteCrawler
{
    private int requests_per_second = 1;
    private float request_delay = 1.0;
    private float last_request_time = 0;
    private mapping(string:mixed) robots_cache = ([]);
    private string user_agent = "PikeBot/1.0 (+https://example.com/bot)";

    void create(int|void rps, string|void ua)
    {
        if (rps) {
            requests_per_second = rps;
            request_delay = 1.0 / rps;
        }
        if (ua) {
            user_agent = ua;
        }
    }

    // Respect rate limiting
    void throttle()
    {
        float current_time = (float)time(1) + ((float)time(time(time()) - (int)time())) / 1000000.0;
        float elapsed = current_time - last_request_time;

        if (elapsed < request_delay) {
            float sleep_time = request_delay - elapsed;
            int usecs = (int)(sleep_time * 1000000);
            usleep(usecs);
        }

        last_request_time = (float)time(1) + ((float)time(time(time()) - (int)time())) / 1000000.0;
    }

    // Fetch and parse robots.txt
    mapping fetch_robots_txt(string base_url)
    {
        if (robots_cache[base_url]) {
            return robots_cache[base_url];
        }

        Standards.URI uri = Standards.URI(base_url);
        string robots_url = sprintf("%s://%s/robots.txt", uri->scheme, uri->host);

        throttle();

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(
            robots_url,
            (["User-Agent": user_agent])
        );

        mapping rules = ([]);

        if (q->status == 200) {
            foreach(q->data() / "\n", string line) {
                line = String.trim_whitespace(line);

                // Skip comments and empty lines
                if (has_prefix(line, "#") || sizeof(line) == 0) {
                    continue;
                }

                // Parse User-agent and Disallow
                if (has_prefix(lower_case(line), "user-agent:")) {
                    // Multiple user-agents supported
                }
                else if (has_prefix(lower_case(line), "disallow:")) {
                    string path = String.trim_whitespace(line[9..]);
                    if (sizeof(path) > 0) {
                        rules->disallowed += ({ path });
                    }
                }
                else if (has_prefix(lower_case(line), "crawl-delay:")) {
                    string delay_str = String.trim_whitespace(line[12..]);
                    float delay = (float)delay_str;
                    if (delay > 0) {
                        rules->crawl_delay = delay;
                    }
                }
                else if (has_prefix(lower_case(line), "request-rate:")) {
                    // Parse request-rate format (e.g., "1/5")
                    string rate = String.trim_whitespace(line[13..]);
                    array parts = rate / "/";
                    if (sizeof(parts) == 2) {
                        rules->request_rate = (int)parts[0];
                        rules->request_time = (int)parts[1];
                    }
                }
            }

            robots_cache[base_url] = rules;
        } else {
            // If robots.txt not found, allow all
            rules->allow_all = 1;
            robots_cache[base_url] = rules;
        }

        return rules;
    }

    // Check if URL is allowed by robots.txt
    int is_allowed(string url)
    {
        Standards.URI uri = Standards.URI(url);
        string base_url = sprintf("%s://%s", uri->scheme, uri->host);

        mapping rules = fetch_robots_txt(base_url);

        if (rules->allow_all) {
            return 1;
        }

        string path = uri->path;

        foreach(rules->disallowed || ({}), string disallowed) {
            if (has_prefix(path, disallowed)) {
                return 0;
            }
        }

        return 1;
    }

    // Polite fetch
    Protocols.HTTP.Query fetch(string url)
    {
        if (!is_allowed(url)) {
            werror("Blocked by robots.txt: %s\n", url);
            return 0;
        }

        throttle();

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(
            url,
            ([
                "User-Agent": user_agent,
                "From": "bot@example.com"
            ])
        );

        return q;
    }

    // Fetch multiple URLs with concurrency control
    array(Protocols.HTTP.Query) fetch_multiple(array(string) urls, int|void max_concurrent)
    {
        max_concurrent = max_concurrent || 5;
        array(Protocols.HTTP.Query) results = ({});
        int completed = 0;

        foreach(urls; int i; string url) {
            // Wait for available slot
            while (completed - sizeof(results) >= max_concurrent) {
                sleep(1);
            }

            // Fetch URL
            Protocols.HTTP.Query q = fetch(url);
            results += ({ q });
            completed++;

            write("Progress: %d/%d\n", completed, sizeof(urls));
        }

        return results;
    }
}

int main(int argc, array(string) argv)
{
    write("=== Polite Crawler Example ===\n\n");

    if (argc < 2) {
        werror("Usage: %s <url> [requests_per_second]\n", argv[0]);
        return 1;
    }

    string url = argv[1];
    int rps = 2;

    if (argc > 2) {
        rps = (int)argv[2];
    }

    PoliteCrawler crawler = PoliteCrawler(rps);

    write("Crawler settings:\n");
    write("  Rate: %d requests/second\n", rps);
    write("  Delay: %.2f seconds\n", 1.0 / rps);
    write("  User-Agent: %s\n", "PikeBot/1.0");

    // Check robots.txt
    write("\nChecking robots.txt...\n");
    mapping rules = crawler->fetch_robots_txt(url);

    if (rules->disallowed) {
        write("Disallowed paths:\n");
        foreach(rules->disallowed, string path) {
            write("  - %s\n", path);
        }
    } else {
        write("  No restrictions found\n");
    }

    // Fetch URL
    write("\nFetching URL...\n");
    Protocols.HTTP.Query q = crawler->fetch(url);

    if (q) {
        if (q->status == 200) {
            write("  ✓ Success: %d bytes\n", sizeof(q->data()));
        } else {
            write("  ✗ Status: %d\n", q->status);
        }
    }

    // Fetch multiple URLs
    if (argc > 3) {
        array(string) urls = argv[3..];
        write("\nFetching %d URLs...\n", sizeof(urls));
        array results = crawler->fetch_multiple(urls, 2);
        write("Completed: %d URLs\n", sizeof(results));
    }

    return 0;
}
