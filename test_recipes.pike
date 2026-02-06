#!/usr/bin/env pike

// Script to test all Pike recipes for syntax and basic execution

import Stdio;
import Process;

array(string) find_pike_files(string dir) {
    array(string) files = ({});
    
    // Use find command to get all .pike files
    object proc = Process.create_process(
        ({ "find", dir, "-name", "*.pike", "-type", "f" }),
        ([ "stdout": Pipe("pipe"), "stderr": Pipe("pipe") ])
    );
    
    string output = proc->stdout->read();
    proc->wait();
    
    if (output && sizeof(output) > 0) {
        files = filter(output / "\n", lambda(string s) { return sizeof(s) > 0; });
    }
    
    return files;
}

int test_syntax(string file) {
    // Test syntax using pike -x dump
    object proc = Process.create_process(
        ({ "pike", "-x", "dump", file }),
        ([ "stdout": Pipe("pipe"), "stderr": Pipe("pipe") ])
    );
    
    int result = proc->wait();
    return result == 0;
}

int test_run(string file) {
    // Try to run the file with a timeout
    object proc = Process.create_process(
        ({ "timeout", "5", "pike", file }),
        ([ "stdout": Pipe("pipe"), "stderr": Pipe("pipe") ])
    );
    
    int result = proc->wait();
    return result;
}

int main() {
    array(string) all_files = ({});
    
    // Collect files from all directories
    foreach(({
        "recipes",
        "examples/webautomation",
        "pleac_pike/ui_examples"
    }), string dir) {
        if (file_stat(dir)) {
            all_files += find_pike_files(dir);
        }
    }
    
    write("Found %d Pike files to test\n\n", sizeof(all_files));
    
    mapping results = ([
        "syntax_ok": ({}),
        "syntax_fail": ({}),
        "run_ok": ({}),
        "run_fail": ({}),
        "run_timeout": ({})
    ]);
    
    foreach(all_files, string file) {
        write("Testing: %s\n", file);
        
        // Test syntax
        if (test_syntax(file)) {
            results["syntax_ok"] += ({ file });
            
            // Try to run it
            int run_result = test_run(file);
            if (run_result == 0) {
                results["run_ok"] += ({ file });
                write("  [OK] Syntax OK, Runs OK\n");
            } else if (run_result == 124) { // timeout exit code
                results["run_timeout"] += ({ file });
                write("  [TIMEOUT] Syntax OK, but timed out (may need input)\n");
            } else {
                results["run_fail"] += ({ file });
                write("  [FAIL] Syntax OK, but run failed (exit: %d)\n", run_result);
            }
        } else {
            results["syntax_fail"] += ({ file });
            write("  [SYNTAX ERROR]\n");
        }
    }
    
    // Summary
    write("\n" + "="*60 + "\n");
    write("SUMMARY\n");
    write("="*60 + "\n");
    write("Total files: %d\n", sizeof(all_files));
    write("Syntax OK: %d\n", sizeof(results["syntax_ok"]));
    write("Syntax Fail: %d\n", sizeof(results["syntax_fail"]));
    write("Run OK: %d\n", sizeof(results["run_ok"]));
    write("Run Fail: %d\n", sizeof(results["run_fail"]));
    write("Run Timeout: %d\n", sizeof(results["run_timeout"]));
    
    if (sizeof(results["syntax_fail"]) > 0) {
        write("\n--- Files with SYNTAX ERRORS ---\n");
        foreach(results["syntax_fail"], string f) {
            write("  - %s\n", f);
        }
    }
    
    if (sizeof(results["run_fail"]) > 0) {
        write("\n--- Files that FAILED TO RUN ---\n");
        foreach(results["run_fail"], string f) {
            write("  - %s\n", f);
        }
    }
    
    if (sizeof(results["run_timeout"]) > 0) {
        write("\n--- Files that TIMED OUT (may need user input) ---\n");
        foreach(results["run_timeout"], string f) {
            write("  - %s\n", f);
        }
    }
    
    return 0;
}
