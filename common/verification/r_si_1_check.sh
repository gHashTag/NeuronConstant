#!/usr/bin/env bash
# R-SI-1: zero standalone `*` operators in synthesisable RTL
# Usage: r_si_1_check.sh <rtl_dir>
#
# R-SI-1 invariant: all multiplication in Trinity RTL is implemented via
# shift-and-add in gf16_mul.v. The standalone `*` operator is prohibited
# in synthesisable .v files to guarantee synthesis portability and audit
# compliance with the DARPA CLARA AI safety framework.
#
# Exit code: number of violations found (0 = pass).
#
# NeuronConstant canonical hardware catalog
# DOI: 10.5281/zenodo.19227877 · Apache-2.0

set -euo pipefail

RTL_DIR="${1:?usage: r_si_1_check.sh <rtl_dir>}"

if [[ ! -d "$RTL_DIR" ]]; then
    echo "ERROR: RTL directory not found: $RTL_DIR" >&2
    exit 1
fi

violations=0
files_checked=0

echo "R-SI-1 check: scanning $RTL_DIR/*.v ..."

for f in "$RTL_DIR"/*.v; do
    [[ -f "$f" ]] || continue
    files_checked=$((files_checked + 1))

    # Strip block comments /* ... */ and line comments // ...
    # then check for standalone * (not **, not */, not /*, not port declarations)
    cleaned=$(sed -E \
        -e 's@/\*([^*]|\*+[^*/])*\*+/@@g' \
        -e 's@//.*$@@' \
        "$f")

    # Pattern: a * that is not part of ** (power — should not exist in RTL),
    # not /*, not */, not *) or (* (attribute syntax)
    # We look for: non-* non-/ characters before *, and non-* non-/ after *
    if echo "$cleaned" | grep -nE '[^*/[:space:]]\*[^*/=]' >&2; then
        echo "R-SI-1 VIOLATION in $f" >&2
        violations=$((violations + 1))
    fi
done

if [[ $files_checked -eq 0 ]]; then
    echo "WARNING: no .v files found in $RTL_DIR" >&2
    exit 0
fi

if [[ $violations -eq 0 ]]; then
    echo "R-SI-1 PASS: $files_checked files checked, 0 violations."
else
    echo "R-SI-1 FAIL: $violations violation(s) in $files_checked files." >&2
fi

exit $violations
