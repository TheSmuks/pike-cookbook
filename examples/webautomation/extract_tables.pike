#!/usr/bin/env pike
#pragma strict_types
// Extract data from HTML tables

int main(int argc, array(string) argv)
{
    write("=== HTML Table Extraction Example ===\n\n");

    // Accept optional URL argument, otherwise use embedded demo HTML
    string html;

    if (argc > 1 && has_prefix(argv[1], "http")) {
        write("Fetching URL: %s\n", argv[1]);

        mixed err = catch {
            Protocols.HTTP.Query q = Protocols.HTTP.get_url(argv[1]);
            if (q && q->status == 200) {
                html = q->data();
                write("Fetched %d bytes\n\n", sizeof(html));
            } else {
                write("Failed to fetch URL, using demo HTML\n\n");
            }
        };

        if (err || !html) {
            write("Network error, using demo HTML\n\n");
        }
    }

    if (!html) {
        html = #"
    <table id='users'>
        <thead>
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Alice Smith</td>
                <td>alice@example.com</td>
                <td>Admin</td>
            </tr>
            <tr>
                <td>Bob Jones</td>
                <td>bob@example.com</td>
                <td>User</td>
            </tr>
        </tbody>
    </table>
    ";

    object xml_root = Parser.XML.Tree.parse_input(html);
    mixed root_mixed = xml_root->get_children();
    if (!arrayp(root_mixed) || !sizeof((array)root_mixed)) {
        werror("No root element\n");
        return 1;
    }
    object root = (object)((array)root_mixed)[0];

    // Find table
    mixed tables_mixed = root->get_elements("table");
    if (!arrayp(tables_mixed) || !sizeof((array)tables_mixed)) {
        werror("No tables found\n");
        return 1;
    }
    array tables = (array)tables_mixed;

    // Extract table data
    array(array(string)) rows = ({});

    void process_tr(object tr) {
        array(string) cells = ({});
        mixed tds_mixed = tr->get_elements("td");
        mixed ths_mixed = tr->get_elements("th");
        if (arrayp(tds_mixed) && arrayp(ths_mixed)) {
            array tds = (array)tds_mixed;
            array ths = (array)ths_mixed;
            foreach(tds + ths, mixed cell) {
                if (objectp(cell)) {
                    mixed text = ((object)cell)->get_text();
                    cells += ({ stringp(text) ? (string)text : "" });
                }
            }
        }
        if (sizeof(cells)) {
            rows += ({ cells });
        }
    };

    // Process all rows
    if (sizeof(tables) == 0) {
        werror("No tables found\n");
        return 1;
    }
    mixed first_table = tables[0];
    if (!objectp(first_table)) {
        werror("First table is not an object\n");
        return 1;
    }
    mixed trs = ((object)first_table)->get_elements("tr");
    if (arrayp(trs)) {
        foreach((array)trs, mixed tr) {
            if (objectp(tr)) {
                process_tr((object)tr);
            }
        }
    }

    // Display as formatted table
    if (sizeof(rows)) {
        // Calculate column widths
        array(int) widths = allocate(sizeof(rows[0]));
        foreach(rows, array(string) row) {
            for (int i = 0; i < sizeof(row); i++) {
                widths[i] = max(widths[i], sizeof(row[i]));
            }
        }

        // Print header separator (calculate total width)
        int total_width = 0;
        foreach(widths, int w) { total_width += w; }
        total_width += sizeof(widths) * 3 + 1;
        write("%s\n", "-" * total_width);

        // Print rows
        foreach(rows; int row_num; array(string) row) {
            write("|");
            for (int i = 0; i < sizeof(row); i++) {
                int w = widths[i];
                write(sprintf(" %%-%ds |", w), row[i]);
            }
            write("\n");

            // Separator after header
            if (row_num == 0) {
                write("%s\n", "-" * total_width);
            }
        }

        write("%s\n", "-" * total_width);
    }
    }

    return 0;
}
