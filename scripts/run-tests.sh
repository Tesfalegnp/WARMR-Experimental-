#!/usr/bin/env bash
# =============================================================================
# scripts/run-tests.sh
# =============================================================================
# Purpose:
#   Automated Test Suite Runner for the independent WARMR relational pattern
#   miner in MeTTa/MM2 on MORK.
#
# Usage:
#   ./scripts/run-tests.sh [test_file.metta ...]
#
# Behavior:
#   - If no arguments are provided, automatically discovers and runs all 
#     test suites in tests/*.metta.
#   - If specific test files are passed as arguments, runs only those.
#   - Parses ';; TEST-AUX <path>' declarations from each test header.
#   - Executes 'mork run' and verifies all '(EXPECTED-RESULT <label> <expr>)'
#     invariants against the dumped AtomSpace expressions.
#   - Reports summary of passed/failed suites and assertions.
#   - Exits with code 0 on 100% pass, non-zero on any failure.
# =============================================================================

set -euo pipefail

# Print help if requested
for arg in "$@"; do
  if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
    cat << 'EOF'
WARMR MORK Test Suite Runner

Usage:
  ./scripts/run-tests.sh [test_file.metta ...]

Options:
  -h, --help    Show this help message and exit

Behavior:
  - If no arguments are provided, automatically runs all 19 test suites
    in tests/*.metta (270 assertions).
  - If specific test files are passed, executes only those.
  - Returns exit code 0 on 100% pass, non-zero on any failure.
EOF
    exit 0
  fi
done

# Locate MORK binary
MORK_BIN="${MORK_BIN:-/home/hope/.local/bin/mork}"
if ! command -v "$MORK_BIN" &> /dev/null; then
  if command -v mork &> /dev/null; then
    MORK_BIN="mork"
  else
    echo "ERROR: MORK binary not found at '$MORK_BIN' and not in PATH." >&2
    echo "Please set MORK_BIN or install mork into /home/hope/.local/bin/mork or PATH." >&2
    exit 127
  fi
fi

# Locate workspace root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORKSPACE_ROOT"

# Determine test files to run
if [[ $# -gt 0 ]]; then
  TEST_FILES=()
  for t in "$@"; do
    if [[ ! -f "$t" && ! -f "$WORKSPACE_ROOT/$t" ]]; then
      echo "ERROR: Test file not found: '$t'" >&2
      exit 2
    fi
    if [[ -f "$t" ]]; then
      TEST_FILES+=("$t")
    else
      TEST_FILES+=("$WORKSPACE_ROOT/$t")
    fi
  done
else
  mapfile -t TEST_FILES < <(find tests -name "*.metta" | sort)
fi

TOTAL_SUITES=${#TEST_FILES[@]}
PASSED_SUITES=0
FAILED_SUITES=0
TOTAL_ASSERTIONS=0
PASSED_ASSERTIONS=0
FAILED_ASSERTIONS=0

echo "================================================================================"
echo "WARMR MORK Test Suite Runner"
echo "================================================================================"
echo "Workspace:   $WORKSPACE_ROOT"
echo "MORK Binary: $MORK_BIN"
echo "Suites:      $TOTAL_SUITES"
echo "--------------------------------------------------------------------------------"

for TEST_FILE in "${TEST_FILES[@]}"; do
  if [[ ! -f "$TEST_FILE" ]]; then
    echo "ERROR: Test file not found: $TEST_FILE" >&2
    FAILED_SUITES=$((FAILED_SUITES + 1))
    continue
  fi

  # Extract auxiliary files from header
  AUX_ARGS=()
  AUX_REGEX='^[[:space:]]*;;[[:space:]]*TEST-AUX[[:space:]]+([^[:space:]]+)'
  while IFS= read -r line; do
    if [[ "$line" =~ $AUX_REGEX ]]; then
      AUX_PATH="${BASH_REMATCH[1]}"
      AUX_ARGS+=(--aux-path "$WORKSPACE_ROOT/$AUX_PATH")
    fi
  done < "$TEST_FILE"

  # Measure execution time
  START_TIME=$(python3 -c 'import time; print(int(time.time() * 1000))')
  
  # Run MORK
  RAW_OUTPUT="$("$MORK_BIN" run "$TEST_FILE" "${AUX_ARGS[@]}" 2>&1)" || {
    echo "FAIL: $TEST_FILE (mork run crashed or returned non-zero)"
    echo "$RAW_OUTPUT" | head -n 20
    FAILED_SUITES=$((FAILED_SUITES + 1))
    continue
  }
  
  END_TIME=$(python3 -c 'import time; print(int(time.time() * 1000))')
  ELAPSED_MS=$((END_TIME - START_TIME))

  # Use Python to accurately parse s-expressions and match assertions
  RESULT_JSON=$(python3 -c '
import sys, re, json

raw_output = sys.stdin.read()
lines = [l.strip() for l in raw_output.splitlines() if l.strip()]
line_set = set(lines)

assertions = []
for l in lines:
    m = re.match(r"^\(EXPECTED-RESULT\s+(\S+)\s+(.+)\)$", l)
    if m:
        label = m.group(1)
        expected = m.group(2)
        passed = expected in line_set
        assertions.append({
            "label": label,
            "expected": expected,
            "passed": passed
        })

total = len(assertions)
passed = sum(1 for a in assertions if a["passed"])
failed_items = [a for a in assertions if not a["passed"]]

print(json.dumps({
    "total": total,
    "passed": passed,
    "failed": total - passed,
    "failed_items": failed_items
}))
' <<< "$RAW_OUTPUT")

  SUITE_TOTAL=$(echo "$RESULT_JSON" | python3 -c 'import sys, json; print(json.load(sys.stdin)["total"])')
  SUITE_PASSED=$(echo "$RESULT_JSON" | python3 -c 'import sys, json; print(json.load(sys.stdin)["passed"])')
  SUITE_FAILED=$(echo "$RESULT_JSON" | python3 -c 'import sys, json; print(json.load(sys.stdin)["failed"])')

  TOTAL_ASSERTIONS=$((TOTAL_ASSERTIONS + SUITE_TOTAL))
  PASSED_ASSERTIONS=$((PASSED_ASSERTIONS + SUITE_PASSED))
  FAILED_ASSERTIONS=$((FAILED_ASSERTIONS + SUITE_FAILED))

  if [[ $SUITE_FAILED -eq 0 && $SUITE_TOTAL -gt 0 ]]; then
    PASSED_SUITES=$((PASSED_SUITES + 1))
    printf "  PASS: %-32s (%2d/%2d assertions) [%3d ms]\n" "$TEST_FILE" "$SUITE_PASSED" "$SUITE_TOTAL" "$ELAPSED_MS"
  else
    FAILED_SUITES=$((FAILED_SUITES + 1))
    printf "  FAIL: %-32s (%2d/%2d assertions) [%3d ms]\n" "$TEST_FILE" "$SUITE_PASSED" "$SUITE_TOTAL" "$ELAPSED_MS"
    echo "$RESULT_JSON" | python3 -c '
import sys, json
data = json.load(sys.stdin)
for item in data.get("failed_items", []):
    lbl = item["label"]
    exp = item["expected"]
    print(f"        Missing assertion: {lbl} -> {exp}")
'
  fi
done

echo "--------------------------------------------------------------------------------"
echo "Test Execution Summary:"
echo "  Suites:     $PASSED_SUITES / $TOTAL_SUITES passed"
echo "  Assertions: $PASSED_ASSERTIONS / $TOTAL_ASSERTIONS passed"

if [[ $FAILED_SUITES -eq 0 && $TOTAL_SUITES -gt 0 ]]; then
  echo "Status:     ALL TESTS PASSED (100%)"
  echo "================================================================================"
  exit 0
else
  echo "Status:     TESTS FAILED ($FAILED_SUITES suites failed, $FAILED_ASSERTIONS assertions failed)"
  echo "================================================================================"
  exit 1
fi
