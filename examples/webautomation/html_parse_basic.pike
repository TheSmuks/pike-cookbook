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
    string pattern = "<title>([^<]*)</title>";

    object re = Regexp.SimpleRegexp(pattern);
    mixed matches = re->split(html);

    if (arrayp(matches) && sizeof((array)matches) > 1) {
        array(string) match_array = (array(string))matches;
        write("Page Title: %s\n", match_array[1]);
    }

    // Extract all links
    write("\n--- Links Found ---\n");
    pattern = "<a\\s+href=\"([^\"]+)\"[^>]*>([^<]*)</a>";
    re = Regexp.SimpleRegexp(pattern);
    int match_count;

    void scan_links(string s) {
        while (1) {
            mixed parts = re->split(s);
            if (!arrayp(parts) || sizeof((array)parts) < 3) break;

            array(string) parts_array = (array(string))parts;
            write("  %s -> %s\n", parts_array[2], parts_array[1]);
            match_count++;

            // Continue from after this match
            int pos = search(s, parts_array[0]) + sizeof(parts_array[0]);
            if (pos >= sizeof(s)) break;
            s = s[pos..];
        }
    };

    scan_links(html);
    write("Total links: %d\n", match_count);

    return 0;
}
