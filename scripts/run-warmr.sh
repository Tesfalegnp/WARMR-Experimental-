#!/usr/bin/env bash
# =============================================================================
# scripts/run-warmr.sh
# =============================================================================
# Purpose:
#   Command-line runner for the independent WARMR relational pattern miner
#   in MeTTa/MM2 on MORK.
#
# Usage:
#   ./scripts/run-warmr.sh \
#     --dataset <path_to_facts.metta> \
#     --keys <path_to_keys.metta> \
#     --bias <path_to_bias.metta> \
#     --min-support <integer> \
#     --max-length <integer> \
#     [--dataset-id <name>]
# =============================================================================

set -euo pipefail

# Print help if requested before checking prerequisites
for arg in "$@"; do
  if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
    cat << 'EOF'
WARMR Relational Pattern Miner (MORK Engine) CLI

Usage:
  ./scripts/run-warmr.sh \
    --dataset <path_to_facts.metta> \
    --keys <path_to_keys.metta> \
    --bias <path_to_bias.metta> \
    --min-support <integer> \
    --max-length <integer> \
    [--dataset-id <name>]

Options:
  --dataset     Path to background relational facts file (.metta)
  --keys        Path to positive example keys file (.metta)
  --bias        Path to language-bias mode declarations file (.metta)
  --min-support Non-negative integer threshold for frequent patterns (>= 0)
  --max-length  Maximum pattern length to explore (positive integer >= 1)
  --dataset-id  Optional identifier for the dataset (defaults to dataset basename)
  -h, --help    Show this help message and exit

Examples:
  # Shared MM2 Benchmark
  ./scripts/run-warmr.sh \
    --dataset benchmarks/ugly-sodaDrinker.metta \
    --keys benchmarks/ugly-sodaDrinker-keys.metta \
    --bias config/mm2-bias.metta \
    --min-support 2 \
    --max-length 3

  # Unary Properties Benchmark
  ./scripts/run-warmr.sh \
    --dataset benchmarks/unary-properties.metta \
    --keys benchmarks/unary-properties-keys.metta \
    --bias config/unary-bias.metta \
    --min-support 5 \
    --max-length 2

  # Recursive Family Benchmark
  ./scripts/run-warmr.sh \
    --dataset benchmarks/recursive-family.metta \
    --keys benchmarks/family-keys.metta \
    --bias config/family-bias.metta \
    --min-support 2 \
    --max-length 2
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

# Workspace root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse CLI arguments
DATASET=""
KEYS=""
BIAS=""
MIN_SUPPORT=""
MAX_LENGTH=""
DATASET_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dataset)
      DATASET="$2"
      shift 2
      ;;
    --keys)
      KEYS="$2"
      shift 2
      ;;
    --bias)
      BIAS="$2"
      shift 2
      ;;
    --min-support)
      MIN_SUPPORT="$2"
      shift 2
      ;;
    --max-length)
      MAX_LENGTH="$2"
      shift 2
      ;;
    --dataset-id)
      DATASET_ID="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown option '$1'" >&2
      echo "Run with -h or --help for usage instructions." >&2
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "$DATASET" || -z "$KEYS" || -z "$BIAS" || -z "$MIN_SUPPORT" || -z "$MAX_LENGTH" ]]; then
  echo "ERROR: Missing required arguments." >&2
  echo "Required: --dataset <path> --keys <path> --bias <path> --min-support <int> --max-length <int>" >&2
  echo "Run with -h or --help for detailed usage." >&2
  exit 1
fi

# Validate numeric constraints
if ! [[ "$MIN_SUPPORT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --min-support must be a non-negative integer (got '$MIN_SUPPORT')." >&2
  exit 1
fi

if ! [[ "$MAX_LENGTH" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: --max-length must be a positive integer >= 1 (got '$MAX_LENGTH')." >&2
  exit 1
fi

# Resolve and validate file paths
for var_name in DATASET KEYS BIAS; do
  file_val="${!var_name}"
  if [[ ! -f "$file_val" ]]; then
    # Try relative to WORKSPACE_ROOT
    if [[ -f "$WORKSPACE_ROOT/$file_val" ]]; then
      file_val="$WORKSPACE_ROOT/$file_val"
    else
      echo "ERROR: File for --$(echo "$var_name" | tr '[:upper:]' '[:lower:]') not found: '${!var_name}'" >&2
      exit 2
    fi
  fi
  # Convert to absolute path
  abs_path="$(cd "$(dirname "$file_val")" && pwd)/$(basename "$file_val")"
  eval "$var_name=\"$abs_path\""
done

if [[ -z "$DATASET_ID" ]]; then
  DATASET_ID="$(basename "$DATASET" .metta)"
fi

# Create a temporary run configuration file in /tmp
TMP_CONFIG="$(mktemp /tmp/warmr_run_XXXXXX.metta)"
trap 'rm -f "$TMP_CONFIG"' EXIT

cat << EOF > "$TMP_CONFIG"
;; Runtime Execution Configuration
(INPUT MIN_SUPPORT $MIN_SUPPORT)
(INPUT MAX_LENGTH $MAX_LENGTH)
(INPUT DATASET_ID $DATASET_ID)
(configured_limits (min_support $MIN_SUPPORT) (max_length $MAX_LENGTH))
EOF

echo "================================================================================"
echo "WARMR Relational Pattern Miner (MORK Engine)"
echo "================================================================================"
echo "Dataset:     $DATASET"
echo "Keys:        $KEYS"
echo "Bias:        $BIAS"
echo "Min Support: $MIN_SUPPORT"
echo "Max Length:  $MAX_LENGTH"
echo "Dataset ID:  $DATASET_ID"
echo "MORK Binary: $MORK_BIN"
echo "--------------------------------------------------------------------------------"

# Execute MORK pipeline
RAW_OUTPUT="$("$MORK_BIN" run \
  --aux-path "$WORKSPACE_ROOT/src/language-bias.metta" \
  --aux-path "$WORKSPACE_ROOT/src/support-calc.metta" \
  --aux-path "$WORKSPACE_ROOT/src/warmr.metta" \
  --aux-path "$WORKSPACE_ROOT/src/pruning.metta" \
  --aux-path "$WORKSPACE_ROOT/src/search-loop.metta" \
  --aux-path "$WORKSPACE_ROOT/src/output.metta" \
  --aux-path "$DATASET" \
  --aux-path "$KEYS" \
  --aux-path "$BIAS" \
  "$TMP_CONFIG")"

EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "ERROR: MORK execution failed with exit code $EXIT_CODE" >&2
  echo "$RAW_OUTPUT" >&2
  exit $EXIT_CODE
fi

# Print Discovered Frequent Patterns
echo "Discovered Frequent Patterns:"
echo "$RAW_OUTPUT" | grep -E "^\(warmr_pattern" || echo "  (No frequent patterns discovered at threshold $MIN_SUPPORT)"

# Print Summary Status
echo "--------------------------------------------------------------------------------"
STATUS="$(echo "$RAW_OUTPUT" | grep -E "^\(warmr_search_status" || echo "(warmr_search_status unknown)")"
TOTAL_KEYS="$(echo "$RAW_OUTPUT" | grep -E "^\(total_positive_keys" || echo "(total_positive_keys unknown)")"
FREQ_COUNT="$(echo "$RAW_OUTPUT" | grep -c -E "^\(warmr_pattern" || true)"

echo "Search Status:       $STATUS"
echo "Total Domain Keys:   $TOTAL_KEYS"
echo "Frequent Patterns:   $FREQ_COUNT"
echo "================================================================================"
exit 0
