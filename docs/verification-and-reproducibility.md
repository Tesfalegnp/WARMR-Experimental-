# Verification and Reproducibility Guide

This document provides complete instructions, environment specifications, verified commands, and ground-truth references for reproducing all experimental results of the independent WARMR relational pattern miner in MeTTa/MM2 on MORK.

---

## 1. System & Environment Specifications

- **Operating System:** Linux (x86_64)
- **Execution Engine:** Native MORK compiler binary (`bin/mork`, build commit `ed57c67`)
- **Repository:** `https://github.com/Tesfalegnp/WARMR-Experimental-.git`, branch `main`
- **Comparative Target:** `https://github.com/iCog-Labs-Dev/Pattern-miner-mm2.git` (commit `153afdae240d5235cdd045112f5d04b4bfb397a0`)

---

## 2. Dataset Provenance & SHA256 Checksums

| Dataset File | Role / Domain | Fact Count | Verified SHA256 Checksum |
|---|---|:---:|---|
| `benchmarks/ugly-sodaDrinker.metta` | Shared MM2 Benchmark | 60 | `3b8b32224004667108e4560001c78861faf833ddb498f7b6a62f92aaecc223b8` |
| `benchmarks/unary-properties.metta` | Unary Relations ($N=10$) | 18 | `479fa5aefc4fe1d8aca5cfa9fa48e47ee9e336280883f653dfba9847791597fc` |
| `benchmarks/ternary-transactions.metta` | Ternary Banking ($N=6$) | 8 | `3bf72c01e16c5cb6715a0f09ca37bbaf65d2a607eaa87b8d2f131962e49c567e` |
| `benchmarks/events-4ary.metta` | 4-Ary Security Audit ($N=5$) | 7 | `affb8fdc5fc8b6ebb507d84f8d58134de08a2440f2614630b6bd1f8ee6161c33` |
| `benchmarks/deep-chain.metta` | 5-Hop Relational Chain ($N=6$) | 7 | `7834b194bd248a01d99e41304e54df08b2894b14d816cb5807ee3bd23868d30b` |
| `benchmarks/deep-chain-8.metta` | 8-Hop Relational Chain ($N=6$) | 8 | `7e338461c32d076a4dc5553c537d371a1b9ea6f2af81ecccd4fdef8a89c82167` |
| `benchmarks/recursive-family.metta` | Transitive Datalog ($N=7$) | 5 base + rules | `5ae684089c221f68ff5880d193aefc15197512fdc04d43f57142075e6530a6b2` |
| `data.metta` | Original Family Facts | 5 | `db1324749f7e52d3f74087e59b2512f43cf2bf15d0ec36f8f53974c2e68f86f3` |

Verification command:
```bash
sha256sum benchmarks/*.metta
```

---

## 3. Automated Test Suite Execution

To run all 23 regression and generalization test suites:

```bash
MORK_BIN=bin/mork ./scripts/run-tests.sh
```

### Verified Test Results (100% Pass Rate: 369/369 Assertions)
```text
================================================================================
WARMR MORK Test Suite Runner
================================================================================
Workspace:   /home/hope/Projects/warmr-experiment
MORK Binary: bin/mork
Suites:      23
--------------------------------------------------------------------------------
  PASS: tests/anti-monotonicity-test.metta (12/12 assertions) [ 66 ms]
  PASS: tests/bias-test.metta            (34/34 assertions) [ 61 ms]
  PASS: tests/candidate-test.metta       (20/20 assertions) [ 69 ms]
  PASS: tests/canonicalize-test.metta    (19/19 assertions) [ 62 ms]
  PASS: tests/deep-search-test.metta     (19/19 assertions) [ 67 ms]
  PASS: tests/dynamic-depth-test.metta   (26/26 assertions) [ 79 ms]
  PASS: tests/empty-domain-test.metta    ( 3/ 3 assertions) [ 72 ms]
  PASS: tests/empty-level-test.metta     ( 8/ 8 assertions) [ 71 ms]
  PASS: tests/family-test.metta          (12/12 assertions) [ 62 ms]
  PASS: tests/generalized-numeric-test.metta ( 8/ 8 assertions) [ 62 ms]
  PASS: tests/higher-arity-test.metta    (14/14 assertions) [ 73 ms]
  PASS: tests/integration-test.metta     (28/28 assertions) [ 91 ms]
  PASS: tests/lifecycle-counting-test.metta (14/14 assertions) [ 56 ms]
  PASS: tests/max-length-test.metta      ( 5/ 5 assertions) [ 72 ms]
  PASS: tests/mm2-benchmark-test.metta   (29/29 assertions) [ 59 ms]
  PASS: tests/poc-support-test.metta     ( 2/ 2 assertions) [ 52 ms]
  PASS: tests/pruning-test.metta         (23/23 assertions) [ 76 ms]
  PASS: tests/recursive-datalog-test.metta (18/18 assertions) [167 ms]
  PASS: tests/search-loop-generic-test.metta (13/13 assertions) [114 ms]
  PASS: tests/support-test.metta         (13/13 assertions) [ 77 ms]
  PASS: tests/synthetic-test.metta       (15/15 assertions) [ 66 ms]
  PASS: tests/ternary-test.metta         (17/17 assertions) [ 67 ms]
  PASS: tests/unary-test.metta           (17/17 assertions) [ 65 ms]
--------------------------------------------------------------------------------
Test Execution Summary:
  Suites:     23 / 23 passed
  Assertions: 369 / 369 passed
Status:     ALL TESTS PASSED (100%)
================================================================================
```

