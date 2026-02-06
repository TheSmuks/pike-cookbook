#!/bin/bash

# Script to test all Pike recipes for syntax and basic execution

echo "Pike Recipe Analysis Report"
echo "============================"
echo ""

# Find all .pike files
files=$(find recipes examples/webautomation pleac_pike/ui_examples -name "*.pike" -type f 2>/dev/null | sort)

total=0
syntax_ok=0
syntax_fail=0
run_ok=0
run_fail=0
run_timeout=0

syntax_fail_files=""
run_fail_files=""
run_timeout_files=""

for file in $files; do
    total=$((total + 1))
    echo "Testing: $file"
    
    # Test syntax using pike -x dump
    if pike -x dump "$file" >/dev/null 2>&1; then
        syntax_ok=$((syntax_ok + 1))
        
        # Try to run with timeout
        exit_code=$(timeout 5 pike "$file" >/dev/null 2>&1; echo $?)
        
        if [ "$exit_code" -eq 0 ]; then
            run_ok=$((run_ok + 1))
            echo "  [OK] Syntax OK, Runs OK"
        elif [ "$exit_code" -eq 124 ]; then
            run_timeout=$((run_timeout + 1))
            run_timeout_files="$run_timeout_files\n  - $file"
            echo "  [TIMEOUT] Syntax OK, but timed out (may need input)"
        else
            run_fail=$((run_fail + 1))
            run_fail_files="$run_fail_files\n  - $file (exit: $exit_code)"
            echo "  [FAIL] Syntax OK, but run failed (exit: $exit_code)"
        fi
    else
        syntax_fail=$((syntax_fail + 1))
        syntax_fail_files="$syntax_fail_files\n  - $file"
        echo "  [SYNTAX ERROR]"
    fi
done

echo ""
echo "============================================================"
echo "SUMMARY"
echo "============================================================"
echo "Total files: $total"
echo "Syntax OK: $syntax_ok"
echo "Syntax Fail: $syntax_fail"
echo "Run OK: $run_ok"
echo "Run Fail: $run_fail"
echo "Run Timeout: $run_timeout"

if [ -n "$syntax_fail_files" ]; then
    echo ""
    echo "--- Files with SYNTAX ERRORS ---"
    echo -e "$syntax_fail_files"
fi

if [ -n "$run_fail_files" ]; then
    echo ""
    echo "--- Files that FAILED TO RUN ---"
    echo -e "$run_fail_files"
fi

if [ -n "$run_timeout_files" ]; then
    echo ""
    echo "--- Files that TIMED OUT (may need user input) ---"
    echo -e "$run_timeout_files"
fi

echo ""
echo "Analysis complete!"
