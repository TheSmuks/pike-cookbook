#!/usr/bin/env pike
#pragma strict_types
// Advanced CSS selector-like extraction from HTML

class CSSSelector
{
    // Parse selector and match elements
    public array(object) select(string selector, object root)
    {
        array(object) results = ({});

        // Parse selector: tag.class#id, multiple selectors
        array(string) parts = selector / ",";

        foreach(parts, string part) {
            string tag = "*";
            string class_name = "";
            string id = "";

            // Parse tag#id.class
            string sel = part - " " - "\t" - "\n" - "\r";

            // Extract ID
            int id_pos = search(sel, "#");
            if (id_pos != -1) {
                int end_pos = search(sel, ".", id_pos);
                if (end_pos == -1) end_pos = sizeof(sel);

                id = sel[id_pos + 1..end_pos - 1];
                sel = sel[0..id_pos - 1] + sel[end_pos..];
            }

            // Extract class
            int class_pos = search(sel, ".");
            if (class_pos != -1) {
                int end_pos = search(sel, "#", class_pos);
                if (end_pos == -1) end_pos = sizeof(sel);

                class_name = sel[class_pos + 1..end_pos - 1];
                sel = sel[0..class_pos - 1] + sel[end_pos..];
            }

            // Remaining is tag name
            if (sizeof(sel) && sel != "") {
                tag = sel;
            }

            // Find matching elements
            array(object) matched = find_elements(root, tag, class_name, id);
            results += matched;
        }

        return results;
    }

    // Find elements by tag, class, and ID
    private array(object) find_elements(object node,
                                       string tag, string class_name, string id)
    {
        array(object) results = ({});

        void check(object n) {
            // Check tag name
            mixed tag_name_result = n->get_tag_name();

            // Check attributes
            mixed attrs_result = n->get_attributes();
            if (mappingp(attrs_result)) {
                mapping attrs = (mapping)attrs_result;
                int matches_tag = (tag == "*") || (stringp(tag_name_result) && tag_name_result == tag);
                mixed id_val = attrs->id;
                mixed class_val = attrs->class;
                int matches_id = !sizeof(id) || (stringp(id_val) && id_val == id);
                int matches_class = !sizeof(class_name) || (stringp(class_val) && class_val == class_name);

                if (matches_tag && matches_id && matches_class) {
                    results += ({ n });
                }
            }

            // Recurse into children
            mixed children_result = n->get_children();
            if (arrayp(children_result)) {
                foreach((array)children_result, mixed child) {
                    if (objectp(child)) {
                        check((object)child);
                    }
                }
            }
        };

        check(node);
        return results;
    }

    // Get element by ID
    public object get_by_id(object root, string id)
    {
        array(object) results = select("#" + id, root);
        return sizeof(results) ? results[0] : 0;
    }

    // Get elements by class
    public array(object) get_by_class(object root, string class_name)
    {
        return select("." + class_name, root);
    }

    // Get text content of matched elements
    public array(string) get_text(string selector, object root)
    {
        array(object) elements = select(selector, root);
        array(string) texts = ({});
        foreach(elements, object n) {
            mixed text = n->get_text();
            texts += ({ stringp(text) ? (string)text : "" });
        }
        return texts;
    }
}

int main()
{
    string html = #"
    <html>
    <body>
        <div id='header' class='container'>
            <h1 class='title'>Main Title</h1>
            <nav class='navigation'>
                <a href='/home'>Home</a>
                <a href='/about'>About</a>
            </nav>
        </div>
        <div id='content' class='container main'>
            <article class='post'>
                <h2 class='title'>Post Title</h2>
                <p class='text'>First paragraph</p>
                <p class='text'>Second paragraph</p>
            </article>
            <aside class='sidebar'>
                <p>Sidebar content</p>
            </aside>
        </div>
        <footer id='footer' class='container'>
            <p>Footer text</p>
        </footer>
    </body>
    </html>
    ";

    object xml_root = Parser.XML.Tree.parse_input(html);
    mixed root_mixed = xml_root->get_children();
    if (!arrayp(root_mixed) || !sizeof((array)root_mixed)) {
        werror("No root element\n");
        return 1;
    }
    object root = (object)((array)root_mixed)[0];

    CSSSelector selector = CSSSelector();

    write("=== CSS Selector Examples ===\n\n");

    // Example 1: Select by ID
    write("1. Select by ID (#header)\n");
    array(object) results = selector->select("#header", root);
    write("   Found: %d element(s)\n", sizeof(results));

    // Example 2: Select by class
    write("\n2. Select by class (.container)\n");
    results = selector->select(".container", root);
    write("   Found: %d element(s)\n", sizeof(results));

    // Example 3: Select by tag
    write("\n3. Select by tag (h2)\n");
    results = selector->select("h2", root);
    write("   Found: %d element(s)\n", sizeof(results));
    foreach(results, object n) {
        mixed text = n->get_text();
        write("   - %s\n", stringp(text) ? (string)text : "");
    }

    // Example 4: Select by tag.class
    write("\n4. Select by tag.class (p.text)\n");
    results = selector->select("p.text", root);
    write("   Found: %d element(s)\n", sizeof(results));
    foreach(results, object n) {
        mixed text = n->get_text();
        write("   - %s\n", stringp(text) ? (string)text : "");
    }

    // Example 5: Select by tag#id
    write("\n5. Select by tag#id (div#content)\n");
    results = selector->select("div#content", root);
    write("   Found: %d element(s)\n", sizeof(results));

    // Example 6: Multiple selectors
    write("\n6. Multiple selectors (h1, h2)\n");
    results = selector->select("h1, h2", root);
    write("   Found: %d element(s)\n", sizeof(results));
    foreach(results, object n) {
        mixed tag = n->get_tag_name();
        mixed text = n->get_text();
        write("   - %s: %s\n", stringp(tag) ? (string)tag : "?",
                            stringp(text) ? (string)text : "");
    }

    // Example 7: Get text content
    write("\n7. Get text content (.title)\n");
    array(string) texts = selector->get_text(".title", root);
    foreach(texts, string text) {
        write("   - %s\n", text);
    }

    return 0;
}
