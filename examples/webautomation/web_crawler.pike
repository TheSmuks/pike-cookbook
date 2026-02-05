#!/usr/bin/env pike
#pragma strict_types
// Complete web crawler with deduplication and depth control

class WebCrawler
{
    private string start_url;
    private int max_depth;
    private int max_pages;
    private PoliteCrawler crawler;
    private set(string) visited = (<>);
    private set(string) queued = (<>);
    private array(string) url_queue = ({});
    private mapping(string:mixed) results = ([]);
    private int pages_crawled = 0;

    void create(string url, int|void depth, int|void max_pg, int|void rps)
    {
        start_url = url;
        max_depth = depth || 3;
        max_pages = max_pg || 100;
        crawler = PoliteCrawler(rps || 2);
    }

    // Normalize URL for deduplication
    string normalize_url(string url)
    {
        // Remove fragment
        int frag_pos = search(url, "#");
        if (frag_pos != -1) {
            url = url[0..frag_pos - 1];
        }

        // Remove trailing slash (except for root)
        if (sizeof(url) > 1 && url[-1] == '/') {
            url = url[0..sizeof(url) - 2];
        }

        return lower_case(url);
    }

    // Check if URL should be crawled
    int should_crawl(string url, string base_url)
    {
        // Skip non-HTTP URLs
        if (!has_prefix(url, "http://") && !has_prefix(url, "https://")) {
            return 0;
        }

        // Skip common file extensions
        array(string) skip_exts = ({
            ".pdf", ".zip", ".exe", ".jpg", ".jpeg", ".png", ".gif",
            ".css", ".js", ".json", ".xml", ".svg", ".mp4", ".mp3"
        });

        foreach(skip_exts, string ext) {
            if (has_suffix(lower_case(url), ext)) {
                return 0;
            }
        }

        // Stay on same domain (basic check)
        Standards.URI base_uri = Standards.URI(base_url);
        Standards.URI url_uri = Standards.URI(url);

        if (url_uri->host != base_uri->host) {
            return 0;
        }

        return 1;
    }

    // Extract links from HTML
    array(string) extract_links(string html, string base_url)
    {
        array(string) links = ({});

        // Extract href attributes from <a> tags
        object re = Regexp.SimpleRegexp("<a\\s+[^>]*href=['\"]([^'\"]+)['\"]");

        int pos = 0;
        while (pos < sizeof(html)) {
            array(string) match = re->match(html, pos);
            if (!match) break;

            string href = match[1];

            // Convert relative URLs to absolute
            if (has_prefix(href, "/")) {
                Standards.URI base_uri = Standards.URI(base_url);
                href = sprintf("%s://%s%s", base_uri->scheme, base_uri->host, href);
            } else if (!has_prefix(href, "http://") && !has_prefix(href, "https://")) {
                // Relative path
                string base_path = base_url;
                int query_pos = search(base_path, "?");
                if (query_pos != -1) {
                    base_path = base_path[0..query_pos - 1];
                }

                // Remove filename from base path
                int last_slash = rsearch(base_path, "/");
                if (last_slash != -1) {
                    base_path = base_path[0..last_slash];
                }

                href = base_path + href;
            }

            links += ({ href });
            pos = html->search(match[0], pos) + sizeof(match[0]);
        }

        return links;
    }

    // Crawl single page
    mapping crawl_page(string url, int current_depth)
    {
        if (pages_crawled >= max_pages) {
            return 0;
        }

        string normalized = normalize_url(url);

        if (visited[normalized]) {
            return 0;
        }

        visited[normalized] = 1;
        pages_crawled++;

        write("[%d/%d] Crawling: %s (depth %d)\n",
              pages_crawled, max_pages, url, current_depth);

        Protocols.HTTP.Query q = crawler->fetch(url);

        if (!q || q->status != 200) {
            return ([
                "url": url,
                "status": q ? q->status : 0,
                "error": q ? "HTTP error" : "Network error"
            ]);
        }

        string html = q->data();
        array(string) links = extract_links(html, url);

        mapping result = ([
            "url": url,
            "status": q->status,
            "size": sizeof(html),
            "content_type": q->headers["content-type"] || "unknown",
            "links": links,
            "depth": current_depth
        ]);

        // Queue discovered links if not at max depth
        if (current_depth < max_depth) {
            foreach(links, string link) {
                string norm_link = normalize_url(link);

                if (!visited[norm_link] && !queued[norm_link] &&
                    should_crawl(link, start_url)) {
                    queued[norm_link] = 1;
                    url_queue += ({ link });
                }
            }
        }

        return result;
    }

    // Run crawler
    mapping(string:mixed) run()
    {
        write("=== Starting Web Crawler ===\n");
        write("Start URL: %s\n", start_url);
        write("Max depth: %d\n", max_depth);
        write("Max pages: %d\n", max_pages);
        write("\n");

        // Add start URL to queue with depth
        url_queue += ({ start_url });
        queued[normalize_url(start_url)] = 1;

        // Track depth for each URL
        mapping(string:int) url_depth = ([]);
        url_depth[start_url] = 0;

        // Crawl pages
        while (sizeof(url_queue) && pages_crawled < max_pages) {
            string url = url_queue[0];
            url_queue = url_queue[1..];

            int current_depth = url_depth[url] || 0;
            mapping result = crawl_page(url, current_depth);

            if (result) {
                results[url] = result;

                // Track depth for discovered links
                if (current_depth < max_depth && arrayp(result->links)) {
                    foreach(result->links, string link) {
                        string norm_link = normalize_url(link);
                        if (!url_depth[norm_link]) {
                            url_depth[norm_link] = current_depth + 1;
                        }
                    }
                }
            }
        }

        write("\n=== Crawl Complete ===\n");
        write("Pages crawled: %d\n", pages_crawled);
        write("Unique pages: %d\n", sizeof(results));

        return ([
            "start_url": start_url,
            "pages_crawled": pages_crawled,
            "results": results
        ]);
    }

    // Get crawl results
    mapping get_results()
    {
        return results;
    }

    // Export results to JSON
    string export_json()
    {
        return Standards.JSON.encode(results);
    }

    // Export results to CSV
    string export_csv()
    {
        array(string) lines = ({
            "URL,Status,Size,Content Type,Depth,Links"
        });

        foreach(results; string url; mapping data) {
            int link_count = arrayp(data->links) ? sizeof(data->links) : 0;
            lines += ({
                sprintf("\"%s\",%d,%d,\"%s\",%d,%d",
                       url, data->status, data->size,
                       data->content_type, data->depth, link_count)
            });
        }

        return lines * "\n";
    }
}

int main(int argc, array(string) argv)
{
    if (argc < 2) {
        werror("Usage: %s <url> [max_depth] [max_pages] [requests_per_second]\n", argv[0]);
        werror("Example: %s https://example.com 2 50 2\n", argv[0]);
        return 1;
    }

    string url = argv[1];
    int depth = argc > 2 ? (int)argv[2] : 3;
    int max_pages = argc > 3 ? (int)argv[3] : 100;
    int rps = argc > 4 ? (int)argv[4] : 2;

    WebCrawler crawler = WebCrawler(url, depth, max_pages, rps);
    mapping results = crawler->run();

    // Save results
    string output_file = "crawl_results.json";
    Stdio.write_file(output_file, crawler->export_json());
    write("\nResults saved to: %s\n", output_file);

    // Save CSV
    output_file = "crawl_results.csv";
    Stdio.write_file(output_file, crawler->export_csv());
    write("CSV saved to: %s\n", output_file);

    return 0;
}
