# System Boundaries, Engineering Scope, and Known Limitations

This document provides a factual, evidence-based description of the capabilities, verified boundaries, and genuine technical limitations of the independent WARMR implementation in MeTTa/MM2 on MORK.

---

## 1. Verified Search Depth vs. Arbitrary Depth

### Implemented Capability
- The engine supports level-wise breadth-first search (BFS) with dynamic candidate generation, evaluation, and level transitions up to **depth 8**.
- Evaluated and verified across depths 1 through 8 on synthetic relational chains (`Length 8` in `tests/dynamic-depth-test.metta` and `benchmarks/deep-chain-8.metta`).
- Multi-hop relational chaining and branched constant matching are verified for lengths 1, 2, 3, 4, 5, 6, 7, and 8 against an independent reference oracle (`scripts/verify-depth-oracle.py`).
- Configurable maximum search depth is fully supported in the production CLI via `--max-length N` or `--max-depth N`.
- Anti-monotonic Apriori pruning and empty-frontier termination cleanly halt search when candidate frontiers become empty before reaching the configured maximum depth cutoff.

### Limitation & Boundary
- **Do not claim arbitrary infinite search depth without bounds.**
- The MORK engine uses priority-staged term rewriting passes. While the search progression across depths 1 through 8 is completely dynamic, conjunction matching templates and stage transitions are currently implemented up to length 8.
- Arbitrary depths $d > 8$ would require defining additional stage expansion blocks.
- In practical relational data mining and ILP research, patterns beyond length 4 or 5 are rarely mined due to combinatorial hypothesis space explosion ($\mathcal{O}(|\mathcal{P}|^k)$).

---

## 2. Relational Predicate Arities

### Implemented Capability
- **Unary (Arity 1):** Supported (`active(+user)`).
- **Binary (Arity 2):** Supported (`parent(+person, -person)`, `Inheritance(+entity, #type)`).
- **Ternary (Arity 3):** Supported (`transfer(+account, -account, #bank)`).
- **4-Ary (Arity 4):** Supported (`audit_log(+user, #service, #action, #region)`).

### Limitation & Boundary
- Relations with arity $\ge 5$ are not currently templated in `src/candidate-gen.metta` or `src/support-calc.metta`.
- Arbitrary n-ary relational predicates require adding mode slot validation and unification rules for the respective arities.

---

## 3. Candidate Canonicalization and $\theta$-Subsumption

### Implemented Capability
- **Atom Permutation Normalization:** Relational body literals are sorted lexicographically via MORK's pure `sort-atom` primitive ($L_1 \wedge L_2 \equiv L_2 \wedge L_1$).
- **Duplicate Literal Elimination (Idempotence):** Collapses duplicate identical literals in conjunctions ($Q \wedge L \wedge L \equiv Q \wedge L$) to prevent tautological self-conjunctions.
- **Alpha-Renaming Normalization:** Variables are re-indexed from left to right sequentially starting at `(var 0)` via `indices_to_vars` and `vars_to_indices`.
- **Equivalence Invariants:** Strictly preserves constant distinctions, predicate argument ordering, and repeated variable relationships (e.g., $related(X, X) \not\equiv related(X, Y)$).
- **Production Deduplication:** Loaded into `scripts/run-warmr.sh` and verified across benchmark datasets to guarantee single canonical evaluation.

### Limitation & Boundary
- **Syntactic Normalization vs. Semantic $\theta$-Subsumption:**
  - The engine normalizes syntactic permutations, duplicate literals, and variable renamings ($\alpha$-equivalence).
  - It does **not** solve full semantic $\theta$-subsumption equivalence checking (e.g., checking if $Q_1 \succeq_\theta Q_2$ and $Q_2 \succeq_\theta Q_1$ when literals can fold onto themselves, such as $p(X, Y) \wedge p(Y, X)$ vs $p(X, X)$).
  - Full $\theta$-subsumption is NP-complete. In ILP and WARMR, syntactic canonicalization combined with language bias is the standard approach.


---

## 4. Search Loop and Predicate / Constant Ordering

