#!/usr/bin/env pike
#pragma strict_types
// Basic HTML parsing with Standards.XML

int main()
{
    // Fetch and parse HTML
    string url = "https://example.com";
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    if (q->status != 200) {
        werror("Failed to fetch: %d\n", q->status);
        return 1;
    }

    // Parse HTML using Standards.XML
    // Note: HTML5 has Parser module if available
    string html = q->data();

    // Simple extraction using regex (for basic cases)
    array(string) titles = ({});
    string pattern = "<title>([^<]*)</title>";

    object re = Regexp.SimpleRegexp(pattern);
    array(string) matches = re->split(html);

    if (sizeof(matches) > 1) {
        write("Page Title: %s\n", matches[1]);
    }

    // Extract all links
    write("\n--- Links Found ---\n");
    pattern = "<a\\s+href=\"([^\"]+)\"[^>]*>([^<]*)</a>";
    re = Regexp.SimpleRegexp(pattern);
    int match_count;

    void scan_links(string s) {
        while (1) {
            array(string) parts = re->split(s);
            if (!parts || sizeof(parts) < 3) break;

            write("  %s -> %s\n", parts[2], parts[1]);
            match_count++;

            // Continue from after this match
            int pos = search(s, parts[0]) + sizeof(parts[0]);
            if (pos >= sizeof(s)) break;
            s = s[pos..];
        }
    };

    scan_links(html);
    write("Total links: %d\n", match_count);

    return 0;
}
