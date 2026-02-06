#!/usr/bin/env pike
#pragma strict_types
// XPath-like queries on parsed XML/HTML

// Simple XPath-like navigation helper
class XPathHelper
{
    protected mixed root;

    void create(mixed r) {
        root = r;
    }

    // Find elements by tag name recursively
    array(object) find_by_tag(string tag_name, object|void node)
    {
        object n;
        if (node && objectp(node)) {
            n = (object)node;
        } else if (objectp(root)) {
            n = (object)root;
        } else {
            return ({});
        }

        array(object) results = ({});

        // Check current node
        mixed tag_name_result = n->get_tag_name();
        if (stringp(tag_name_result) && tag_name_result == tag_name) {
            results += ({ n });
        }

        // Recursively search children
        mixed children = n->get_children();
        if (arrayp(children)) {
            foreach((array)children, mixed child) {
                if (objectp(child)) {
                    results += find_by_tag(tag_name, (object)child);
                }
            }
        }

        return results;
    }

    // Find elements by attribute value
    array(object) find_by_attr(string attr, string value, object|void node)
    {
        object n;
        if (node && objectp(node)) {
            n = (object)node;
        } else if (objectp(root)) {
            n = (object)root;
        } else {
            return ({});
        }
        array(object) results = ({});

        mixed attrs_mixed = node->get_attributes();
        if (mappingp(attrs_mixed)) {
            mapping attrs = (mapping)attrs_mixed;
            mixed attr_val = attrs[attr];
            if (attr_val == value) {
                results += ({ node });
            }
        }

        mixed children = node->get_children();
        if (arrayp(children)) {
            foreach((array)children, mixed child) {
                if (objectp(child)) {
                    results += find_by_attr(attr, value, (object)child);
                }
            }
        }

        return results;
    }

    // CSS selector-like: tag.class
    array(object) select(string selector, mixed|void node)
    {
        node = node || root;

        // Parse "tag.class" or just "tag" or just ".class"
        string tag = "*";
        string class_name = "";

        if (sscanf(selector, "%s.%s", tag, class_name) == 2) {
            // Both tag and class
        } else if (selector[0] == '.') {
            class_name = selector[1..];
        } else {
            tag = selector;
        }

        array(object) results = ({});
        object node_obj;
        if (node && objectp(node)) {
            node_obj = (object)node;
        } else if (objectp(root)) {
            node_obj = (object)root;
        }
        if (!node_obj) return results;
        array(object) candidates = find_by_tag(tag, node_obj);

        foreach(candidates, object n) {
            mixed attrs_mixed = n->get_attributes();
            if (mappingp(attrs_mixed)) {
                mapping attrs = (mapping)attrs_mixed;
                if (!class_name || (attrs && attrs["class"] == class_name)) {
                    results += ({ n });
                }
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

    object xml_root = Parser.XML.Tree.parse_input(html);
    mixed root_mixed = xml_root->get_children();
    if (!arrayp(root_mixed) || !sizeof((array)root_mixed)) {
        werror("Failed to parse HTML\n");
        return 1;
    }
    object root = (object)((array)root_mixed)[0];
    XPathHelper xpath = XPathHelper(root);

    // Find all divs
    array(object) divs = xpath->find_by_tag("div");
    write("Found %d divs\n", sizeof(divs));

    // Find by class attribute
    array(object) titled = xpath->find_by_attr("class", "title");
    if (sizeof(titled)) {
        object title = (object)titled[0];
        mixed text = title->get_text();
        if (stringp(text)) {
            write("\nTitle element: %s\n", (string)text);
        }
    }

    // CSS selector-like: p.text
    array(object) texts = xpath->select("p.text");
    write("\nElements with class 'text':\n");
    foreach(texts, object txt) {
        mixed tag_name = txt->get_tag_name();
        mixed text = txt->get_text();
        string tag_str = stringp(tag_name) ? (string)tag_name : "unknown";
        string text_str = stringp(text) ? (string)text : "";
        write("  %s: %s\n", tag_str, text_str);
    }

    // All divs with class content
    array(object) content_divs = xpath->select("div.content");
    write("\nContent divs: %d\n", sizeof(content_divs));

    return 0;
}
