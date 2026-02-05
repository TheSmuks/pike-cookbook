#!/usr/bin/env pike
#pragma strict_types
// RSS/Atom feed aggregator

class FeedAggregator
{
    private array(string) feed_urls = ({});

    void create(array(string) urls)
    {
        feed_urls = urls;
    }

    // Parse RSS feed
    array(mapping) parse_rss(string xml)
    {
        array(mapping) items = ({});

        Parser.XML.Tree.Node root = Parser.XML.Tree.parse_input(xml);

        // Get channel
        array(Parser.XML.Tree.Node) channels = root->get_elements("channel");
        if (!sizeof(channels)) {
            werror("No channel found in RSS feed\n");
            return items;
        }

        // Get items
        array(Parser.XML.Tree.Node) item_nodes = channels[0]->get_elements("item");

        foreach(item_nodes, Parser.XML.Tree.Node item) {
            mapping data = ([]);

            array(Parser.XML.Tree.Node) titles = item->get_elements("title");
            array(Parser.XML.Tree.Node) links = item->get_elements("link");
            array(Parser.XML.Tree.Node) descriptions = item->get_elements("description");
            array(Parser.XML.Tree.Node) pubs = item->get_elements("pubDate");
            array(Parser.XML.Tree.Node) guids = item->get_elements("guid");

            if (sizeof(titles)) data->title = titles[0]->get_text();
            if (sizeof(links)) data->link = links[0]->get_text();
            if (sizeof(descriptions)) data->description = descriptions[0]->get_text();
            if (sizeof(pubs)) data->pub_date = pubs[0]->get_text();
            if (sizeof(guids)) data->guid = guids[0]->get_text();

            items += ({ data });
        }

        return items;
    }

    // Parse Atom feed
    array(mapping) parse_atom(string xml)
    {
        array(mapping) items = ({});

        Parser.XML.Tree.Node root = Parser.XML.Tree.parse_input(xml);

        // Get entries
        array(Parser.XML.Tree.Node) entries = root->get_elements("entry");

        foreach(entries, Parser.XML.Tree.Node entry) {
            mapping data = ([]);

            array(Parser.XML.Tree.Node) titles = entry->get_elements("title");
            array(Parser.XML.Tree.Node) links = entry->get_elements("link");
            array(Parser.XML.Tree.Node) contents = entry->get_elements("content");
            array(Parser.XML.Tree.Node) summaries = entry->get_elements("summary");
            array(Parser.XML.Tree.Node) published = entry->get_elements("published");
            array(Parser.XML.Tree.Node) updated = entry->get_elements("updated");
            array(Parser.XML.Tree.Node) ids = entry->get_elements("id");

            if (sizeof(titles)) data->title = titles[0]->get_text();
            if (sizeof(links)) {
                mapping attrs = links[0]->get_attributes();
                data->link = attrs->href || links[0]->get_text();
            }
            if (sizeof(contents)) {
                data->content = contents[0]->get_text();
            } else if (sizeof(summaries)) {
                data->description = summaries[0]->get_text();
            }
            if (sizeof(published)) data->pub_date = published[0]->get_text();
            if (sizeof(updated)) data->updated = updated[0]->get_text();
            if (sizeof(ids)) data->guid = ids[0]->get_text();

            items += ({ data });
        }

        return items;
    }

    // Fetch and parse feed
    array(mapping) fetch_feed(string url)
    {
        write("Fetching feed: %s\n", url);

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(
            url,
            (["User-Agent": "Pike FeedAggregator/1.0"])
        );

        if (!q || q->status != 200) {
            werror("Failed to fetch feed: %s\n", url);
            return ({});
        }

        string xml = q->data();

        // Detect feed type
        if (has_value(lower_case(xml), "<rss") ||
            has_value(lower_case(xml), "<rdf:rdf")) {
            return parse_rss(xml);
        } else if (has_value(lower_case(xml), "<feed")) {
            return parse_atom(xml);
        } else {
            werror("Unknown feed format\n");
            return ({});
        }
    }

    // Aggregate all feeds
    array(mapping) aggregate()
    {
        array(mapping) all_items = ({});

        foreach(feed_urls, string url) {
            array(mapping) items = fetch_feed(url);

            // Add source to each item
            foreach(items, mapping item) {
                item->source_url = url;
                all_items += ({ item });
            }
        }

        // Sort by date (newest first)
        all_items = sort_items_by_date(all_items);

        return all_items;
    }

    // Sort items by date
    array(mapping) sort_items_by_date(array(mapping) items)
    {
        // Simple sort - would need proper date parsing for accuracy
        return items;  // Placeholder
    }

    // Filter items by keyword
    array(mapping) filter_by_keyword(array(mapping) items, string keyword)
    {
        string kw = lower_case(keyword);

        return filter(items, lambda(mapping item) {
            string title = lower_case(item->title || "");
            string desc = lower_case(item->description || item->content || "");

            return has_value(title, kw) || has_value(desc, kw);
        });
    }

    // Export to JSON
    string export_json(array(mapping) items)
    {
        return Standards.JSON.encode(items, Standards.JSON.PIKE_CANONICAL);
    }

    // Generate HTML summary
    string export_html(array(mapping) items)
    {
        array(string) lines = ({
            "<!DOCTYPE html>",
            "<html>",
            "<head><title>Feed Aggregator</title></head>",
            "<body>",
            "<h1>Feed Aggregator</h1>",
            sprintf("<p>%d items from %d feeds</p>",
                    sizeof(items), sizeof(feed_urls)),
            "<ul>"
        });

        foreach(items, mapping item) {
            string title = item->title || "Untitled";
            string link = item->link || "#";
            string desc = item->description || item->content || "";
            string source = item->source_url || "";

            // Strip HTML from description
            desc = Regexp.SimpleRegexp("<[^>]+>")->replace(desc, "");

            if (sizeof(desc) > 200) {
                desc = desc[0..200] + "...";
            }

            lines += ({
                sprintf("<li><strong><a href='%s'>%s</a></strong><br/>%s</li>",
                       link, title, desc)
            });
        }

        lines += ({"</ul>", "</body>", "</html>"});

        return lines * "\n";
    }
}

int main()
{
    write("=== Feed Aggregator ===\n\n");

    // Example feeds
    array(string) feeds = ({
        "https://feeds.feedburner.com/oreilly/radar",
        "https://rss.cnn.com/rss/edition.rss",
        // Add more feed URLs here
    });

    FeedAggregator aggregator = FeedAggregator(feeds);

    write("Fetching %d feeds...\n\n", sizeof(feeds));

    array(mapping) items = aggregator->aggregate();

    write("Total items: %d\n\n", sizeof(items));

    // Display recent items
    write("Recent items:\n");
    foreach(items[0..min(10, sizeof(items)) - 1], mapping item) {
        write("  - %s\n", item->title || "Untitled");
        if (item->link) {
            write("    %s\n", item->link);
        }
        write("\n");
    }

    // Save results
    string json_file = "feed_aggregation.json";
    Stdio.write_file(json_file, aggregator->export_json(items));
    write("JSON saved to: %s\n", json_file);

    string html_file = "feed_aggregation.html";
    Stdio.write_file(html_file, aggregator->export_html(items));
    write("HTML saved to: %s\n", html_file);

    return 0;
}
