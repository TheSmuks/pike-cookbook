#!/usr/bin/env pike

// Pike compilation verification script
// Checks all cookbook files compile cleanly

int main(int argc, array(string) argv) {
    mapping(string:int) results = ([]);
    int total = 0, passed = 0, failed = 0;

    array(string) dirs = ({
        "examples/webautomation",
        "pleac_pike/ui_examples",
        "recipes/process",
        "recipes/database"
    });

    foreach(dirs, string dir) {
        write("\n=== Checking %s ===\n", dir);
        array(string) files = get_dir(dir);
        if (!files) {
            werror("Cannot read directory: %s\n", dir);
            continue;
        }

        foreach(files, string fname) {
            if (!has_suffix(fname, ".pike")) continue;

            string path = combine_path(dir, fname);
            total++;

            mixed err = catch {
                program p = compile_file(path);
                passed++;
                write("  OK: %s\n", fname);
            };

            if (err) {
                failed++;
                werror("  FAIL: %s\n", fname);
                werror("        %s\n", describe_error(err));
            }
        }
    }

    write("\n=== Summary ===\n");
    write("Total: %d, Passed: %d, Failed: %d\n", total, passed, failed);

    return failed > 0 ? 1 : 0;
}
