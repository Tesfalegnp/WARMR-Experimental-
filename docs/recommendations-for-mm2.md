# Algorithmic Recommendations for Hyperon Pattern Miner MM2

**Target Repository:** `https://github.com/iCog-Labs-Dev/Pattern-miner-mm2`  
**Purpose:** Propose concrete, evidence-based improvements derived from the independent WARMR research to enhance OpenCog Hyperon's pattern mining engine.

---

## 1. Executive Summary & Prioritization Matrix

| Recommendation | Priority | Category | Expected Benefit | Implementation Risk |
|---|:---:|---|---|:---:|
| **1. Optional Key-Based Support Mode** | **High** | Correctness & Semantics | Prevents support inflation in 1-to-many domains; enables true entity-level prevalence mining. | Low |
| **2. Safe Anti-Monotonic Pruning** | **High** | Performance & Pruning | Eliminates exponential candidate growth when mining under key-based support. | Medium |
| **3. Declarative Language Bias (WRMODE)** | **Medium** | Usability & Constraint | Enables semantic type filtering and input/output slot direction; stops generating nonsensical queries. | Low |
| **4. Multi-Arity Relational Extension** | **Medium** | Generalization | Extends MM2 beyond binary triplets to unary properties (arities 1, 3, 4+). | Medium |
| **5. Intensional Datalog Derivation** | **Low** | Expressiveness | Allows mining over derived relations (transitive closures, taxonomies) in AtomSpace. | High |

---

## 2. High-Priority Recommendations

### 2.1. Recommendation 1: Optional Key-Based Entity Support Mode
- **The Existing Problem `[CODE]`:**
  In `src/common-utils/utils.metta#L25-L38`, MM2's `count-indexed-conjunction-support` uses MORK's `count-fast` sink over unconstrained unifications:
  ```metta
  (count-fast ($out $context $candidate $support) $support)
  ```
  In databases with 1-to-many relationships (e.g. patients with many diagnoses, customers with many orders), MM2 counts every tuple combination. A single entity with 10 facts produces 100 combination pairs, causing massive support distortion (e.g. support = 761 on a 60-fact dataset in `conjunction-expansion-test.metta#L21`).
- **Proposed Solution:**
  Introduce an optional `SUPPORT-MODE key-projected` in `utils.metta`:
  1. Designate a key variable slot (default: `(var 0)`).
  2. Emit temporary `(key-witness $candidate $key)` facts for each satisfying unification.
  3. Count distinct witness facts via MORK's `count` sink:
     ```metta
     (count (support-result $candidate $supp) $supp $key)
     ```
  4. Retract temporary witness atoms.
- **Expected Benefit:**
  Allows MM2 to mine true entity prevalence (e.g. "What fraction of patients have condition X?") alongside its existing combinatorial embedding count.
- **Potential Trade-Offs:**
  Requires a temporary witness emission and cleanup step, adding a small constant overhead per candidate.
- **Verification & Test Plan:**
  Run the family benchmark (`tests/family-test.metta`); verify that `parent(X, Y) ∧ parent(Y, Z)` yields support = 2 (abel, bereket) instead of tuple count = 3.

---

### 2.2. Recommendation 2: Safe Anti-Monotonic Pruning under Key Support
- **The Existing Problem `[CODE]`:**
  In `conjunction-expansion-triplet.metta#L42-L46`, MM2 applies `MIN-SUPPORT` filtering after candidate conjunctions are generated. However, because tuple valuation counts can multiply when unconstrained free variables are introduced, anti-monotonic pruning cannot be assumed in the general case without strict structural guards.
- **Proposed Solution:**
  When operating in `SUPPORT-MODE key-projected`, MM2 can mathematically rely on the Anti-Monotonicity Theorem:
  $$Q \preceq_\theta Q' \implies \text{supp}(Q') \le \text{supp}(Q)$$
  If a candidate conjunction fails `support-at-least`, mark its lineage as pruned and suppress generating any extensions that contain the infrequent candidate as a sub-conjunction.
- **Expected Benefit:**
  Exponential reduction of the candidate search space at higher sizes (`MAX-SIZE >= 3`).
- **Potential Trade-Offs:**
  Pruning is valid **only** when key-projected support is used. It must not be enabled when counting raw unconstrained tuple combinations.
- **Verification & Test Plan:**
  Verify that candidates extending pruned infrequent singletons (e.g. `premium(X)` with support 4 < 5 in `tests/unary-test.metta`) are never queued or evaluated.

---

## 3. Medium-Priority Recommendations

### 3.1. Recommendation 3: Declarative Language Bias (WRMODE)
- **The Existing Problem `[CODE]`:**
  MM2 generates candidate extensions using purely positional slot-mapping rules (`docs/conjunction-expansion-walkthrough.md#L92-L98`). It has no mechanism to declare:
  - Allowed body predicates for a given target concept.
  - Argument types (e.g. `Person`, `Gene`, `Account`).
  - Argument directions (Input `+`, Output `-`, Constant `#`).
  As a result, MM2 can generate syntactically valid but semantically meaningless joins (e.g. joining an account number with a person's age).
- **Proposed Solution:**
  Adopt a lightweight declarative mode configuration module similar to WARMR's `src/language-bias.metta`:
  ```metta
  (modeb Inheritance ((+ entity) (# type)))
  (modeb Evaluation ((+ agent) (- action)))
  ```
  Filter candidate expansion proposals against declared slot modes before queuing.
- **Expected Benefit:**
  Dramatically restricts hypothesis generation to domain-appropriate patterns, cutting candidate queue sizes.
- **Potential Trade-Offs:**
  Requires users to supply a configuration file alongside the database.
- **Verification & Test Plan:**
  Verify that disallowed predicates are caught and rejected with explicit error tags (`candidate_error disallowed_predicate`).

---

### 3.2. Recommendation 4: Multi-Arity Relational Generalization
- **The Existing Problem `[CODE]`:**
  `src/conjunction-expansion-triplet.metta` is explicitly hardcoded to binary relations / triplets:
  ```metta
  ($predicate $left $right)
  ```
  MM2 cannot mine unary properties (e.g. `(active $x)`), ternary banking transactions (`(transfer $x $y $bank)`), or 4-ary security audit events (`(audit_log $u $s $a $r)`).
- **Proposed Solution:**
  Generalize the pattern decomposition in `candidate-patterns.metta` and conjunction expansion to handle variable-length argument lists:
  `($predicate . $args)` using MORK's `car-atom`, `cdr-atom`, and `size-atom` primitives (as proven in WARMR's `src/candidate-gen.metta#L146-L171`).
- **Expected Benefit:**
  Enables MM2 to operate directly on realistic multi-table relational domains without pre-flattening or artificial binarization.
- **Potential Trade-Offs:**
  More complex variable indexing and connection logic during conjunction expansion.

---

## 4. What MM2 Should Keep (Do Not Replace!)

1. **Information-Theoretic Surprisingness (ISURP / JSD):**
   MM2's Jensen-Shannon Divergence and Beta distribution scoring (`src/common-utils/beta-cdf.metta`) are significant innovations beyond classical frequency-only ILP. WARMR only computes support and confidence; MM2's surprisingness scoring should be vigorously preserved.
2. **Support Caching (`support-cache`):**
   The global support cache in `src/common-utils/utils.metta#L54` is an excellent architecture for avoiding redundant database passes across overlapping search branches.
3. **Shallow Abstraction for Nested Trees:**
   MM2's ability to abstract nested MeTTa expression trees (`(Evaluation $x (like $y $z))`) is vital for OpenCog Hyperon's hypergraph representations and should be retained.
