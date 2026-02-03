#!/usr/bin/env pike
#pragma strict_types
// XPath-like queries on parsed XML/HTML

// Simple XPath-like navigation helper
class XPathHelper
{
    static Standards.XML.Node root;

    void create(Standards.XML.Node r) {
        root = r;
    }

    // Find elements by tag name recursively
    array(Standards.XML.Node) find_by_tag(string tag_name, Standards.XML.Node|void node)
    {
        node = node || root;
        array(Standards.XML.Node) results = ({});

        // Check current node
        if (node->get_tag_name() == tag_name) {
            results += ({ node });
        }

        // Recursively search children
        foreach(node->get_children(), Standards.XML.Node child) {
            if (objectp(child)) {
                results += find_by_tag(tag_name, child);
            }
        }

        return results;
    }

    // Find elements by attribute value
    array(Standards.XML.Node) find_by_attr(string attr, string value, Standards.XML.Node|void node)
    {
        node = node || root;
        array(Standards.XML.Node) results = ({});

        mapping attrs = node->get_attributes();
        if (attrs && attrs[attr] == value) {
            results += ({ node });
        }

        foreach(node->get_children(), Standards.XML.Node child) {
            if (objectp(child)) {
                results += find_by_attr(attr, value, child);
            }
        }

        return results;
    }

    // CSS selector-like: tag.class
    array(Standards.XML.Node) select(string selector, Standards.XML.Node|void node)
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

        array(Standards.XML.Node) results = ({});
        array(Standards.XML.Node) candidates = find_by_tag(tag, node);

        foreach(candidates, Standards.XML.Node n) {
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

    Standards.XML.Node root = Standards.XML.parse(html);
    XPathHelper xpath = XPathHelper(root);

    // Find all divs
    array(Standards.XML.Node) divs = xpath->find_by_tag("div");
    write("Found %d divs\n", sizeof(divs));

    // Find by class attribute
    array(Standards.XML.Node) titled = xpath->find_by_attr("class", "title");
    if (sizeof(titled)) {
        write("\nTitle element: %s\n", titled[0]->get_text());
    }

    // CSS selector-like: p.text
    array(Standards.XML.Node) texts = xpath->select("p.text");
    write("\nElements with class 'text':\n");
    foreach(texts, Standards.XML.Node n) {
        write("  %s: %s\n", n->get_tag_name(), n->get_text());
    }

    // All divs with class content
    array(Standards.XML.Node) content_divs = xpath->select("div.content");
    write("\nContent divs: %d\n", sizeof(content_divs));

    return 0;
}
