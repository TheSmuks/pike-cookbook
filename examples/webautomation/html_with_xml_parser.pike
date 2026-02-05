#!/usr/bin/env pike
#pragma strict_types
// Parse well-formed XHTML/XML with Parser.XML.Tree

int main()
{
    string xhtml =
        "<!DOCTYPE html>\n"
        "<html>\n"
        "<head><title>Test Page</title></head>\n"
        "<body>\n"
        "    <h1>Welcome</h1>\n"
        "    <div class=\"content\">\n"
        "        <p id=\"intro\">This is paragraph 1</p>\n"
        "        <p id=\"main\">This is paragraph 2</p>\n"
        "    </div>\n"
        "    <ul>\n"
        "        <li>Item 1</li>\n"
        "        <li>Item 2</li>\n"
        "        <li>Item 3</li>\n"
        "    </ul>\n"
        "</body>\n"
        "</html>\n";

    // Parse with Parser.XML.Tree (for XHTML/well-formed XML)
    Parser.XML.Tree.RootNode xml_root = Parser.XML.Tree.parse_input(xhtml);
    Parser.XML.Tree.Node root = xml_root->get_children()[0];

    // Extract title
    array(Parser.XML.Tree.Node) titles = root->get_elements("title");
    if (sizeof(titles)) {
        write("Title: %s\n", titles[0]->get_text());
    }

    // Extract all paragraphs
    array(Parser.XML.Tree.Node) paragraphs = root->get_elements("p");
    write("\n--- Paragraphs ---\n");
    foreach(paragraphs, Parser.XML.Tree.Node p) {
        string id = p->get_attributes()->id || "no-id";
        write("  [%s]: %s\n", id, p->get_text());
    }

    // Extract list items
    array(Parser.XML.Tree.Node) lists = root->get_elements("ul");
    if (sizeof(lists)) {
        array(Parser.XML.Tree.Node) items = lists[0]->get_elements("li");
        write("\n--- List Items ---\n");
        foreach(items, Parser.XML.Tree.Node item) {
            write("  - %s\n", item->get_text());
        }
    }

    return 0;
}
