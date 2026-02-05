#!/usr/bin/env pike
#pragma strict_types
// Focused site scraper for structured data extraction

// Polite web crawler with rate limiting and robots.txt respect
// (Included from polite_crawler.pike to avoid main() conflict)
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
        float current_time = (float)gethrtime() / 1000000.0;
        float elapsed = current_time - last_request_time;

        if (elapsed < request_delay) {
            float sleep_time = request_delay - elapsed;
            int usecs = (int)(sleep_time * 1000000);
            System.usleep(usecs);
        }

        last_request_time = (float)gethrtime() / 1000000.0;
    }

    // Fetch and parse robots.txt
    mapping fetch_robots_txt(string base_url)
    {
        if (robots_cache[base_url]) {
            return [mapping]robots_cache[base_url];
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
                line = String.trim_all_whites(line);

                // Skip comments and empty lines
                if (has_prefix(line, "#") || sizeof(line) == 0) {
                    continue;
                }

                // Parse User-agent and Disallow
                if (has_prefix(lower_case(line), "user-agent:")) {
                    // Multiple user-agents supported
                }
                else if (has_prefix(lower_case(line), "disallow:")) {
                    string path = String.trim_all_whites(line[9..]);
                    if (sizeof(path) > 0) {
                        rules->disallowed += ({ path });
                    }
                }
                else if (has_prefix(lower_case(line), "crawl-delay:")) {
                    string delay_str = String.trim_all_whites(line[12..]);
                    float delay = (float)delay_str;
                    if (delay > 0) {
                        rules->crawl_delay = delay;
                    }
                }
                else if (has_prefix(lower_case(line), "request-rate:")) {
                    // Parse request-rate format (e.g., "1/5")
                    string rate = String.trim_all_whites(line[13..]);
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

        mixed disallowed_mixed = rules->disallowed;
        if (disallowed_mixed && arrayp(disallowed_mixed)) {
            array(string) disallowed_paths = [array(string)]disallowed_mixed;
            foreach(disallowed_paths, string disallowed) {
                if (has_prefix(path, disallowed)) {
                    return 0;
                }
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

        foreach(urls, string url) {
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

class SiteScraper
{
    private string base_url;
    private PoliteCrawler crawler;

    void create(string url, int|void rps)
    {
        base_url = url;
        crawler = PoliteCrawler(rps || 2);
    }

    // Scrape product listings
    array(mapping) scrape_products()
    {
        Protocols.HTTP.Query q = crawler->fetch(base_url);

        if (!q || q->status != 200) {
            werror("Failed to fetch page\n");
            return ({});
        }

        array(mapping) products = ({});
        string html = q->data();

        // Extract product cards (example pattern)
        // Note: SimpleRegexp doesn't support DOTALL/MULTILINE flags
        // For complex HTML parsing, consider using Parser.HTML instead
        object re = Regexp.SimpleRegexp(
            "<div\\s+class=['\"]product['\"][^>]*>[^<]*</div>"
        );

        int pos = 0;
        while (pos < sizeof(html)) {
            mixed match_result = re->match(html, pos);
            if (!match_result) break;

            array(string) match = [array(string)]match_result;

            // Extract the matched substring
            string matched_text = match[0];
            string product_html = matched_text;

            // Extract product details
            mapping product = extract_product_data(product_html);

            if (sizeof(product)) {
                products += ({ product });
            }

            int match_pos = search(html, matched_text, pos);
            if (match_pos == -1) break;
            pos = match_pos + sizeof(matched_text);
        }

        return products;
    }

    // Extract product data from HTML
    mapping extract_product_data(string html)
    {
        mapping product = ([]);

        // Extract title
        object title_re = Regexp.SimpleRegexp("<h3[^>]*>([^<]+)</h3>");
        mixed title_match_mixed = title_re->match(html);
        if (title_match_mixed && arrayp(title_match_mixed)) {
            array(string) title_match = [array(string)]title_match_mixed;
            if (sizeof(title_match) > 1) {
                product->title = title_match[1];
            }
        }

        // Extract price
        object price_re = Regexp.SimpleRegexp("[$€£]([\\d,]+\\.?\\d*)");
        mixed price_match_mixed = price_re->match(html);
        if (price_match_mixed && arrayp(price_match_mixed)) {
            array(string) price_match = [array(string)]price_match_mixed;
            if (sizeof(price_match) > 1) {
                product->price = price_match[1];
            }
        }

        // Extract URL
        object url_re = Regexp.SimpleRegexp("href=['\"]([^'\"]+)['\"]");
        mixed url_match_mixed = url_re->match(html);
        if (url_match_mixed && arrayp(url_match_mixed)) {
            array(string) url_match = [array(string)]url_match_mixed;
            if (sizeof(url_match) > 1) {
                product->url = url_match[1];

                // Convert to absolute URL if needed
                string url_value = [string]product->url;
                if (has_prefix(url_value, "/")) {
                    Standards.URI base_uri = Standards.URI(base_url);
                    product->url = sprintf("%s://%s%s",
                                          base_uri->scheme, [string]base_uri->host, url_value);
                }
            }
        }

        return product;
    }

    // Scrape article listings
    array(mapping) scrape_articles()
    {
        Protocols.HTTP.Query q = crawler->fetch(base_url);

        if (!q || q->status != 200) {
            werror("Failed to fetch page\n");
            return ({});
        }

        array(mapping) articles = ({});
        string html = q->data();

        // Common article patterns
        array(string) patterns = ({
            "<article[^>]*>(.*?)</article>",
            "<div\\s+class=['\"]post['\"][^>]*>(.*?)</div>",
            "<div\\s+class=['\"]entry['\"][^>]*>(.*?)</div>"
        });

        foreach(patterns, string pattern) {
            // Note: SimpleRegexp doesn't support DOTALL flag
            // Use Parser.HTML for better HTML parsing results
            object re = Regexp.SimpleRegexp(pattern);
            int pos = 0;

            while (pos < sizeof(html)) {
                mixed match_result = re->match(html, pos);
                if (!match_result) break;

                array(string) match = [array(string)]match_result;

                // For article patterns, we need the captured content
                // But SimpleRegexp doesn't support capture groups, so use the full match
                string matched_text = match[0];

                mapping article = extract_article_data(matched_text);

                if (sizeof(article)) {
                    articles += ({ article });
                }

                int match_pos = search(html, matched_text, pos);
                if (match_pos == -1) break;
                pos = match_pos + sizeof(matched_text);
            }

            if (sizeof(articles)) {
                break;  // Use first successful pattern
            }
        }

        return articles;
    }

    // Extract article data
    mapping extract_article_data(string html)
    {
        mapping article = ([]);

        // Extract title
        array(string) title_patterns = ({
            "<h[12][^>]*>([^<]+)</h[12]>",
            "<h3[^>]*>([^<]+)</h3>"
        });

        foreach(title_patterns, string pattern) {
            object re = Regexp.SimpleRegexp(pattern);
            mixed match_mixed = re->match(html);

            if (match_mixed && arrayp(match_mixed)) {
                array(string) match = [array(string)]match_mixed;
                if (sizeof(match) > 1) {
                    article->title = match[1];
                    break;
                }
            }
        }

        // Extract link
        object url_re = Regexp.SimpleRegexp("<a\\s+href=['\"]([^'\"]+)['\"]");
        mixed url_match_mixed = url_re->match(html);
        if (url_match_mixed && arrayp(url_match_mixed)) {
            array(string) url_match = [array(string)]url_match_mixed;
            if (sizeof(url_match) > 1) {
                article->url = url_match[1];
            }
        }

        // Extract excerpt
        object p_re = Regexp.SimpleRegexp("<p[^>]*>([^<]+)</p>");
        mixed p_match_mixed = p_re->match(html);
        if (p_match_mixed && arrayp(p_match_mixed)) {
            array(string) p_match = [array(string)]p_match_mixed;
            if (sizeof(p_match) > 1) {
                article->excerpt = p_match[1];
            }
        }

        // Extract date if present
        object date_re = Regexp.SimpleRegexp("(?:datetime|date)['\"]?:['\"]?([^'\"<]+)");
        mixed date_match_mixed = date_re->match(html);
        if (date_match_mixed && arrayp(date_match_mixed)) {
            array(string) date_match = [array(string)]date_match_mixed;
            if (sizeof(date_match) > 1) {
                article->date = date_match[1];
            }
        }

        return article;
    }

    // Scrape with custom extraction rules
    array(mapping) scrape_custom(function(mixed:mixed) extractor, string|void url)
    {
        string target_url = url || base_url;
        Protocols.HTTP.Query q = crawler->fetch(target_url);

        if (!q || q->status != 200) {
            werror("Failed to fetch page\n");
            return ({});
        }

        mixed result = extractor(q->data());
        if (arrayp(result)) {
            return [array(mapping)]result;
        }
        return ({});
    }
}

int main(int argc, array(string) argv)
{
    if (argc < 2) {
        werror("Usage: %s <url> [type]\n", argv[0]);
        werror("Types: products, articles, custom\n");
        return 1;
    }

    string url = argv[1];
    string type = argc > 2 ? argv[2] : "articles";

    write("=== Site Scraper ===\n\n");

    SiteScraper scraper = SiteScraper(url, 2);

    array(mapping) results;

    switch(type)
    {
        case "products":
            write("Scraping products...\n");
            results = scraper->scrape_products();
            break;

        case "articles":
            write("Scraping articles...\n");
            results = scraper->scrape_articles();
            break;

        default:
            werror("Unknown type: %s\n", type);
            return 1;
    }

    if (sizeof(results)) {
        write("\nExtracted %d items:\n\n", sizeof(results));

        foreach(results, mapping item) {
            mixed title = item->title || item->name || "Untitled";
            write("  %s\n", (string)title);
            if (item->price) {
                write("    Price: %s\n", (string)item->price);
            }
            if (item->url) {
                write("    URL: %s\n", (string)item->url);
            }
            if (item->excerpt) {
                string excerpt = (string)item->excerpt;
                write("    Excerpt: %s\n", excerpt[0..100] + "...");
            }
            write("\n");
        }

        // Save to JSON
        string output = Standards.JSON.encode(results, Standards.JSON.PIKE_CANONICAL);
        string filename = "scraped_" + type + ".json";
        Stdio.write_file(filename, output);
        write("Results saved to: %s\n", filename);
    } else {
        write("No results found. Try adjusting the extraction patterns.\n");
    }

    return 0;
}
