#!/usr/bin/env pike
#pragma strict-values
#pragma strict_types
// Parse well-formed XHTML/XML with Standards.XML

int main()
{
    string xhtml = #"
    <!DOCTYPE html>
    <html>
    <head><title>Test Page</title></head>
    <body>
        <h1>Welcome</h1>
        <div class="content">
            <p id="intro">This is paragraph 1</p>
            <p id="main">This is paragraph 2</p>
        </div>
        <ul>
            <li>Item 1</li>
            <li>Item 2</li>
            <li>Item 3</li>
        </ul>
    </body>
    </html>
    ";

    // Parse with Standards.XML (for XHTML/well-formed XML)
    Standards.XML.Node root = Standards.XML.parse(xhtml);

    // Extract title
    array(Standards.XML.Node) titles = root->get_elements("title");
    if (sizeof(titles)) {
        write("Title: %s\n", titles[0]->get_text());
    }

    // Extract all paragraphs
    array(Standards.XML.Node) paragraphs = root->get_elements("p");
    write("\n--- Paragraphs ---\n");
    foreach(paragraphs, Standards.XML.Node p) {
        string id = p->get_attributes()->id || "no-id";
        write("  [%s]: %s\n", id, p->get_text());
    }

    // Extract list items
    array(Standards.XML.Node) lists = root->get_elements("ul");
    if (sizeof(lists)) {
        array(Standards.XML.Node) items = lists[0]->get_elements("li");
        write("\n--- List Items ---\n");
        foreach(items, Standards.XML.Node item) {
            write("  - %s\n", item->get_text());
        }
    }

    return 0;
}
