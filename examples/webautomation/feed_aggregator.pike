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

        object root = Parser.XML.Tree.parse_input(xml);

        // Get channel
        mixed channels_mixed = root->get_elements("channel");
        if (!arrayp(channels_mixed) || !sizeof([array]channels_mixed)) {
            werror("No channel found in RSS feed\n");
            return items;
        }
        array channels = [array]channels_mixed;

        // Get items
        mixed channel_mixed = channels[0];
        if (!objectp(channel_mixed)) return items;
        object channel = [object]channel_mixed;
        mixed item_nodes_mixed = channel->get_elements("item");
        if (!arrayp(item_nodes_mixed)) {
            return items;
        }
        array item_nodes = [array]item_nodes_mixed;

        foreach(item_nodes, mixed item) {
            mapping data = ([]);

            // Cast to object before calling methods
            if (!objectp(item)) continue;
            object item_obj = [object]item;

            mixed titles_mixed = item_obj->get_elements("title");
            mixed links_mixed = item_obj->get_elements("link");
            mixed descriptions_mixed = item_obj->get_elements("description");
            mixed pubs_mixed = item_obj->get_elements("pubDate");
            mixed guids_mixed = item_obj->get_elements("guid");

            if (arrayp(titles_mixed) && sizeof([array]titles_mixed)) {
                array titles = [array]titles_mixed;
                object title_elem = [object]titles[0];
                data->title = title_elem->get_text();
            }
            if (arrayp(links_mixed) && sizeof([array]links_mixed)) {
                array links = [array]links_mixed;
                object link_elem = [object]links[0];
                data->link = link_elem->get_text();
            }
            if (arrayp(descriptions_mixed) && sizeof([array]descriptions_mixed)) {
                array descriptions = [array]descriptions_mixed;
                object desc_elem = [object]descriptions[0];
                data->description = desc_elem->get_text();
            }
            if (arrayp(pubs_mixed) && sizeof([array]pubs_mixed)) {
                array pubs = [array]pubs_mixed;
                object pub_elem = [object]pubs[0];
                data->pub_date = pub_elem->get_text();
            }
            if (arrayp(guids_mixed) && sizeof([array]guids_mixed)) {
                array guids = [array]guids_mixed;
                object guid_elem = [object]guids[0];
                data->guid = guid_elem->get_text();
            }

            items += ({ data });
        }

        return items;
    }

    // Parse Atom feed
    array(mapping) parse_atom(string xml)
    {
        array(mapping) items = ({});

        object root = Parser.XML.Tree.parse_input(xml);

        // Get entries
        mixed entries_mixed = root->get_elements("entry");
        if (!arrayp(entries_mixed)) {
            return items;
        }
        array entries = [array]entries_mixed;

        foreach(entries, mixed entry) {
            mapping data = ([]);

            // Cast to object before calling methods
            if (!objectp(entry)) continue;
            object entry_obj = [object]entry;

            mixed titles_mixed = entry_obj->get_elements("title");
            mixed links_mixed = entry_obj->get_elements("link");
            mixed contents_mixed = entry_obj->get_elements("content");
            mixed summaries_mixed = entry_obj->get_elements("summary");
            mixed published_mixed = entry_obj->get_elements("published");
            mixed updated_mixed = entry_obj->get_elements("updated");
            mixed ids_mixed = entry_obj->get_elements("id");

            if (arrayp(titles_mixed) && sizeof([array]titles_mixed)) {
                array titles = [array]titles_mixed;
                object title_elem = [object]titles[0];
                data->title = title_elem->get_text();
            }
            if (arrayp(links_mixed) && sizeof([array]links_mixed)) {
                array links = [array]links_mixed;
                object link_elem = [object]links[0];
                mixed attrs_mixed = link_elem->get_attributes();
                if (mappingp(attrs_mixed)) {
                    mapping attrs = [mapping]attrs_mixed;
                    if (stringp(attrs->href)) {
                        data->link = attrs->href;
                    }
                } else {
                    data->link = link_elem->get_text();
                }
            }
            if (arrayp(contents_mixed) && sizeof([array]contents_mixed)) {
                array contents = [array]contents_mixed;
                object content_elem = [object]contents[0];
                data->content = content_elem->get_text();
            } else if (arrayp(summaries_mixed) && sizeof([array]summaries_mixed)) {
                array summaries = [array]summaries_mixed;
                object summary_elem = [object]summaries[0];
                data->description = summary_elem->get_text();
            }
            if (arrayp(published_mixed) && sizeof([array]published_mixed)) {
                array published = [array]published_mixed;
                object pub_elem = [object]published[0];
                data->pub_date = pub_elem->get_text();
            }
            if (arrayp(updated_mixed) && sizeof([array]updated_mixed)) {
                array updated = [array]updated_mixed;
                object upd_elem = [object]updated[0];
                data->updated = upd_elem->get_text();
            }
            if (arrayp(ids_mixed) && sizeof([array]ids_mixed)) {
                array ids = [array]ids_mixed;
                object id_elem = [object]ids[0];
                data->guid = id_elem->get_text();
            }

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
            mixed title = item->title;
            mixed desc = item->description || item->content;
            string title_str = stringp(title) ? lower_case([string]title) : "";
            string desc_str = stringp(desc) ? lower_case([string]desc) : "";

            return has_value(title_str, kw) || has_value(desc_str, kw);
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
            mixed title = item->title;
            mixed link = item->link;
            mixed desc = item->description || item->content;

            string title_str = (stringp(title) && sizeof([string]title) > 0) ? [string]title : "Untitled";
            string link_str = stringp(link) ? [string]link : "#";
            string desc_str = stringp(desc) ? [string]desc : "";

            // Strip HTML from description
            desc_str = Regexp.SimpleRegexp("<[^>]+>")->replace(desc_str, "");

            if (sizeof(desc_str) > 200) {
                desc_str = desc_str[0..200] + "...";
            }

            lines += ({
                sprintf("<li><strong><a href='%s'>%s</a></strong><br/>%s</li>",
                       link_str, title_str, desc_str)
            });
        }

        lines += ({"</ul>", "</body>", "</html>"});

        return lines * "\n";
    }
}

