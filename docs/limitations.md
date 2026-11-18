# System Boundaries, Engineering Scope, and Known Limitations

This document provides a factual, evidence-based description of the capabilities, verified boundaries, and genuine technical limitations of the independent WARMR implementation in MeTTa/MM2 on MORK.

---

## 1. Verified Search Depth vs. Arbitrary Depth

### Implemented Capability
- The engine supports level-wise breadth-first search (BFS).
- Multi-literal conjunctions are rigorously tested and verified up to **depth 5** (`Length 5` in `tests/deep-search-test.metta`).
- Multi-hop relational chaining and branched constant matching are verified for lengths 1, 2, 3, 4, and 5.

### Limitation & Boundary
- **Do not claim arbitrary infinite search depth without bounds.**
- While the BFS search loop architecture is recursive in design, the conjunction matching templates in `src/support-calc.metta` explicitly define unification patterns up to length 5.
- Queries exceeding length 5 require extending unification rules for higher depths or deploying a dynamic conjunction unifier in MORK.
- In practical relational data mining, patterns beyond length 4 or 5 are rarely mined due to combinatorial hypothesis space explosion ($\mathcal{O}(|\mathcal{P}|^k)$).

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
- **Alpha-Renaming Normalization:** Variables are re-indexed from left to right sequentially starting at `(var 0)` via `indices_to_vars` and `vars_to_indices`.
- **Set Deduplication:** Inserting normalized candidates into `candidate_pool` eliminates identical forms via MORK PathMap BTM set semantics.

### Limitation & Boundary
- **Syntactic Normalization vs. Semantic $\theta$-Subsumption:**
  - The engine normalizes syntactic permutations and variable renamings ($\alpha$-equivalence).
  - It does **not** solve full semantic $\theta$-subsumption equivalence checking (e.g., checking if $Q_1 \succeq_\theta Q_2$ and $Q_2 \succeq_\theta Q_1$ when literals can fold onto themselves, such as $p(X, Y) \wedge p(Y, X)$ vs $p(X, X)$).
  - Full $\theta$-subsumption is NP-complete. In ILP, heuristic canonicalization or syntactic ordering is the standard industrial approach.

---

## 4. Negation and Monotonicity

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

## 6. Execution Runtime Prerequisites

### Implemented Capability
- Executes on standard Linux environments with the MORK binary.

### Limitation & Boundary
- Requires the native compiled MORK binary (`/home/hope/.local/bin/mork`).
- Standard non-MORK MeTTa interpreters (such as Python `hyperon-py` without MORK extensions) cannot execute the low-level PathMap BTM `(exec (warmr ...) ...)` priority tags directly without an adapter harness.
