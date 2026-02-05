#!/usr/bin/env pike
#pragma strict_types
// Extract data from HTML tables

int main()
{
    string html = #"
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

    Parser.XML.Tree.RootNode xml_root = Parser.XML.Tree.parse_input(html);
    Parser.XML.Tree.Node root = xml_root->get_children()[0];

    // Find table
    array(Parser.XML.Tree.Node) tables = root->get_elements("table");
    if (!sizeof(tables)) {
        werror("No tables found\n");
        return 1;
    }

    // Extract table data
    array(array(string)) rows = ({});

    void process_tr(Parser.XML.Tree.Node tr) {
        array(string) cells = ({});
        foreach(tr->get_elements("td") + tr->get_elements("th"),
                Parser.XML.Tree.Node cell) {
            cells += ({ cell->get_text() });
        }
        if (sizeof(cells)) {
            rows += ({ cells });
        }
    };

    // Process all rows
    foreach(tables[0]->get_elements("tr"), Parser.XML.Tree.Node tr) {
        process_tr(tr);
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

        // Print header separator
        write("%s\n", "-" * (sum(widths) + sizeof(widths) * 3 + 1));

        // Print rows
        foreach(rows; int row_num; array(string) row) {
            write("|");
            for (int i = 0; i < sizeof(row); i++) {
                write(" %-*s |", widths[i], row[i]);
            }
            write("\n");

            // Separator after header
            if (row_num == 0) {
                write("%s\n", "-" * (sum(widths) + sizeof(widths) * 3 + 1));
            }
        }

        write("%s\n", "-" * (sum(widths) + sizeof(widths) * 3 + 1));
    }

    return 0;
}