### Implemented Capability
- **Generic Lexicographical Ordering Compilation:**
  - Evaluates candidate pairs $(A, B)$ using MORK's pure `sort-atom` to synthesize strict, anti-symmetric orders (`unary_lt` and `attr_lt`).
  - Works with arbitrary new predicate names and constant domains without modifying the engine source code.
  - Automatically filters reflexive pairings ($P \land P$) to prevent tautological self-conjunctions.
  - Guarantees that any pair of distinct unary predicates or constants is explored in exactly one deterministic direction, preventing duplicate permutation evaluations.
  - Supports benchmark fallback declarations (`default_attr_lt`, `default_unary_lt`) for legacy test compatibility.

### Limitation & Boundary
- **Higher-Arity Argument Pairings:**
  - Automatic ordering synthesis currently covers unary predicate pairs and attribute constant pairs on key variables.
  - Arbitrary permutations of ternary or 4-ary relations with mixed free variables rely on language bias slot modes and canonicalization rather than pairwise enumeration guards.

---

## 5. Negation and Monotonicity

### Implemented Capability
- Fully supports positive definite relational Horn clauses:
  $$Q = \text{key}(X) \leftarrow P_1(\dots) \wedge \dots \wedge P_k(\dots)$$
- Supports monotonic recursive Datalog rules (e.g. transitive closure).

### Limitation & Boundary
- Non-monotonic negation (Negation-as-Failure / `\+` / `not`) is excluded from the language bias.
- Relational aggregation operators (`count`, `sum`, `avg` over nested bags) within candidate pattern bodies are not supported.
- Anti-monotonic pruning relies strictly on monotonicity: adding positive body literals can only decrease or preserve support. Introducing negation or non-monotonic constructs would invalidate anti-monotonic pruning.

---

## 5. Comparative Semantics: WARMR vs. Hyperon Pattern Miner MM2

### Crucial Semantic Distinction
- **WARMR Support (Key Witness Projection):**
  Support is defined as the fraction of *distinct positive key entities* $K$ that satisfy the relational query. Multiple matching proofs for the same individual collapse into **1** key witness.
- **Pattern Miner MM2 Support (Hypergraph Subgraph Matching):**
  Counts matching valuation instances or target space hypergraph link occurrences.
- **Conclusion:**
  WARMR and MM2 are solving relational pattern discovery under different semantic frameworks. WARMR outputs should not be expected to be numerically identical to MM2 match counts without taking into account their differing support definitions and target representations.

---

## 6. Phase 1 vs. Phase 2 Scope (Association Rule Generation)

### Implemented Capability (Phase 1: Frequent Relational Pattern Discovery)
- The engine implements the complete **Phase 1** of the WARMR algorithm: discovering all frequent conjunctive Datalog patterns satisfying declarative language bias and minimum support thresholds.
- Structured pattern records `(warmr_pattern ...)` are emitted with integer absolute support, rational relative support, candidate identities, and length annotations.

### Limitation & Boundary (Phase 2: Post-Processing Rule Generation)
- **Phase 2 (Association Rule Generation)** is **explicitly deferred as out-of-scope**, in strict accordance with the project task requirements:
  - `project-reference-materials/Task.pdf` Section 1 explicitly states:
    > *"Focus on frequent-pattern discovery. Discuss association-rule generation and surprisingness separately. This task requires reading, code investigation and a worked example; implementing a new miner or conducting a full performance benchmark is not required."*
  - Generating relational association rules $Q_1 \Rightarrow Q_2$ with confidence $\text{conf} = \frac{\text{supp}(Q_2)}{\text{supp}(Q_1)}$ is a downstream post-processing step over the discovered frequent patterns, not part of the core frequent pattern search engine.

---

## 7. Execution Runtime Prerequisites

### Implemented Capability
- Executes on standard Linux environments with the local MORK binary (`bin/mork` or `/home/hope/.local/bin/mork`, build commit `ed57c67`).

### Limitation & Boundary
- Requires the native compiled MORK binary.
- Standard non-MORK MeTTa interpreters (such as Python `hyperon-py` without MORK extensions) cannot execute the low-level PathMap BTM `(exec (warmr ...) ...)` priority tags directly without an adapter harness.
