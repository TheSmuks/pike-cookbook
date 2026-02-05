#!/usr/bin/env pike
#pragma strict_types
// XPath-like queries for precise data extraction

class XPathEngine
{
    static Parser.XML.Tree.Node root;

    void create(Parser.XML.Tree.Node r)
    {
        root = r;
    }

    // Execute XPath-like query
    array(Parser.XML.Tree.Node) query(string xpath)
    {
        // Support basic XPath: //tag, /root/tag, tag[@attr='value'], tag[text()='value']
        array(Parser.XML.Tree.Node) results = ({});

        // Absolute path
        if (has_prefix(xpath, "/")) {
            results = evaluate_absolute(xpath);
        }
        // Relative path (//)
        else if (has_prefix(xpath, "//")) {
            string tag = xpath[2..];
            results = find_all_by_tag(tag);
        }
        // Simple tag name
        else {
            results = find_by_tag(root, xpath);
        }

        return results;
    }

    // Evaluate absolute path
    static array(Parser.XML.Tree.Node) evaluate_absolute(string path)
    {
        array(string) parts = path / "/";
        parts -= ({""});  // Remove empty strings

        array(Parser.XML.Tree.Node) current = ({ root });

        foreach(parts, string part) {
            array(Parser.XML.Tree.Node) next = ({});

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

            foreach(current, Parser.XML.Tree.Node node) {
                array(Parser.XML.Tree.Node) children = node->get_elements(tag);

                foreach(children, Parser.XML.Tree.Node child) {
                    if (sizeof(attr_name)) {
                        if (attr_name == "text()") {
                            if (child->get_text() == attr_value) {
                                next += ({ child });
                            }
                        } else {
                            mapping attrs = child->get_attributes();
                            if (attrs && attrs[attr_name] == attr_value) {
                                next += ({ child });
                            }
                        }
                    } else {
                        next += ({ child });
                    }
                }
            }

            current = next;
            if (!sizeof(current)) break;
        }

        return current;
    }

    // Find all elements by tag name recursively
    static array(Parser.XML.Tree.Node) find_all_by_tag(string tag)
    {
        array(Parser.XML.Tree.Node) results = ({});

        void recurse(Parser.XML.Tree.Node node) {
            if (!objectp(node)) return;

            if (node->get_tag_name() == tag) {
                results += ({ node });
            }

            foreach(node->get_children(), mixed child) {
                if (objectp(child)) {
                    recurse(child);
                }
            }
        };

        recurse(root);
        return results;
    }

    // Find by tag name (direct children only)
    static array(Parser.XML.Tree.Node) find_by_tag(Parser.XML.Tree.Node node, string tag)
    {
        return node->get_elements(tag);
    }

    // Get parent of element
    static Parser.XML.Tree.Node get_parent(Parser.XML.Tree.Node node)
    {
        // Would need to track parent during traversal
        return 0;
    }

    // Get siblings
    static array(Parser.XML.Tree.Node) get_siblings(Parser.XML.Tree.Node node)
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

    Parser.XML.Tree.RootNode xml_root = Parser.XML.Tree.parse_input(html);
    Parser.XML.Tree.Node root = xml_root->get_children()[0];
    XPathEngine xpath = XPathEngine(root);

    write("=== XPath Examples ===\n\n");

    // Example 1: //p - all paragraphs
    write("1. Query: //p (all paragraphs)\n");
    array(Parser.XML.Tree.Node) results = xpath->query("//p");
    write("   Results: %d\n", sizeof(results));
    foreach(results, Parser.XML.Tree.Node n) {
        write("   - %s\n", n->get_text());
    }

    // Example 2: //p[@class='highlight']
    write("\n2. Query: //p[@class='highlight']\n");
    results = xpath->query("//p[@class='highlight']");
    write("   Results: %d\n", sizeof(results));
    foreach(results, Parser.XML.Tree.Node n) {
        write("   - %s\n", n->get_text());
    }

    // Example 3: /html/body/div
    write("\n3. Query: /html/body/div\n");
    results = xpath->query("/html/body/div");
    write("   Results: %d\n", sizeof(results));
    foreach(results, Parser.XML.Tree.Node n) {
        mapping attrs = n->get_attributes();
        write("   - div id=%s\n", attrs->id || "none");
    }

    // Example 4: //div[@id='intro']/p
    write("\n4. Complex: //div[@id='intro']//p\n");
    // Note: Full implementation would support nested queries
    results = xpath->query("//p");  // Simplified
    write("   Results: %d paragraphs total\n", sizeof(results));

    return 0;
}
