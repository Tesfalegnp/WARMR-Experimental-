# Relational Benchmark Suites and Ground-Truth Evaluation

This directory contains eight verified relational benchmark suites used to evaluate the independent WARMR pattern miner in MeTTa/MM2 on MORK.

---

## 1. Benchmark Summary Table

| Benchmark | Dataset File | Key Adapter | Bias File | Keys ($N$) | Arities Tested | Max Depth | Verified Patterns |
|---|---|---|---|:---:|:---:|:---:|:---:|
| **Shared MM2 Benchmark** | `ugly-sodaDrinker.metta` | `ugly-sodaDrinker-keys.metta` | `mm2-bias.metta` | 20 | Binary (2) | 3 | 20 frequent |
| **Unary Properties** | `unary-properties.metta` | `unary-properties-keys.metta` | `unary-bias.metta` | 10 | Unary (1) | 2 | 3 frequent |
| **Ternary Transactions** | `ternary-transactions.metta` | `ternary-transactions-keys.metta` | `ternary-bias.metta` | 6 | Ternary (3) | 2 | 2 frequent |
| **4-Ary Security Events** | `events-4ary.metta` | `events-4ary-keys.metta` | `events-4ary-bias.metta` | 5 | 4-Ary (4) | 2 | 2 frequent |
| **Deep Relational Chain** | `deep-chain.metta` | `deep-chain-keys.metta` | `deep-chain-bias.metta` | 6 | Binary (2) | 5 | 4 frequent, 1 pruned |
| **Recursive Family Datalog** | `recursive-family.metta` | `family-keys.metta` | `family-bias.metta` | 7 | Binary (2) + Intensional | 2 | 2 frequent |
| **Synthetic Gene Pathways** | `synthetic-genes.metta` | `synthetic-genes-keys.metta` | `synthetic-bias.metta` | 3 | Binary (2) | 2 | 2 frequent |
| **Original Family Dataset** | `data.metta` | `family-keys.metta` | `family-bias.metta` | 7 | Binary (2) | 2 | 2 frequent |

---

## 2. Detailed Dataset Specifications

### 2.1. Shared MM2 Benchmark (`benchmarks/ugly-sodaDrinker.metta`)
- **Origin:** Reference benchmark shared with `iCog-Labs-Dev/Pattern-miner-mm2`.
- **SHA256:** `3b8b32224004667108e4560001c78861faf833ddb498f7b6a62f92aaecc223b8`
- **Fact Count:** Exactly 60 relational facts (`Inheritance` relations).
- **Target Key Domain:** 20 individuals (`person1` through `person20`).
- **Configured Thresholds:** `MIN_SUPPORT = 2`, `MAX_LENGTH = 3`.
- **CLI Execution:**
  ```bash
  ./scripts/run-warmr.sh \
    --dataset benchmarks/ugly-sodaDrinker.metta \
    --keys benchmarks/ugly-sodaDrinker-keys.metta \
    --bias config/mm2-bias.metta \
    --min-support 2 \
    --max-length 3
  ```
- **Discovered Patterns:**
  - **Level 1 (5 patterns):** `human` (20/20), `man` (10/20), `woman` (10/20), `ugly` (10/20), `sodaDrinker` (10/20).
  - **Level 2 (9 patterns):** `human ∧ man` (10/20), `human ∧ woman` (10/20), `human ∧ ugly` (10/20), `human ∧ sodaDrinker` (10/20), `man ∧ ugly` (5/20), `man ∧ sodaDrinker` (5/20), `woman ∧ ugly` (5/20), `woman ∧ sodaDrinker` (5/20), `ugly ∧ sodaDrinker` (5/20).
  - **Level 3 (6 patterns):** `man ∧ ugly ∧ sodaDrinker` (5/20), `human ∧ man ∧ ugly` (5/20), `human ∧ man ∧ sodaDrinker` (5/20), `human ∧ woman ∧ ugly` (5/20), `human ∧ woman ∧ sodaDrinker` (5/20), `human ∧ ugly ∧ sodaDrinker` (5/20).
  - **Total Discovered:** **20 frequent patterns**.

---

### 2.2. Unary Properties Benchmark (`benchmarks/unary-properties.metta`)
- **Purpose:** Verifies single-argument relation mining ($k=1$), conjunctions of unary properties, and anti-monotonic pruning.
- **Predicates:** `active(user)`, `verified(user)`, `premium(user)`.
- **Key Domain:** 10 users (`user1` .. `user10`).
- **Configured Thresholds:** `MIN_SUPPORT = 5`, `MAX_LENGTH = 2`.
- **CLI Execution:**
  ```bash
  ./scripts/run-warmr.sh \
    --dataset benchmarks/unary-properties.metta \
    --keys benchmarks/unary-properties-keys.metta \
    --bias config/unary-bias.metta \
    --min-support 5 \
    --max-length 2
  ```