int main()
{
    write("=== Feed Aggregator ===\n\n");

    // Example feeds - using reliable public feeds
    array(string) feeds = ({
        "https://feeds.feedburner.com/oreilly/radar",
        "https://rss.cnn.com/rss/edition.rss",
        // Add more feed URLs here
    });

    FeedAggregator aggregator = FeedAggregator(feeds);

    write("Fetching %d feeds...\n", sizeof(feeds));
    write("Note: This requires network access. Using demo mode if feeds fail.\n\n");

    array(mapping) items = ({});

    mixed err = catch {
        items = aggregator->aggregate();
    };

    if (err) {
        write("Network error - creating demo feed data instead...\n\n");
        // Create demo items for testing without network
        items = ({
            ([
                "title": "Demo Feed Item 1",
                "link": "https://example.com/1",
                "description": "This is a demo feed item for testing when network is unavailable.",
                "pub_date": "Mon, 01 Jan 2026 00:00:00 GMT",
                "source_url": "demo://local"
            ]),
            ([
                "title": "Demo Feed Item 2",
                "link": "https://example.com/2",
                "description": "Another demo item showing the feed aggregator functionality.",
                "pub_date": "Mon, 01 Jan 2026 01:00:00 GMT",
                "source_url": "demo://local"
            ])
        });
    }

    write("Total items: %d\n\n", sizeof(items));

    // Display recent items
    write("Recent items:\n");
    int count = min(10, sizeof(items));
    for (int i = 0; i < count; i++) {
        mapping item = items[i];
        mixed title = item->title;
        mixed link = item->link;
        string title_str = (stringp(title) && sizeof([string]title) > 0) ? [string]title : "Untitled";

        write("  - %s\n", title_str);
        if (stringp(link) && sizeof([string]link) > 0) {
            write("    %s\n", [string]link);
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
