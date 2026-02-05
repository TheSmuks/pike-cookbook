#!/usr/bin/env pike
#pragma strict_types
// Recipe: Parsing Program Arguments with Getopt

constant USAGE =
"Usage: parse_args.pike [OPTIONS]\n"
"\n"
"Options:\n"
"  -h, --help        Show this help message\n"
"  -v, --verbose     Enable verbose output\n"
"  -o FILE, --output=FILE  Output file\n"
"  -n NUM, --number=NUM    Set number (default: 10)\n"
"  --enable-flag     Enable a feature flag\n"
"  --list=ITEMS      Comma-separated list of items\n"
;

int verbose = 0;
string output_file = "";
int number = 10;
int feature_flag = 0;
array(string) items = ({});

int main(int argc, array(string) argv) {
    // Modern Pike 8 Getopt parsing
    foreach(Getopt.find_all_options(argv, ({
        ({"help", Getopt.NO_ARG, ({"-h", "--help"})}),
        ({"verbose", Getopt.NO_ARG, ({"-v", "--verbose"})}),
        ({"output", Getopt.HAS_ARG, ({"-o", "--output"})}),
        ({"number", Getopt.HAS_ARG, ({"-n", "--number"})}),
        ({"enable_flag", Getopt.NO_ARG, ({"--enable-flag"})}),
        ({"list", Getopt.HAS_ARG, ({"--list"})}),
    })), array(string) opt) {
        switch(opt[0]) {
            case "help":
                write(USAGE);
                return 0;
            case "verbose":
                verbose = 1;
                break;
            case "output":
                output_file = opt[1];
                break;
            case "number":
                number = (int)opt[1];
                break;
            case "enable_flag":
                feature_flag = 1;
                break;
            case "list":
                items = opt[1] / ",";
                break;
        }
    }

    // Remaining arguments after options
    array(string) args = Getopt.get_args(argv);

    if (verbose) {
        write("Configuration:\n");
        write(sprintf("  Verbose: %d\n", verbose));
        write(sprintf("  Output: %s\n", output_file || "stdout"));
        write(sprintf("  Number: %d\n", number));
        write(sprintf("  Feature flag: %d\n", feature_flag));
        write(sprintf("  Items: %s\n", items * ", "));
        write(sprintf("  Remaining args: %s\n", args * " "));
    }

    return 0;
}
