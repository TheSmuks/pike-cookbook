#!/usr/bin/env pike
#pragma strict_types
// Focused site scraper for structured data extraction

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
        object re = Regexp.PCRE.Simple(
            "<div\\s+class=['\"]product['\"][^>]*>(.*?)</div>",
            ["DOTALL", " MULTILINE"]
        );

        int pos = 0;
        while (pos < sizeof(html)) {
            array(string) match = re->match(html, pos);
            if (!match) break;

            string product_html = match[1];

            // Extract product details
            mapping product = extract_product_data(product_html);

            if (sizeof(product)) {
                products += ({ product });
            }

            pos = html->search(match[0], pos) + sizeof(match[0]);
        }

        return products;
    }

    // Extract product data from HTML
    mapping extract_product_data(string html)
    {
        mapping product = ([]);

        // Extract title
        object title_re = Regexp.PCRE.Simple("<h3[^>]*>([^<]+)</h3>");
        array(string) title_match = title_re->match(html);
        if (title_match && sizeof(title_match) > 1) {
            product->title = title_match[1];
        }

        // Extract price
        object price_re = Regexp.PCRE.Simple("[$€£]([\\d,]+\\.?\\d*)");
        array(string) price_match = price_re->match(html);
        if (price_match && sizeof(price_match) > 1) {
            product->price = price_match[1];
        }

        // Extract URL
        object url_re = Regexp.PCRE.Simple("href=['\"]([^'\"]+)['\"]");
        array(string) url_match = url_re->match(html);
        if (url_match && sizeof(url_match) > 1) {
            product->url = url_match[1];

            // Convert to absolute URL if needed
            if (has_prefix(product->url, "/")) {
                Standards.URI base_uri = Standards.URI(base_url);
                product->url = sprintf("%s://%s%s",
                                      base_uri->scheme, base_uri->host, product->url);
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
            object re = Regexp.PCRE.Simple(pattern, ["DOTALL"]);
            int pos = 0;

            while (pos < sizeof(html)) {
                array(string) match = re->match(html, pos);
                if (!match) break;

                mapping article = extract_article_data(match[1]);

                if (sizeof(article)) {
                    articles += ({ article });
                }

                pos = html->search(match[0], pos) + sizeof(match[0]);
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
            object re = Regexp.PCRE.Simple(pattern);
            array(string) match = re->match(html);

            if (match && sizeof(match) > 1) {
                article->title = match[1];
                break;
            }
        }

        // Extract link
        object url_re = Regexp.PCRE.Simple("<a\\s+href=['\"]([^'\"]+)['\"]");
        array(string) url_match = url_re->match(html);
        if (url_match && sizeof(url_match) > 1) {
            article->url = url_match[1];
        }

        // Extract excerpt
        object p_re = Regexp.PCRE.Simple("<p[^>]*>([^<]+)</p>");
        array(string) p_match = p_re->match(html);
        if (p_match && sizeof(p_match) > 1) {
            article->excerpt = p_match[1];
        }

        // Extract date if present
        object date_re = Regexp.PCRE.Simple("(?:datetime|date)['\"]?:['\"]?([^'\"<]+)");
        array(string) date_match = date_re->match(html);
        if (date_match && sizeof(date_match) > 1) {
            article->date = date_match[1];
        }

        return article;
    }

    // Scrape with custom extraction rules
    array(mapping) scrape_custom(function extractor, string|void url)
    {
        string target_url = url || base_url;
        Protocols.HTTP.Query q = crawler->fetch(target_url);

        if (!q || q->status != 200) {
            werror("Failed to fetch page\n");
            return ({});
        }

        return extractor(q->data());
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
            write("  %s\n", item->title || item->name || "Untitled");
            if (item->price) {
                write("    Price: %s\n", item->price);
            }
            if (item->url) {
                write("    URL: %s\n", item->url);
            }
            if (item->excerpt) {
                write("    Excerpt: %s\n", item->excerpt[0..100] + "...");
            }
            write("\n");
        }

        // Save to JSON
        string output = Standards.JSON.encode_pretty(results);
        string filename = "scraped_" + type + ".json";
        Stdio.write_file(filename, output);
        write("Results saved to: %s\n", filename);
    } else {
        write("No results found. Try adjusting the extraction patterns.\n");
    }

    return 0;
}
