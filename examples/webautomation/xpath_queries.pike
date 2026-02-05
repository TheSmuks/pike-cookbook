#!/usr/bin/env pike
#pragma strict_types
// XPath-like queries on parsed XML/HTML

// Simple XPath-like navigation helper
class XPathHelper
{
    static Parser.XML.Tree.Node root;

    void create(Parser.XML.Tree.Node r) {
        root = r;
    }

    // Find elements by tag name recursively
    array(Parser.XML.Tree.Node) find_by_tag(string tag_name, Parser.XML.Tree.Node|void node)
    {
        node = node || root;
        array(Parser.XML.Tree.Node) results = ({});

        // Check current node
        if (node->get_tag_name() == tag_name) {
            results += ({ node });
        }

        // Recursively search children
        foreach(node->get_children(), Parser.XML.Tree.Node child) {
            if (objectp(child)) {
                results += find_by_tag(tag_name, child);
            }
        }

        return results;
    }

    // Find elements by attribute value
    array(Parser.XML.Tree.Node) find_by_attr(string attr, string value, Parser.XML.Tree.Node|void node)
    {
        node = node || root;
        array(Parser.XML.Tree.Node) results = ({});

        mapping attrs = node->get_attributes();
        if (attrs && attrs[attr] == value) {
            results += ({ node });
        }

        foreach(node->get_children(), Parser.XML.Tree.Node child) {
            if (objectp(child)) {
                results += find_by_attr(attr, value, child);
            }
        }

        return results;
    }

    // CSS selector-like: tag.class
    array(Parser.XML.Tree.Node) select(string selector, Parser.XML.Tree.Node|void node)
    {
        node = node || root;

        // Parse "tag.class" or just "tag" or just ".class"
        string tag = "*";
        string class = "";

        if (sscanf(selector, "%s.%s", tag, class) == 2) {
            // Both tag and class
        } else if (selector[0] == '.') {
            class = selector[1..];
        } else {
            tag = selector;
        }

        array(Parser.XML.Tree.Node) results = ({});
        array(Parser.XML.Tree.Node) candidates = find_by_tag(tag, node);

        foreach(candidates, Parser.XML.Tree.Node n) {
            mapping attrs = n->get_attributes();
            if (!class || (attrs && attrs["class"] == class)) {
                results += ({ n });
            }
        }

        return results;
    }
}

int main()
{
    string html = #"
    <html>
    <body>
        <div class='header'>
            <h1 class='title'>Main Title</h1>
        </div>
        <div class='content'>
            <p class='text'>First paragraph</p>
            <p>Second paragraph</p>
        </div>
    </body>
    </html>
    ";

    Parser.XML.Tree.RootNode xml_root = Parser.XML.Tree.parse_input(html);
    Parser.XML.Tree.Node root = xml_root->get_children()[0];
    XPathHelper xpath = XPathHelper(root);

    // Find all divs
    array(Parser.XML.Tree.Node) divs = xpath->find_by_tag("div");
    write("Found %d divs\n", sizeof(divs));

    // Find by class attribute
    array(Parser.XML.Tree.Node) titled = xpath->find_by_attr("class", "title");
    if (sizeof(titled)) {
        write("\nTitle element: %s\n", titled[0]->get_text());
    }

    // CSS selector-like: p.text
    array(Parser.XML.Tree.Node) texts = xpath->select("p.text");
    write("\nElements with class 'text':\n");
    foreach(texts, Parser.XML.Tree.Node n) {
        write("  %s: %s\n", n->get_tag_name(), n->get_text());
    }

    // All divs with class content
    array(Parser.XML.Tree.Node) content_divs = xpath->select("div.content");
    write("\nContent divs: %d\n", sizeof(content_divs));

    return 0;
}
