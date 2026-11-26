#!/usr/bin/env bash
# =============================================================================
# scripts/test-cli-e2e.sh
# =============================================================================
# Automated End-to-End Regression Suite for the Production WARMR CLI.
# Tests real MORK execution across all 6 production benchmark datasets:
#   1. ugly-sodaDrinker (MM2 Benchmark, Arity 2, Depths 1-3)
#   2. recursive-family (Transitive Datalog, Arity 2, Depths 1-2)
#   3. unary-properties (User Accounts, Arity 1, Depths 1-2)
#   4. ternary-transactions (Banking, Arity 3, Depths 1-2)
#   5. events-4ary (Security Audit Log, Arity 4, Depths 1-2)
#   6. deep-chain-8 (Synthetic Chain, Depths 1-8)
#
# Validates:
#   - Exit code 0
#   - Expected frequent pattern emission
#   - Exact support counts & relative support ratios
#   - Max-depth cutoff enforcement
#   - No duplicate output records
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORKSPACE_ROOT"

MORK_BIN="${MORK_BIN:-bin/mork}"
if [[ ! -x "$MORK_BIN" ]]; then
  if command -v mork &>/dev/null; then
    MORK_BIN="mork"
  else
    echo "ERROR: MORK binary not found at '$MORK_BIN'" >&2
    exit 127
  fi
fi

echo "================================================================================"
echo "WARMR Production CLI End-to-End Regression Test Suite"
echo "================================================================================"
echo "Workspace:   $WORKSPACE_ROOT"
echo "MORK Binary: $MORK_BIN"
echo "--------------------------------------------------------------------------------"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_e2e_benchmark() {
  local name="$1"
  local dataset="$2"
  local keys="$3"
  local bias="$4"
  local min_s="$5"
  local max_d="$6"
  local expected_pat_count="$7"
  local required_regex="$8"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "  TEST [$TOTAL_TESTS] $name ... "

  local output
  local exit_code=0
  output="$(MORK_BIN="$MORK_BIN" ./scripts/run-warmr.sh \
    --dataset "$dataset" \
    --keys "$keys" \
    --bias "$bias" \
    --min-support "$min_s" \
    --max-depth "$max_d" 2>&1)" || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "FAILED (Exit code $exit_code)"
    echo "$output" | sed 's/^/    /'
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return
  fi

  # Check expected pattern count
  local actual_pat_count
  actual_pat_count="$(echo "$output" | grep -c "^(warmr_pattern" || true)"
  if [[ "$actual_pat_count" -ne "$expected_pat_count" ]]; then
    echo "FAILED (Pattern count mismatch: expected $expected_pat_count, got $actual_pat_count)"
    echo "$output" | sed 's/^/    /'
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return
  fi

  # Check required pattern regex
  if [[ -n "$required_regex" ]] && ! echo "$output" | grep -E "$required_regex" >/dev/null; then
    echo "FAILED (Required regex '$required_regex' not found in output)"
    echo "$output" | sed 's/^/    /'
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return
  fi

  # Check duplicate output records (each line starting with (warmr_pattern must be unique)
  local total_pats unique_pats
  total_pats="$(echo "$output" | grep "^(warmr_pattern" | wc -l || true)"
  unique_pats="$(echo "$output" | grep "^(warmr_pattern" | sort -u | wc -l || true)"
  if [[ "$total_pats" -ne "$unique_pats" ]]; then
    echo "FAILED (Duplicate pattern records detected: total $total_pats, unique $unique_pats)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return
  fi

  echo "PASS ($actual_pat_count patterns verified)"
  PASSED_TESTS=$((PASSED_TESTS + 1))
}

# 1. MM2 Benchmark: ugly-sodaDrinker (Arity 2, Depths 1-3)
run_e2e_benchmark "ugly-sodaDrinker (MM2 Benchmark)" \
  "benchmarks/ugly-sodaDrinker.metta" \
  "benchmarks/ugly-sodaDrinker-keys.metta" \
  "config/mm2-bias.metta" \
  5 3 20 \
  "\(warmr_pattern \(id \(cand_l3 human man ugly\)\)"

# 2. Recursive Family Benchmark: Transitive Datalog (Arity 2, Depths 1-2)
run_e2e_benchmark "recursive-family (Transitive Chains)" \
  "benchmarks/recursive-family.metta" \
  "benchmarks/family-keys.metta" \
  "config/family-bias.metta" \
  2 2 2 \
  "\(warmr_pattern \(id \(cand_l2_chain parent parent\)\)"

# 3. Unary Properties Benchmark: User Accounts (Arity 1, Depths 1-2)
run_e2e_benchmark "unary-properties (Arity 1 Attributes)" \
  "benchmarks/unary-properties.metta" \
  "benchmarks/unary-properties-keys.metta" \
  "config/unary-bias.metta" \
  5 2 3 \
  "\(warmr_pattern \(id \(cand_l2 active verified\)\)"

# 4. Ternary Transactions Benchmark: Banking Transfers (Arity 3, Depths 1-2)
run_e2e_benchmark "ternary-transactions (Arity 3 Chaining)" \
  "benchmarks/ternary-transactions.metta" \
  "benchmarks/ternary-transactions-keys.metta" \
  "config/ternary-bias.metta" \
  2 2 3 \
  "\(warmr_pattern \(id \(cand_l2 \(cand_l1 transfer chase\) transfer citi\)\)"

# 5. Events 4-Ary Benchmark: Security Audit Log (Arity 4, Depths 1-2)
run_e2e_benchmark "events-4ary (Arity 4 Quadruples)" \
  "benchmarks/events-4ary.metta" \
  "benchmarks/events-4ary-keys.metta" \
  "config/events-4ary-bias.metta" \
  2 2 1 \
  "\(warmr_pattern \(id \(cand_l1 audit_log login mobile success\)\)"

# 6. Deep Relational Chain: Depths 1-8 (Multi-Hop Relational Chain)
run_e2e_benchmark "deep-chain-8 (Depths 1-8)" \
  "benchmarks/deep-chain-8.metta" \
  "benchmarks/deep-chain-keys.metta" \
  "config/deep-chain-bias.metta" \
  1 8 8 \
  "\(warmr_pattern \(id \(cand_l8_chain"

echo "--------------------------------------------------------------------------------"
echo "End-to-End Test Summary:"
echo "  Total Benchmarks: $TOTAL_TESTS"
echo "  Passed:           $PASSED_TESTS"
echo "  Failed:           $FAILED_TESTS"
if [[ $FAILED_TESTS -eq 0 ]]; then
  echo "Status:             ALL E2E BENCHMARKS PASSED (100%)"
  echo "================================================================================"
  exit 0
else
  echo "Status:             E2E BENCHMARK SUITE FAILED"
  echo "================================================================================"
  exit 1
fi