---

## 4. End-to-End Production CLI Regression

To verify the production CLI across all 6 benchmark domains:

```bash
MORK_BIN=bin/mork ./scripts/test-cli-e2e.sh
```

### Verified E2E Results
```text
================================================================================
WARMR Production CLI End-to-End Regression Test Suite
================================================================================
  TEST [1] ugly-sodaDrinker (MM2 Benchmark) ... PASS (20 patterns verified)
  TEST [2] recursive-family (Transitive Chains) ... PASS (2 patterns verified)
  TEST [3] unary-properties (Arity 1 Attributes) ... PASS (3 patterns verified)
  TEST [4] ternary-transactions (Arity 3 Chaining) ... PASS (3 patterns verified)
  TEST [5] events-4ary (Arity 4 Quadruples) ... PASS (1 patterns verified)
  TEST [6] deep-chain-8 (Depths 1-8) ... PASS (8 patterns verified)
--------------------------------------------------------------------------------
End-to-End Test Summary:
  Total Benchmarks: 6
  Passed:           6
  Failed:           0
Status:             ALL E2E BENCHMARKS PASSED (100%)
================================================================================
```

---

## 4. End-to-End Benchmark Execution via CLI

### 4.1. Shared MM2 Benchmark (`ugly-sodaDrinker`)
```bash
./scripts/run-warmr.sh \
  --dataset benchmarks/ugly-sodaDrinker.metta \
  --keys benchmarks/ugly-sodaDrinker-keys.metta \
  --bias config/mm2-bias.metta \
  --min-support 2 \
  --max-length 3
```
*Expected Result:* Discovers all 20 frequent relational patterns across Levels 1–3 in ~10 ms.

### 4.2. Unary Properties Benchmark
```bash
./scripts/run-warmr.sh \
  --dataset benchmarks/unary-properties.metta \
  --keys benchmarks/unary-properties-keys.metta \
  --bias config/unary-bias.metta \
  --min-support 5 \
  --max-length 2
```
*Expected Result:* Discovers 3 frequent patterns (`active`, `verified`, and `active ∧ verified`) and prunes `premium` (support 4 < 5).

### 4.3. Recursive Family / Datalog Benchmark
```bash
./scripts/run-warmr.sh \
  --dataset benchmarks/recursive-family.metta \
  --keys benchmarks/family-keys.metta \
  --bias config/family-bias.metta \
  --min-support 2 \
  --max-length 2
```
*Expected Result:* Discovers 2 frequent patterns over base and recursively derived relations.

---

## 5. Known Limitations & Boundaries

1. **Automated BFS Staging:** Automated BFS candidate generation in `src/search-loop.metta` is explicitly staged for Levels 1–3. Multi-literal support evaluation is verified up to depth 5 in `tests/deep-search-test.metta`.
2. **Predicate Arities:** Supported templates include arities 1, 2, 3, and 4. Arities $\ge 5$ require adding corresponding mode extraction rules.
3. **Canonicalization:** Employs syntactic ordering (`sort-atom`) and variable indexing (`vars_to_indices`). Full semantic $\theta$-subsumption equivalence checking is NP-complete and not implemented.
4. **Phase 1 Only:** Implements frequent relational pattern discovery; association rule confidence generation ($Q_1 \Rightarrow Q_2$) is not yet implemented.
