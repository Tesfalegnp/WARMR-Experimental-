# Shared Benchmark: ugly-sodaDrinker

## 1. Provenance and Metadata

- **Upstream Repository:** `https://github.com/iCog-Labs-Dev/Pattern-miner-mm2.git`
- **Origin Fork:** `https://github.com/Tesfalegnp/Pattern-miner-mm2.git`
- **Inspected Commit:** `3d97dc45aaf37c47be99485e1cb53a449da11140`
- **Source File:** `data/ugly-sodaDrinker.metta`
- **SHA256 Checksum:** `3b8b32224004667108e4560001c78861faf833ddb498f7b6a62f92aaecc223b8`
- **Dataset Structure:** 60 relational `(Inheritance <Person> <Attribute>)` facts covering 20 individuals and 5 attributes.

## 2. Key Domain Adapter for WARMR

WARMR evaluates frequent relational queries over a designated **key predicate** (e.g. `positive_example/1`). Support in WARMR is defined as the number of distinct key entities that satisfy the query body.

In contrast, Pattern Miner MM2 operates directly over unanchored expressions or tree valuations.

To enable direct, apples-to-apples comparison on this shared dataset without modifying the original relations, a domain adapter was created:
- Exactly 20 `(positive_example <Person>)` facts were derived from the unique individuals appearing in the first slot of `Inheritance`.
- In Milestone 6, these 20 adapter facts are stored in `benchmarks/ugly-sodaDrinker-keys.metta`.
- The dataset file `benchmarks/ugly-sodaDrinker.metta` is restored to exact byte-for-byte identity with the upstream repository (`SHA256: 3b8b322...`, exactly 60 original facts, zero extra lines).
- This guarantees full provenance and byte-level fidelity while allowing WARMR to bind its key domain cleanly via the adapter.

## 3. Investigation of Historical Count Discrepancy (19 vs 20)

Earlier research notes and Pattern Miner MM2 test fixtures recorded 19 individuals for `human` rather than 20.

Git commit inspection of the source repository revealed the exact root cause:
- **Commit:** `1ecafb81ab6b7ef4516c8616c52823116b00226b`
- **Author:** Eyerusalem Hailemariam
- **Commit Message:** `Update data/ugly-sodaDrinker.metta: Add missing Allen human classification`
- **Diff:** Added `(Inheritance Allen human)` to the dataset.

Prior to commit `1ecafb8`, `Allen` possessed `(Inheritance Allen man)`, `ugly`, and `sodaDrinker`, but was missing `human`. Following the commit, all 20 individuals possess the `human` attribute.

Therefore, the ground truth verified against the actual repository file (`3b8b322...`) is:
- `Inheritance(A, human)`: **20**
- `human(A), man(A)`: **10**
- `human(A), woman(A)`: **10**
- `human(A), ugly(A)`: **10**
- `human(A), sodaDrinker(A)`: **10**

## 4. Ground Truth Support Table

| Candidate Query | Form | Expected Distinct-Key Support | Relative Support ($N=20$) |
| :--- | :--- | ---:| ---:|
| `Inheritance(A, human)` | Level 1 | **20** | 100.0% ($20/20$) |
| `Inheritance(A, man)` | Level 1 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, woman)` | Level 1 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, ugly)` | Level 1 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, sodaDrinker)` | Level 1 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, man)` | Level 2 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, woman)` | Level 2 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, ugly)` | Level 2 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, sodaDrinker)` | Level 2 | **10** | 50.0% ($10/20$) |
| `Inheritance(A, man) ∧ Inheritance(A, ugly)` | Level 2 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, man) ∧ Inheritance(A, sodaDrinker)` | Level 2 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, woman) ∧ Inheritance(A, ugly)` | Level 2 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, woman) ∧ Inheritance(A, sodaDrinker)` | Level 2 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, ugly) ∧ Inheritance(A, sodaDrinker)` | Level 2 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, man) ∧ Inheritance(A, ugly)` | Level 3 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, man) ∧ Inheritance(A, sodaDrinker)` | Level 3 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, woman) ∧ Inheritance(A, ugly)` | Level 3 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, woman) ∧ Inheritance(A, sodaDrinker)` | Level 3 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, human) ∧ Inheritance(A, ugly) ∧ Inheritance(A, sodaDrinker)` | Level 3 | **5** | 25.0% ($5/20$) |
| `Inheritance(A, man) ∧ Inheritance(A, ugly) ∧ Inheritance(A, sodaDrinker)` | Level 3 | **5** | 25.0% ($5/20$) |

Note: `Inheritance(A, man) ∧ Inheritance(A, woman)` has absolute support **0** and is pruned by anti-monotonic search, preventing all 4 Level 3 candidates containing both `man` and `woman` from being generated.

## 5. Execution Instructions

Run WARMR on the MM2 benchmark dataset:
```bash
./scripts/run-warmr.sh \
  --dataset benchmarks/ugly-sodaDrinker.metta \
  --keys benchmarks/ugly-sodaDrinker-keys.metta \
  --bias config/mm2-bias.metta \
  --min-support 5 \
  --max-length 3 \
  --dataset-id ugly_soda_drinker
```

Run WARMR on the Family relational chaining dataset:
```bash
./scripts/run-warmr.sh \
  --dataset data.metta \
  --keys benchmarks/family-keys.metta \
  --bias config/family-bias.metta \
  --min-support 2 \
  --max-length 2 \
  --dataset-id family_ancestors
```

Run WARMR on the Synthetic gene pathway dataset:
```bash
./scripts/run-warmr.sh \
  --dataset benchmarks/synthetic-genes.metta \
  --keys benchmarks/synthetic-genes-keys.metta \
  --bias config/synthetic-bias.metta \
  --min-support 2 \
  --max-length 2 \
  --dataset-id synthetic_genes
```

Run all automated test suites:
```bash
./scripts/run-tests.sh
```
