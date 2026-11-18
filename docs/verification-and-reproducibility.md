# Verification and Reproducibility Guide

This document provides complete instructions, environment specifications, verified commands, and ground-truth references for reproducing all experimental results of the independent WARMR relational pattern miner in MeTTa/MM2 on MORK.

---

## 1. System & Environment Specifications

- **Operating System:** Linux (x86_64)
- **Execution Engine:** Native MORK compiler binary (`/home/hope/.local/bin/mork`)
- **Git Commit:** `527ff5108d80e87c2b91a8d6b21cae833b0f3d21` (Repository: `https://github.com/Tesfalegnp/WARMR-Experimental-.git`, branch `main`)
- **Comparative Target:** `https://github.com/iCog-Labs-Dev/Pattern-miner-mm2.git` (commit `153afdae240d5235cdd045112f5d04b4bfb397a0`)

---

## 2. Dataset Provenance & SHA256 Checksums

| Dataset File | Role / Domain | Fact Count | Verified SHA256 Checksum |
|---|---|:---:|---|
| `benchmarks/ugly-sodaDrinker.metta` | Shared MM2 Benchmark | 60 | `3b8b32224004667108e4560001c78861faf833ddb498f7b6a62f92aaecc223b8` |
| `benchmarks/unary-properties.metta` | Unary Relations ($N=10$) | 18 | `3f2dbd486fa4a34b22db7f7b11c97a892b1a1ddf6b7fa26d03cf1975e54d89a7` |
| `benchmarks/ternary-transactions.metta` | Ternary Banking ($N=6$) | 8 | `51e3be288a444155b9e072bfa0446757f5c53ca7d3ad08660bc5ad29ee33d317` |
| `benchmarks/events-4ary.metta` | 4-Ary Security Audit ($N=5$) | 7 | `38b4d8d1e3dbe7cf8aaefbc59dfdb0f4f9dc6e8d2f2d93e18a4a581eebc9535f` |
| `benchmarks/deep-chain.metta` | 5-Hop Relational Chain ($N=6$) | 7 | `0937a4c4e7fb2fbdf404523c14aee6581412e2fa9d5e3056094b8eec1ea74d15` |
| `benchmarks/recursive-family.metta` | Transitive Datalog ($N=7$) | 5 base + rules | `f0fa7ae7ce4ff5f225893a95d73ddcbbe0272cbb0926ff48c084f7fa32ad51cf` |
| `data.metta` | Original Family Facts | 5 | `db1324749f7e52d3f74087e59b2512f43cf2bf15d0ec36f8f53974c2e68f86f3` |

Verification command:
```bash
sha256sum benchmarks/ugly-sodaDrinker.metta
```

---

## 3. Automated Test Suite Execution

To run all 19 regression and generalization test suites:

```bash
./scripts/run-tests.sh
```

### Verified Test Results (100% Pass Rate: 270/270 Assertions)
```text
================================================================================
WARMR MORK Test Suite Runner
================================================================================
Workspace:   /home/hope/Projects/warmr-experiment
MORK Binary: /home/hope/.local/bin/mork
Suites:      19
--------------------------------------------------------------------------------
  PASS: tests/bias-test.metta            (15/15 assertions) [ 45 ms]
  PASS: tests/candidate-test.metta       (17/17 assertions) [ 55 ms]
  PASS: tests/canonicalize-test.metta    ( 7/ 7 assertions) [ 50 ms]
  PASS: tests/deep-search-test.metta     (19/19 assertions) [ 64 ms]
  PASS: tests/empty-domain-test.metta    ( 3/ 3 assertions) [ 53 ms]
  PASS: tests/empty-level-test.metta     ( 8/ 8 assertions) [ 63 ms]
  PASS: tests/family-test.metta          (12/12 assertions) [ 50 ms]
  PASS: tests/generalized-numeric-test.metta ( 8/ 8 assertions) [ 43 ms]
  PASS: tests/higher-arity-test.metta    (14/14 assertions) [ 48 ms]
  PASS: tests/integration-test.metta     (28/28 assertions) [ 60 ms]
  PASS: tests/max-length-test.metta      ( 5/ 5 assertions) [ 54 ms]
  PASS: tests/mm2-benchmark-test.metta   (29/29 assertions) [ 48 ms]
  PASS: tests/poc-support-test.metta     ( 2/ 2 assertions) [ 52 ms]
  PASS: tests/pruning-test.metta         (23/23 assertions) [ 58 ms]
  PASS: tests/recursive-datalog-test.metta (18/18 assertions) [ 46 ms]
  PASS: tests/support-test.metta         (13/13 assertions) [ 60 ms]
  PASS: tests/synthetic-test.metta       (15/15 assertions) [ 70 ms]
  PASS: tests/ternary-test.metta         (17/17 assertions) [ 43 ms]
  PASS: tests/unary-test.metta           (17/17 assertions) [ 63 ms]
--------------------------------------------------------------------------------
Test Execution Summary:
  Suites:     19 / 19 passed
  Assertions: 270 / 270 passed
Status:     ALL TESTS PASSED (100%)
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
