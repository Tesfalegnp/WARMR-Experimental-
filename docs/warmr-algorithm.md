# The WARMR Algorithm: Specification, Pseudocode, and Implementation

**Evidence Categories:**  
`[PAPER]` Supported by Dehaspe & Toivonen (1999)  
`[CODE]` Verified in implementation source code  
`[TESTED]` Verified by executing automated tests  
`[MANUAL]` Theoretical comparison or derivation  

---

## 1. Algorithmic Overview

WARMR is a level-wise breadth-first search (BFS) algorithm over the lattice of conjunctive relational queries bounded by declarative language bias `[PAPER]`. It alternates between:
1. **Candidate Generation (Refinement $\rho$):** Generating candidate queries of length $k$ from frequent queries of length $k-1$.
2. **Canonicalization & Filtering:** Normalizing candidate representations and removing duplicate permutations.
3. **Database Evaluation:** Computing key-projected support for each candidate against relational facts.
4. **Classification & Pruning:** Marking candidates as frequent or infrequent; pruning the search branches of infrequent candidates via anti-monotonicity.

---

## 2. High-Level Pseudocode

```text
Algorithm: WARMR (Frequent Relational Pattern Mining)
Reference: Dehaspe & Toivonen (1999), Table 1 [PAPER]

Input:
  D          : Relational database (facts)
  B          : Background knowledge (Datalog rules)
  L          : Declarative language bias (mode declarations)
  key        : Designated key predicate
  min_supp   : Minimum absolute support threshold
  max_length : Maximum search depth

Output:
  F          : Set of all frequent relational queries

Procedure:
  1. Compile language bias L into active constraints [CODE]
  2. K = { k | key(k) in D };  N = |K| [CODE]
  3. Q_0 = (key(X) <- true)   // Root query (length 0) [CODE]
  4. F_0 = { Q_0 }
  5. k = 1
  6. While k <= max_length and F_{k-1} is not empty:
       a. // Candidate Generation rho(Q)
          C_k = { Q union { L_new } | Q in F_{k-1}, L_new allowed by L, Q union { L_new } connected } [CODE]
       b. // Canonicalization & Deduplication
          C_k = { canonicalize(Q') | Q' in C_k } [CODE]
          C_k = deduplicate(C_k) [CODE]
       c. // Candidate Evaluation
          For each Q' in C_k:
             Witnesses(Q') = { k in K | D union B |= exists Y Body(Q')(k, Y) } [CODE]
             supp(Q') = |Witnesses(Q')| [CODE]
             rel_supp(Q') = supp(Q') / N [CODE]
       d. // Anti-Monotonic Pruning & Classification
          F_k = { Q' in C_k | supp(Q') >= min_supp } [CODE]
          I_k = { Q' in C_k | supp(Q') < min_supp }   // Pruned branches [CODE]
       e. For each Q' in F_k:
             emit warmr_pattern(Q', supp(Q'), rel_supp(Q')) [CODE]
       f. If F_k is empty: break (empty level termination) [CODE]
       g. k = k + 1
  7. Return F = union_{i=1}^k F_i [CODE]
```

---

## 3. The Refinement Operator $\rho(Q)$

In ILP, a **refinement operator** $\rho: \mathcal{L} \rightarrow 2^\mathcal{L}$ computes the set of minimal specializations of a query $Q$ `[PAPER]`.

### 3.1. Language Bias (WRMODE / DLAB)
WARMR uses declarative mode declarations to define valid literals `[PAPER]`:
- **Input Argument (`+`):** Must bind to an already existing variable in $Q$. Ensures query connectivity `[CODE]`.
- **Output Argument (`-`):** Introduces a fresh existential variable not yet present in $Q$ `[CODE]`.
- **Constant Argument (`#`):** Binds to a ground constant from the active domain pool `[CODE]`.

`[CODE]` In `src/language-bias.metta#L34-L36`:
```metta
(valid_mode_symbol + input)
(valid_mode_symbol - output)
(valid_mode_symbol # constant)
```

### 3.2. Concrete Specialization Modes
In our implementation, $\rho(Q)$ specializes candidates across diverse predicate shapes `[CODE]`:

1. **Unary Specialization ($k=1$):**
   $$Q_0 \rightarrow Q_1: \quad \text{active}(\text{var } 0)$$
   `[CODE]` Defined in `src/candidate-gen.metta#L146-L151` and verified in `tests/unary-test.metta` `[TESTED]`.

2. **Binary Specialization (Constant Slot):**
   $$Q_0 \rightarrow Q_1: \quad \text{Inheritance}(\text{var } 0, \text{const man})$$
   `[CODE]` Defined in `src/candidate-gen.metta#L118-L133`.

3. **Binary Specialization (Variable Slot / Relational Chain):**
   $$Q_0 \rightarrow Q_1: \quad \text{parent}(\text{var } 0, \text{var } 1)$$
   `[CODE]` Defined in `src/candidate-gen.metta#L135-L140`.

4. **Ternary Specialization ($k=3$):**
   $$Q_0 \rightarrow Q_1: \quad \text{transfer}(\text{var } 0, \text{var } 1, \text{const chase})$$
   `[CODE]` Defined in `src/candidate-gen.metta#L154-L161` and verified in `tests/ternary-test.metta` `[TESTED]`.

5. **4-Ary Specialization ($k=4$):**
   $$Q_0 \rightarrow Q_1: \quad \text{audit\_log}(\text{var } 0, \text{const s3}, \text{const read}, \text{const us\_east})$$
   `[CODE]` Defined in `src/candidate-gen.metta#L163-L171` and verified in `tests/higher-arity-test.metta` `[TESTED]`.