- **Ground Truth:**
  - `active(X)`: 8 / 10 (**Frequent**)
  - `verified(X)`: 6 / 10 (**Frequent**)
  - `premium(X)`: 4 / 10 (**Infrequent** — pruned at Level 1)
  - `active(X) ∧ verified(X)`: 6 / 10 (**Frequent**)

---

### 2.3. Ternary Transactions Benchmark (`benchmarks/ternary-transactions.metta`)
- **Purpose:** Evaluates 3-argument relations with mixed input, output, and constant argument slots: `transfer(+account, -account, #bank)`.
- **Key Domain:** 6 accounts (`acc1` .. `acc6`).
- **Multi-Proof Invariant:** `acc1` transfers to multiple recipient accounts via `chase`; collapses into exactly 1 key witness.
- **Configured Thresholds:** `MIN_SUPPORT = 2`, `MAX_LENGTH = 2`.
- **Ground Truth:**
  - `transfer(X, Y, chase)`: 2 / 6 (`acc1`, `acc2` -> **Frequent**)
  - `transfer(X, Y, Z)`: 5 / 6 (`acc1`..`acc5` -> **Frequent**)
  - `transfer(X, Y, unknown_bank)`: 0 / 6 (**Infrequent** — pruned)
  - `transfer(X, Y, chase) ∧ transfer(Y, Z, chase)`: 1 / 6 (`acc1` -> **Infrequent**)

---

### 2.4. 4-Ary Security Audit Events Benchmark (`benchmarks/events-4ary.metta`)
- **Purpose:** Evaluates 4-argument relations: `audit_log(+user, #service, #action, #region)`.
- **Key Domain:** 5 users (`alice`, `bob`, `charlie`, `david`, `eve`).
- **Configured Thresholds:** `MIN_SUPPORT = 2`, `MAX_LENGTH = 2`.
- **Ground Truth:**
  - `audit_log(X, s3, read, us_east)`: 3 / 5 (`alice`, `bob`, `charlie` -> **Frequent**)
  - `audit_log(X, Y, Z, eu_west)`: 2 / 5 (`alice`, `david` -> **Frequent**)
  - `audit_log(X, k8s, Y, Z)`: 0 / 5 (**Infrequent** — pruned)
  - `audit_log(X, s3, read, us_east) ∧ audit_log(X, Y, Z, eu_west)`: 1 / 5 (`alice` -> **Infrequent**)

---

### 2.5. Deep Relational Chain Benchmark (`benchmarks/deep-chain.metta`)
- **Purpose:** Evaluates long-range transitive relational conjunctions from length 1 to length 5.
- **Key Domain:** 6 nodes (`n0` .. `n5`).
- **Multi-Proof Invariant at Depth 5:** Node `n0` has two distinct 5-hop paths (`n0 -> n1 -> n2 -> n3 -> n4 -> n5` and `n0 -> n1_alt -> n2 -> n3 -> n4 -> n5`), collapsing into 1 distinct key witness.
- **Configured Thresholds:** `MIN_SUPPORT = 2`, `MAX_LENGTH = 5`.
- **Ground Truth:**
  - Length 1 (`step(A, B)`): 5 / 6 (**Frequent**)
  - Length 2 (`step(A, B) ∧ step(B, C)`): 4 / 6 (**Frequent**)
  - Length 3 (`step(A, B) ∧ ... ∧ step(C, D)`): 3 / 6 (**Frequent**)
  - Length 4 (`step(A, B) ∧ ... ∧ step(D, E)`): 2 / 6 (**Frequent**)
  - Length 5 (`step(A, B) ∧ ... ∧ step(E, F)`): 1 / 6 (`n0` -> **Infrequent** — pruned)

---

### 2.6. Recursive Family / Datalog Benchmark (`benchmarks/recursive-family.metta`)
- **Purpose:** Evaluates WARMR pattern discovery over intensional background relations derived through recursive Datalog deduction:
  $$\text{ancestor}(X, Y) \leftarrow \text{parent}(X, Y)$$
  $$\text{ancestor}(X, Y) \leftarrow \text{parent}(X, Z) \wedge \text{ancestor}(Z, Y)$$
- **Key Domain:** 7 individuals (`abel`, `hana`, `sami`, `lidiya`, `bereket`, `sara`, `noah`).
- **Ground Truth:**
  - `ancestor(X, Y)`: 4 / 7 (`abel`, `hana`, `bereket`, `sara` -> **Frequent**)
  - `ancestor(X, noah)`: 3 / 7 (`abel`, `bereket`, `sara` -> **Frequent**)
  - `ancestor(X, unknown)`: 0 / 7 (**Infrequent** — pruned)
