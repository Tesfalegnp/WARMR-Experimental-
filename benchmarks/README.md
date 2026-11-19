# Shared Benchmark: ugly-sodaDrinker


## 2. Key Domain Adapter for WARMR

WARMR evaluates frequent relational queries over a designated **key predicate** (e.g. `positive_example/1`). Support in WARMR is defined as the number of distinct key entities that satisfy the query body.

In contrast, Pattern Miner MM2 operates directly over unanchored expressions or tree valuations.

To enable direct, apples-to-apples comparison on this shared dataset without modifying the original relations, a domain adapter was created:
- Exactly 20 `(positive_example <Person>)` facts were derived from the unique individuals appearing in the first slot of `Inheritance`.
- In Milestone 6, these 20 adapter facts are stored in `benchmarks/ugly-sodaDrinker-keys.metta`.
- The dataset file `benchmarks/ugly-sodaDrinker.metta` is restored to exact byte-for-byte identity with the upstream repository (`SHA256: 3b8b322...`, exactly 60 original facts, zero extra lines).
- This guarantees full provenance and byte-level fidelity while allowing WARMR to bind its key domain cleanly via the adapter.

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
