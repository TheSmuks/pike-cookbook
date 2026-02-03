#!/usr/bin/env pike
#pragma strict_types
// Advanced CSS selector-like extraction from HTML

class CSSSelector
{
    // Parse selector and match elements
    static array(Standards.XML.Node) select(string selector, Standards.XML.Node root)
    {
        array(Standards.XML.Node) results = ({});

        // Parse selector: tag.class#id, multiple selectors
        array(string) parts = selector / ",";

        foreach(parts, string part) {
            string tag = "*";
            string class_name = "";
            string id = "";

            // Parse tag#id.class
            string sel = String.trim_whitespace(part);

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
            array(Standards.XML.Node) matched = find_elements(root, tag, class_name, id);
            results += matched;
        }

        return results;
    }

    // Find elements by tag, class, and ID
    static array(Standards.XML.Node) find_elements(Standards.XML.Node node,
                                                     string tag, string class_name, string id)
    {
        array(Standards.XML.Node) results = ({});

        void check(Standards.XML.Node n) {
            if (!objectp(n)) return;

            // Check tag name
            if (tag != "*" && n->get_tag_name() != tag) {
                // Recurse anyway for children
            }

            // Check attributes
            mapping attrs = n->get_attributes();
            if (attrs) {
                int matches_tag = (tag == "*") || (n->get_tag_name() == tag);
                int matches_id = !sizeof(id) || (attrs->id == id);
                int matches_class = !sizeof(class_name) || (attrs->class == class_name);

                if (matches_tag && matches_id && matches_class) {
                    results += ({ n });
                }
            }

            // Recurse into children
            foreach(n->get_children(), mixed child) {
                if (objectp(child)) {
                    check(child);
                }
            }
        };

        check(node);
        return results;
    }

    // Get element by ID
    static Standards.XML.Node get_by_id(Standards.XML.Node root, string id)
    {
        array(Standards.XML.Node) results = select("#" + id, root);
        return sizeof(results) ? results[0] : 0;
    }

    // Get elements by class
    static array(Standards.XML.Node) get_by_class(Standards.XML.Node root, string class_name)
    {
        return select("." + class_name, root);
    }

    // Get text content of matched elements
    static array(string) get_text(string selector, Standards.XML.Node root)
    {
        array(Standards.XML.Node) elements = select(selector, root);
        return map(elements, lambda(Standards.XML.Node n) {
            return n->get_text();
        });
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

    Standards.XML.Node root = Standards.XML.parse(html);

    write("=== CSS Selector Examples ===\n\n");

    // Example 1: Select by ID
    write("1. Select by ID (#header)\n");
    array(Standards.XML.Node) results = CSSSelector->select("#header", root);
    write("   Found: %d element(s)\n", sizeof(results));

    // Example 2: Select by class
    write("\n2. Select by class (.container)\n");
    results = CSSSelector->select(".container", root);
    write("   Found: %d element(s)\n", sizeof(results));

    // Example 3: Select by tag
    write("\n3. Select by tag (h2)\n");
    results = CSSSelector->select("h2", root);
    write("   Found: %d element(s)\n", sizeof(results));
    foreach(results, Standards.XML.Node n) {
        write("   - %s\n", n->get_text());
    }

    // Example 4: Select by tag.class
    write("\n4. Select by tag.class (p.text)\n");
    results = CSSSelector->select("p.text", root);
    write("   Found: %d element(s)\n", sizeof(results));
    foreach(results, Standards.XML.Node n) {
        write("   - %s\n", n->get_text());
    }

    // Example 5: Select by tag#id
    write("\n5. Select by tag#id (div#content)\n");
    results = CSSSelector->select("div#content", root);
    write("   Found: %d element(s)\n", sizeof(results));

    // Example 6: Multiple selectors
    write("\n6. Multiple selectors (h1, h2)\n");
    results = CSSSelector->select("h1, h2", root);
    write("   Found: %d element(s)\n", sizeof(results));
    foreach(results, Standards.XML.Node n) {
        write("   - %s: %s\n", n->get_tag_name(), n->get_text());
    }

    // Example 7: Get text content
    write("\n7. Get text content (.title)\n");
    array(string) texts = CSSSelector->get_text(".title", root);
    foreach(texts, string text) {
        write("   - %s\n", text);
    }

    return 0;
}
