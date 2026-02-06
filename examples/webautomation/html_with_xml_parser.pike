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
    object xml_root = Parser.XML.Tree.parse_input(xhtml);
    mixed root_mixed = xml_root->get_children();
    if (!arrayp(root_mixed) || !sizeof((array)root_mixed)) {
        werror("Failed to parse XML\n");
        return 1;
    }
    array root_array = (array)root_mixed;
    object root = (object)root_array[0];

    // Extract title
    mixed titles_mixed = root->get_elements("title");
    if (arrayp(titles_mixed) && sizeof((array)titles_mixed)) {
        object title_elem = (object)((array)titles_mixed)[0];
        mixed text = title_elem->get_text();
        write("Title: %s\n", stringp(text) ? (string)text : "");
    }

    // Extract all paragraphs
    mixed paragraphs_mixed = root->get_elements("p");
    write("\n--- Paragraphs ---\n");
    if (arrayp(paragraphs_mixed)) {
        array paragraphs_array = (array)paragraphs_mixed;
        foreach(paragraphs_array, mixed p) {
            if (!objectp(p)) continue;
            object p_obj = (object)p;
            mixed attrs_mixed = p_obj->get_attributes();
            if (!mappingp(attrs_mixed)) continue;
            mapping attrs = (mapping)attrs_mixed;
            mixed id_mixed = attrs->id;
            string id = stringp(id_mixed) ? (string)id_mixed : "no-id";
            mixed text = p_obj->get_text();
            string text_str = stringp(text) ? (string)text : "";
            write("  [%s]: %s\n", id, text_str);
        }
    }

    // Extract list items
    mixed lists_mixed = root->get_elements("ul");
    if (arrayp(lists_mixed) && sizeof((array)lists_mixed)) {
        object list_obj = (object)((array)lists_mixed)[0];
        mixed items_mixed = list_obj->get_elements("li");
        if (arrayp(items_mixed)) {
            write("\n--- List Items ---\n");
            foreach((array)items_mixed, mixed item) {
                if (objectp(item)) {
                    mixed text = ((object)item)->get_text();
                    write("  - %s\n", stringp(text) ? (string)text : "");
                }
            }
        }
    }

    return 0;
}