6. **Level 2 Conjunctions ($Q_1 \rightarrow Q_2$):**
   - Branching on key: $P_1(\text{var } 0, C_1) \wedge P_2(\text{var } 0, C_2)$ `[CODE]` (`src/candidate-gen.metta#L180-L196`).
   - Chaining on output variable: $P_1(\text{var } 0, \text{var } 1) \wedge P_2(\text{var } 1, \text{var } 2)$ `[CODE]` (`src/candidate-gen.metta#L214-L230`).

---

## 4. Query Evaluation & Witness Projection

### 4.1. AtomSpace Witness Projection
To compute support w.r.t. the key entity, each matching proof emits a witness fact tagged with the candidate ID and the key entity `[CODE]`:
$$(+ (\text{key\_witness } \$qid \ \$key))$$

`[CODE]` In `src/support-calc.metta#L84-L95`:
```metta
(exec (warmr 312 eval_l1_var)
  (, (candidate $qid 1 (($pred (var 0) (var 1))) $types $parent)
     (positive_example $key)
     ($pred $key $val))
  (O (+ (key_witness $qid $key))))
```

### 4.2. Deduplication via PathMap BTM Set Semantics
In MORK, identical atoms collapse into a single entry in the PathMap binary tree map `[CODE]`. If individual `abel` satisfies the query through 10 distinct substitution paths, MORK stores `(key_witness $qid abel)` exactly **once**.

### 4.3. Distinct Key Counting
Once all matches are asserted, MORK's `count` sink aggregates the unique key witnesses `[CODE]`:
```metta
(exec (warmr 320 count_witnesses)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $key))
  (O (count (candidate_support $qid $count) $count $key)
     (- (candidate_pending_eval $qid))))
```

### 4.4. Zero-Support Fallback
If a candidate has 0 witnesses in the database, `count_witnesses` never triggers. A sequenced fallback rule catches this and safely asserts `support = 0` `[CODE]`:
```metta
(exec (warmr 330 zero_support_fallback)
  (, (candidate_pending_eval $qid))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))
```
Verified in `tests/empty-level-test.metta` and `tests/poc-support-test.metta` `[TESTED]`.

---

## 5. Candidate Canonicalization

Relational queries suffer from syntactic redundancy `[PAPER]`:
1. **Conjunction Commutativity:** $P(X) \wedge Q(X) \equiv Q(X) \wedge P(X)$.
2. **Variable Renaming ($\alpha$-Equivalence):** $P(X, Y) \wedge Q(Y, Z) \equiv P(A, B) \wedge Q(B, C)$.

### 5.1. Three-Stage Normalization Pipeline
`[CODE]` Implemented in `src/canonicalize.metta#L40-L61`:
1. **Step 1 (Lexicographical Atom Sorting):** MORK's pure `sort-atom` sorts relational literals by predicate symbol and arguments:
   $$\text{sort-atom}(((Q \ X) \ (P \ X))) \rightarrow ((P \ X) \ (Q \ X))$$
2. **Step 2 (Variable Reification):** `indices_to_vars` converts `(var i)` indices into fresh logic variables.
3. **Step 3 (Sequential Re-indexing):** `vars_to_indices` assigns canonical indices `(var 0)`, `(var 1)`, `(var 2)` from left to right in order of first occurrence.
4. **Step 4 (Pool Deduplication):** Adding canonical candidates to `candidate_pool` collapses duplicate permutations into 1 atom via AtomSpace set semantics.

Verified in `tests/canonicalize-test.metta` (7/7 assertions passing) `[TESTED]`.

---

## 6. Implementation Generality vs. Limitations

| Feature | Paper Definition `[PAPER]` | Current Implementation `[CODE]` | Status | Evidence |
|---|---|---|:---:|---|
| **Language Bias Compiler** | DLAB grammar / WRMODE declarations | `modeh`, `modeb`, `determination`, slot modes | **Full** | `src/language-bias.metta` `[CODE]` |
| **Distinct Key Support** | $|\{ k \in \mathcal{K} \mid \mathcal{D} \cup \mathcal{B} \models Q[X/k] \}|$ | Key witness projection via AtomSpace set semantics | **Full** | `src/support-calc.metta` `[TESTED]` |
| **Anti-Monotonic Pruning** | Prune all $Q' \in \rho^*(Q)$ when $\text{supp}(Q) < min$ | Pure 64-bit `gte_i64` pruning gate | **Full** | `src/pruning.metta` `[TESTED]` |
| **Recursive Datalog Engine** | Intensional background knowledge | Native PathMap transitive closure derivation | **Full** | `benchmarks/recursive-family.metta` `[TESTED]` |
| **Predicate Arities** | Arbitrary arities $k \ge 1$ | Templates for Unary, Binary, Ternary, 4-Ary | **Arities 1–4** | `tests/higher-arity-test.metta` `[TESTED]` |
| **Conjunction Depth** | Arbitrary depth $\le max\_length$ | Tested up to Level 5; BFS driver staged to Level 3 | **Depth 3 (BFS) / 5 (Eval)** | `tests/deep-search-test.metta` `[TESTED]` |
| **Subsumption** | Full semantic $\theta$-subsumption | Syntactic canonicalization (`sort-atom` + $\alpha$-norm) | **Syntactic** | `src/canonicalize.metta` `[CODE]` |
| **Rule Generation** | $Q_1 \Rightarrow Q_2$ with confidence | Phase 1 (frequent pattern discovery) implemented | **Phase 1 Only** | `src/output.metta` `[CODE]` |
