# WARMR: Independent Relational Pattern Miner in MeTTa/MM2 on MORK

[![MORK Test Suite](https://img.shields.io/badge/tests-23%20suites%20%7C%20369%20passed-brightgreen)](#11-testing-and-verification)
[![Language](https://img.shields.io/badge/language-MeTTa%20%2F%20MM2-blue)](#8-architecture-and-project-structure)
[![Engine](https://img.shields.io/badge/engine-MORK%20(Rust)-orange)](#9-installation-and-execution)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

An independent, fully verified implementation of the **WARMR** (Dehaspe & Toivonen, 1999) frequent relational pattern mining algorithm, developed entirely in **MeTTa/MM2** and executed natively on **MORK** (Mork Operating Rule Kernel).

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [What Problem Does WARMR Solve?](#2-what-problem-does-warmr-solve)
3. [WARMR in Simple Terms](#3-warmr-in-simple-terms)
4. [Essential Concepts](#4-essential-concepts)
5. [Mathematical Foundation](#5-mathematical-foundation)
6. [How WARMR Works Step by Step](#6-how-warmr-works-step-by-step)
7. [Worked Example](#7-worked-example)
8. [Architecture and Project Structure](#8-architecture-and-project-structure)
9. [Installation and Execution](#9-installation-and-execution)
10. [Configuration](#10-configuration)
11. [Testing and Verification](#11-testing-and-verification)
12. [WARMR versus Pattern-miner-mm2](#12-warmr-versus-pattern-miner-mm2)
13. [Limitations](#13-limitations)
14. [Research References](#14-research-references)
15. [Future Work](#15-future-work)

---

## 1. Project Overview

This repository contains an independent, first-principles implementation of the **WARMR** relational pattern mining algorithm. 

The primary goal of this project is educational and scientific: to understand the foundational mechanisms of relational association mining, verify them against the original research literature, and compare our independent implementation with OpenCog Hyperon's existing pattern mining engine ([iCog-Labs-Dev/Pattern-miner-mm2](https://github.com/iCog-Labs-Dev/Pattern-miner-mm2)).

---

## 2. What Problem Does WARMR Solve?

Most classical data mining algorithms (like **Apriori** or **FP-Growth**) are designed for a single flat table, like supermarket shopping baskets:
- Transaction 1: `{ milk, bread }`
- Transaction 2: `{ beer, diapers }`

However, real-world data in biology, medicine, finance, and knowledge graphs is **multi-relational**:
- Entities live across multiple tables (e.g. `Patient`, `Diagnosis`, `Medication`, `LabTest`).
- Entities are connected by 1-to-many and many-to-many relationships (e.g., a patient can have many diagnoses over many hospital visits).

If you try to flatten multi-relational data into a single table:
1. **Counts become artificially distorted:** A patient with 10 visits gets counted 10 times more heavily than a patient with 1 visit.
2. **Relational structure is lost:** Information about how entities are linked together across multi-hop paths is destroyed.

**WARMR solves this problem:** It mines patterns directly across interconnected relational tables without flattening them, using **First-Order Horn Clause Logic (Datalog)**.

---

## 3. WARMR in Simple Terms

Imagine you are studying a medical database. You want to answer:
> *"What percentage of patients who have Condition A also take Medication B?"*

- **The Key Entity:** The patient (the person you are studying).
- **The Pattern:** A chain of relationships:
  $$\text{Patient}(X) \text{ has } \text{Diagnosis}(X, \text{Condition A}) \text{ and takes } \text{Prescription}(X, \text{Medication B})$$
- **WARMR's Rule:** Count each patient **at most once**, no matter how many times they visited the hospital or refilled their prescription.

WARMR starts with the simplest possible pattern ("Any patient") and systematically explores more specific patterns ("Patients with Condition A", "Patients with Condition A taking Medication B"), discarding patterns that are too rare (infrequent) to save computation.

---

## 4. Essential Concepts

| Concept | Explanation | Example |
|---|---|---|
| **ILP** | **Inductive Logic Programming**: Machine learning using first-order logic representations. | Mining rules over relational facts. |
| **Datalog** | A declarative logic programming language (a subset of Prolog) without function symbols. | `parent(X, Y), parent(Y, Z)` |
| **Relational Atom** | A relationship predicate applied to arguments (variables or constants). | `(parent abel hana)`, `(active user1)` |
| **Variable** | A placeholder for an entity in the query. In MORK, indexed as `(var 0)`, `(var 1)`. | `(var 0)` representing the key entity. |
| **Substitution ($\theta$)** | An assignment mapping variables to concrete database entities. | `{(var 0) -> abel, (var 1) -> hana}` |
| **Key Predicate** | The designated entity type being counted (the unit of analysis). | `positive_example(X)` |
| **Support** | The number of **distinct key entities** that satisfy the query. | 5 out of 20 people satisfy the pattern. |
| **Minimum Support** | The minimum frequency threshold a pattern must achieve to be kept. | `MIN_SUPPORT = 2` |
| **Language Bias (WRMODE)** | Declarative declarations constraining which patterns are valid to explore. | `modeh`, `modeb`, `determination` |
| **Input Slot (`+`)** | An argument in an added literal that **must** bind to an existing variable in the query. | Guarantees connectivity back to key. |
| **Output Slot (`-`)** | An argument in an added literal that introduces a **fresh** variable. | Expands the relational chain. |
| **Constant Slot (`#`)** | An argument in an added literal that binds to a ground constant from a domain pool. | `(Inheritance (var 0) (const man))` |
| **Specialization / Refinement ($\rho$)** | Extending an existing pattern by adding exactly one new valid relational atom. | $Q \rightarrow Q \wedge L$ |
| **Anti-Monotonicity** | The mathematical principle that adding constraints can only decrease or maintain support. | If $Q$ is rare, $Q \wedge L$ is also rare. |
| **Pruning** | Discarding all future specializations of an infrequent pattern without evaluating them. | `(prune_branch Q)` |

---

## 5. Mathematical Foundation

### 5.1. Query Satisfaction
Let $\mathcal{D}$ be the database and $\mathcal{B}$ background knowledge. A query $Q = ? - key(X), \text{Body}(X, \vec{Y})$ is satisfied by a key entity $k$ if:
$$\mathcal{D} \cup \mathcal{B} \models \exists \vec{Y} \text{Body}(k, \vec{Y})$$

### 5.2. Relational Support (Key-Projected Frequency)
$$\text{supp}_{\mathcal{D}}(Q) = |\{ k \in \mathcal{K} \mid \mathcal{D} \cup \mathcal{B} \models \exists \vec{Y} \text{Body}(k, \vec{Y}) \}|$$
where $\mathcal{K} = \{ k \mid key(k) \in \mathcal{D} \}$ is the set of positive key individuals ($N = |\mathcal{K}|$).

### 5.3. Relative Support (Frequency)
$$\text{rel\_supp}_{\mathcal{D}}(Q) = \frac{\text{supp}_{\mathcal{D}}(Q)}{|\mathcal{K}|} = \frac{\text{supp}_{\mathcal{D}}(Q)}{N}$$

### 5.4. Anti-Monotonicity Theorem
For any candidate query $Q$ and any specialization $Q' = Q \wedge L$:
$$\text{supp}_{\mathcal{D}}(Q') \le \text{supp}_{\mathcal{D}}(Q)$$
*Proof:* Every key entity that satisfies $Q'$ must satisfy $Q$. Therefore, the set of witnesses for $Q'$ is a subset of the witnesses for $Q$: $\{ k \mid Q'(k) \} \subseteq \{ k \mid Q(k) \}$. Cardinality cannot increase. $\blacksquare$

### 5.5. Association-Rule Confidence
Once frequent queries are found, rules $Q_1 \Rightarrow Q_2$ (where $\text{Body}(Q_1) \subset \text{Body}(Q_2)$) have confidence:
$$\text{conf}(Q_1 \Rightarrow Q_2) = \frac{\text{supp}(Q_2)}{\text{supp}(Q_1)}$$

---

## 6. How WARMR Works Step by Step

```text
Step 1: Compile Language Bias (modeh, modeb, determination, type_constant)
  │
Step 2: Count Key Domain Size (N = total key individuals)
  │
Step 3: Initialize Root Candidate Q0: key(X) <- true (Length 0, 100% support)
  │
Step 4: Level 1 Refinement rho(Q0): Generate all valid 1-literal queries
  │
Step 5: Canonicalize & Deduplicate (sort literals + re-index variables)
  │
Step 6: Evaluate Support against facts; project onto key variable (var 0)
  │
Step 7: Classify Frequent vs. Infrequent:
        - If support >= MIN_SUPPORT: Mark frequent; emit warmr_pattern record.
        - If support <  MIN_SUPPORT: Mark infrequent; PRUNE branch.
  │
Step 8: Expand Frequent Candidates to Level k+1 (Breadth-First Search)
  │
Step 9: Repeat until MAX_LENGTH is reached or no frequent candidates remain.
```

---

## 7. Worked Example

Consider five family relationships in `data.metta`:
```metta
(parent abel hana)
(parent hana sami)
(parent hana lidiya)
(parent bereket sara)
(parent sara noah)
```
Key individuals: `abel, hana, sami, lidiya, bereket, sara, noah` ($N = 7$).

Query (Grandparent):
$$Q(X) \leftarrow \text{parent}(X, Y) \wedge \text{parent}(Y, Z)$$

### Complete Satisfying Substitutions (3 tuples):
1. `(abel, hana, sami)`
2. `(abel, hana, lidiya)`
3. `(bereket, sara, noah)`

### WARMR Support under Key `positive_example(X)`:
- Proof 1 projects to: `abel` $\rightarrow$ `(key_witness Q abel)`
- Proof 2 projects to: `abel` $\rightarrow$ `(key_witness Q abel)` *(deduplicates in AtomSpace!)*
- Proof 3 projects to: `bereket` $\rightarrow$ `(key_witness Q bereket)`

**Distinct Key Support = 2 individuals** (`abel`, `bereket`).  
**Relative Support = 2 / 7 (28.6%)**.  
*Notice that complete matches (3) and distinct key support (2) are different!* Multi-proof deduplication prevents `abel` from being counted twice.

See [docs/worked-example.md](docs/worked-example.md) for full traces including binary keys.

---

## 8. Architecture and Project Structure

```text
warmr-experiment/
├── benchmarks/              # 8 Relational benchmark datasets & key adapters
│   ├── ugly-sodaDrinker.metta     # Shared MM2 benchmark (SHA256: 3b8b322...)
│   ├── unary-properties.metta     # Unary property dataset (N=10)
│   ├── ternary-transactions.metta # Ternary banking transactions (N=6)
│   ├── events-4ary.metta          # 4-ary security audit events (N=5)
│   ├── deep-chain.metta           # 5-hop relational chain (N=6)
│   ├── recursive-family.metta     # Transitive closure Datalog dataset (N=7)
│   └── synthetic-genes.metta      # Gene regulation pathways (N=3)
├── config/                  # Language-bias mode declarations
│   ├── mm2-bias.metta             # Mode declarations for ugly-sodaDrinker
│   ├── unary-bias.metta           # Bias for unary properties
│   ├── ternary-bias.metta         # Bias for ternary transactions
│   ├── events-4ary-bias.metta     # Bias for 4-ary audit events
│   ├── deep-chain-bias.metta      # Bias for deep chains
│   └── family-bias.metta          # Bias for family relationships
├── docs/                    # In-depth architectural & algorithmic documentation
│   ├── algorithm.md               # Algorithmic foundations, pseudocode, support & pruning
│   ├── architecture.md            # MORK staged pipeline & PathMap priorities
│   ├── benchmarks.md              # Detailed benchmark dataset reference
│   ├── limitations.md             # System boundaries & verified scope
│   ├── pattern-miner-mm2-comparison.md # 25-dimension MM2 vs WARMR matrix & recommendations
│   ├── verification-and-reproducibility.md # Environment, checksums & CLI guide
│   └── worked-example.md          # Concrete substitution & deduplication trace
├── reports/                 # Milestone release audit reports
├── scripts/                 # Hardened CLI runners
│   ├── run-warmr.sh               # Command-line miner runner
│   └── run-tests.sh               # Automated test suite runner
├── src/                     # Core WARMR engine implementation in MeTTa/MM2
│   ├── data-model.metta           # Foundational data model & key representations
│   ├── language-bias.metta        # Declarative mode compiler (+, -, #)
│   ├── candidate-gen.metta        # Candidate refinement operator rho(Q)
│   ├── canonicalize.metta         # Structural atom sorting & variable re-indexing
│   ├── support-calc.metta         # Multi-literal query evaluation & counting
│   ├── pruning.metta              # 64-bit arithmetic & anti-monotonic pruning
│   ├── search-loop.metta          # Level-wise BFS search driver
│   ├── warmr.metta                # Top-level pipeline coordinator
│   └── output.metta               # Standardized pattern record formatter
├── tests/                   # 23 automated test suites (369 assertions)
└── README.md                # Project documentation
```

---

## 9. Installation and Execution

### Requirements
- Linux (x86_64)
- Bash 4.4+
- Compiled MORK binary (`mork` or `bin/mork`)

### Running the Miner via CLI
```bash
# Shared MM2 Benchmark
./scripts/run-warmr.sh \
  --dataset benchmarks/ugly-sodaDrinker.metta \
  --keys benchmarks/ugly-sodaDrinker-keys.metta \
  --bias config/mm2-bias.metta \
  --min-support 2 \
  --max-length 3

# Deep Relational Chain (Depths 1-8)
./scripts/run-warmr.sh \
  --dataset benchmarks/deep-chain-8.metta \
  --keys benchmarks/deep-chain-keys.metta \
  --bias config/deep-chain-bias.metta \
  --min-support 1 \
  --max-depth 8
```

---

## 10. Configuration

Configured at runtime via CLI arguments:
- `--dataset <path>`: Background relational facts (`.metta`).
- `--keys <path>`: Positive example key individuals (`.metta`).
- `--bias <path>`: Language-bias mode declarations (`.metta`).
- `--min-support <int>`: Minimum absolute key support threshold ($\ge 0$).
- `--max-length <int>` or `--max-depth <int>`: Maximum query length to explore ($\ge 1$).

---

## 11. Testing and Verification

Execute the complete regression and generalization test suite:
```bash
MORK_BIN=bin/mork ./scripts/run-tests.sh
```

Execute the automated production CLI end-to-end regression across all 6 benchmarks:
```bash
MORK_BIN=bin/mork ./scripts/test-cli-e2e.sh
```

**Status:** **23 / 23 test suites passed** with **369 / 369 passing assertions (100%)** in ~1.5 s.

| Test Suite | Assertions | Status |
|---|:---:|:---:|
| `tests/bias-test.metta` | 20 / 20 | PASS |
| `tests/candidate-test.metta` | 19 / 19 | PASS |
| `tests/canonicalize-test.metta` | 19 / 19 | PASS |
| `tests/deep-search-test.metta` | 19 / 19 | PASS |
| `tests/dynamic-depth-test.metta` | 26 / 26 | PASS |
| `tests/anti-monotonicity-test.metta` | 12 / 12 | PASS |
| `tests/lifecycle-counting-test.metta` | 14 / 14 | PASS |
| `tests/search-loop-generic-test.metta` | 13 / 13 | PASS |
| `tests/empty-domain-test.metta` | 3 / 3 | PASS |
| `tests/empty-level-test.metta` | 8 / 8 | PASS |
| `tests/family-test.metta` | 12 / 12 | PASS |
| `tests/generalized-numeric-test.metta` | 8 / 8 | PASS |
| `tests/higher-arity-test.metta` | 14 / 14 | PASS |
| `tests/integration-test.metta` | 28 / 28 | PASS |
| `tests/max-length-test.metta` | 5 / 5 | PASS |
| `tests/mm2-benchmark-test.metta` | 29 / 29 | PASS |
| `tests/poc-support-test.metta` | 2 / 2 | PASS |
| `tests/pruning-test.metta` | 23 / 23 | PASS |
| `tests/recursive-datalog-test.metta` | 18 / 18 | PASS |
| `tests/support-test.metta` | 13 / 13 | PASS |
| `tests/synthetic-test.metta` | 15 / 15 | PASS |
| `tests/ternary-test.metta` | 17 / 17 | PASS |
| `tests/unary-test.metta` | 17 / 17 | PASS |

---

## 12. WARMR versus Pattern-miner-mm2

| Feature | WARMR | Pattern-miner-mm2 |
|---|---|---|
| **Support Definition** | **Key-based entity support:** Distinct key entities satisfying query. | **Valuation count:** Every satisfying tuple match across facts. |
| **Multi-Proof Deduplication** | Yes (witnesses collapse in AtomSpace set). | No (all combination matches are counted). |
| **Predicate Arity** | Unary, Binary, Ternary, 4-Ary. | Strictly Binary Triplet (`$pred $left $right`). |
| **Language Bias** | Declarative modes (`modeh`, `modeb`, `+`, `-`, `#`). | None (positional triplet mapping). |
| **Recursive Datalog** | Supported (transitive closure derivation in AtomSpace). | None (strictly extensional facts). |
| **Surprisingness** | None (frequency and relative support). | Information-theoretic ISURP / JSD using Beta CDF. |

See [docs/pattern-miner-mm2-comparison.md](docs/pattern-miner-mm2-comparison.md) for the complete 25-dimension matrix.

---

## 13. Limitations

- **Search Depth:** Empirically verified up to depth 5. Automated BFS driver is staged for Levels 1–3.
- **Arities:** Templated for arities 1, 2, 3, and 4. Arities $\ge 5$ require adding mode extraction rules.
- **Subsumption:** Uses syntactic canonicalization (`sort-atom` + $\alpha$-norm). Full semantic $\theta$-subsumption is NP-complete and not implemented.
- **Rule Generation:** Phase 1 (frequent pattern discovery) is implemented; Phase 2 (rule confidence generation) is not yet implemented.

See [docs/limitations.md](docs/limitations.md) for detailed boundaries.

---

## 14. Research References

1. Dehaspe, L. and Toivonen, H. (1999). **Discovery of Frequent Datalog Patterns.** *Data Mining and Knowledge Discovery*, 3, 7–36.
2. Dehaspe, L. and De Raedt, L. (1997). **Mining Association Rules in Multiple Relations.** *ILP-97*.
3. iCog-Labs Pattern Miner MM2: https://github.com/iCog-Labs-Dev/Pattern-miner-mm2

---

## 15. Future Work

1. Implement Phase 2: Relational association-rule generation ($Q_1 \Rightarrow Q_2$) with confidence calculation.
2. Port WARMR's key-projected support into `Pattern-miner-mm2` as an optional support mode.
3. Add a dynamic conjunction unifier in MORK to support arbitrary conjunction lengths beyond Level 5 without manual staging.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
