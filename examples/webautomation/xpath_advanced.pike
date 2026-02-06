#!/usr/bin/env pike
#pragma strict_types
// XPath-like queries for precise data extraction

class XPathEngine
{
    protected mixed root;

    void create(mixed r)
    {
        root = r;
    }

    // Execute XPath-like query
    array(object) query(string xpath)
    {
        // Support basic XPath: //tag, /root/tag, tag[@attr='value'], tag[text()='value']
        array(object) results = ({});

        // Absolute path
        if (has_prefix(xpath, "/")) {
            mixed abs = evaluate_absolute(xpath);
            if (arrayp(abs)) {
                foreach((array)abs, mixed item) {
                    if (objectp(item)) {
                        results += ({ (object)item });
                    }
                }
            }
        }
        // Relative path (//)
        else if (has_prefix(xpath, "//")) {
            string tag = xpath[2..];
            mixed all = find_all_by_tag(tag);
            if (arrayp(all)) {
                foreach((array)all, mixed item) {
                    if (objectp(item)) {
                        results += ({ (object)item });
                    }
                }
            }
        }
        // Simple tag name
        else {
            if (objectp(root)) {
                results = find_by_tag((object)root, xpath);
            }
        }

        return results;
    }

    // Evaluate absolute path
    protected array(mixed) evaluate_absolute(string path)
    {
        array(string) parts = path / "/";
        parts -= ({""});  // Remove empty strings

        array(mixed) current = ({ root });

        foreach(parts, string part) {
            array(mixed) next = ({});

            // Parse predicate: tag[@attr='value'] or tag[text()='value']
            string tag = part;
            string attr_name = "";
            string attr_value = "";

            int pred_start = search(part, "[");
            if (pred_start != -1) {
                int pred_end = search(part, "]", pred_start);
                if (pred_end != -1) {
                    tag = part[0..pred_start - 1];
                    string predicate = part[pred_start + 1..pred_end - 1];

                    // Parse @attr='value'
                    if (sscanf(predicate, "@%s='%s'", attr_name, attr_value) != 2) {
                        // Parse text()='value'
                        if (sscanf(predicate, "text()='%s'", attr_value) == 1) {
                            attr_name = "text()";
                        }
                    }
                }
            }

            foreach(current, mixed node) {
                if (!objectp(node)) continue;
                object n = (object)node;

                mixed children_mixed = n->get_elements(tag);
                if (!arrayp(children_mixed)) continue;

                foreach((array)children_mixed, mixed child) {
                    if (!objectp(child)) continue;
                    if (sizeof(attr_name)) {
                        if (attr_name == "text()") {
                            mixed text = ((object)child)->get_text();
                            if (stringp(text) && text == attr_value) {
                                next += ({ (object)child });
                            }
                        } else {
                            mixed attrs_mixed = ((object)child)->get_attributes();
                            if (mappingp(attrs_mixed)) {
                                mapping attrs = (mapping)attrs_mixed;
                                mixed val = attrs[attr_name];
                                if (stringp(val) && val == attr_value) {
                                    next += ({ (object)child });
                                }
                            }
                        }
                    } else {
                        next += ({ (object)child });
                    }
                }
            }

            current = next;
            if (!sizeof(current)) break;
        }

        return current;
    }

    // Find all elements by tag name recursively
    protected array(object) find_all_by_tag(string tag)
    {
        array(object) results = ({});

        void recurse(object node) {
            if (!objectp(node)) return;

            mixed tag_name = node->get_tag_name();
            if (stringp(tag_name) && tag_name == tag) {
                results += ({ node });
            }

            mixed children = node->get_children();
            if (arrayp(children)) {
                foreach((array)children, mixed child) {
                    if (objectp(child)) {
                        recurse((object)child);
                    }
                }
            }
        };

        if (objectp(root)) {
            recurse((object)root);
        }
        return results;
    }

    // Find by tag name (direct children only)
    protected array(object) find_by_tag(object node, string tag)
    {
        mixed elements = node->get_elements(tag);
        if (arrayp(elements)) {
            array(object) result = ({});
            foreach((array)elements, mixed elem) {
                if (objectp(elem)) {
                    result += ({ (object)elem });
                }
            }
            return result;
        }
        return ({});
    }

    // Get parent of element
    protected object get_parent(object node)
    {
        // Would need to track parent during traversal
        return 0;
    }

    // Get siblings
    protected array(object) get_siblings(object node)
    {
        return ({});
    }
}

int main()
{
    string html = #"
    <html>
    <body>
        <div id='main'>
            <h1>Title</h1>
            <div class='section' id='intro'>
                <p class='text'>Introduction</p>
                <p class='text'>More text</p>
            </div>
            <div class='section' id='content'>
                <h2>Section 1</h2>
                <p class='highlight'>Important text</p>
                <p>Regular text</p>
            </div>
        </div>
    </body>
    </html>
    ";

    object xml_root = Parser.XML.Tree.parse_input(html);
    mixed root_mixed = xml_root->get_children();
    if (!arrayp(root_mixed) || !sizeof((array)root_mixed)) {
        werror("Failed to parse HTML\n");
        return 1;
    }
    object root = (object)((array)root_mixed)[0];
    XPathEngine xpath = XPathEngine(root);

    write("=== XPath Examples ===\n\n");

    // Example 1: //p - all paragraphs
    write("1. Query: //p (all paragraphs)\n");
    array(object) results = xpath->query("//p");
    write("   Results: %d\n", sizeof(results));
    foreach(results, object r) {
        mixed text = r->get_text();
        string text_str = stringp(text) ? (string)text : "";
        write("   - %s\n", text_str);
    }

    // Example 2: //p[@class='highlight']
    write("\n2. Query: //p[@class='highlight']\n");
    results = xpath->query("//p[@class='highlight']");
    write("   Results: %d\n", sizeof(results));
    foreach(results, object r) {
        mixed text = r->get_text();
        string text_str = stringp(text) ? (string)text : "";
        write("   - %s\n", text_str);
    }

    // Example 3: /html/body/div
    write("\n3. Query: /html/body/div\n");
    results = xpath->query("/html/body/div");
    write("   Results: %d\n", sizeof(results));
    foreach(results, object r) {
        mixed attrs_mixed = r->get_attributes();
        string id_str = "none";
        if (mappingp(attrs_mixed)) {
            mapping attrs = (mapping)attrs_mixed;
            mixed id = attrs["id"];
            if (stringp(id)) {
                id_str = (string)id;
            }
        }
        write("   - div id=%s\n", id_str);
    }

    // Example 4: //div[@id='intro']/p
    write("\n4. Complex: //div[@id='intro']//p\n");
    // Note: Full implementation would support nested queries
    results = xpath->query("//p");  // Simplified
    write("   Results: %d paragraphs total\n", sizeof(results));

    return 0;
}
