# Comprehensive Algorithmic & Implementation Comparison: WARMR vs. Pattern Miner MM2

**Evidence Categories:**  
`[CODE]` Verified directly in repository source code  
`[TESTED]` Verified by executing automated tests or benchmark runs  
`[PAPER]` Supported by ILP literature (Dehaspe & Toivonen 1999)  
`[HYPOTHESIS]` Reasoned expectation pending future benchmark experiments  

---

## 1. Repository & Baseline Provenance

| Parameter | Independent WARMR Implementation | Pattern-miner-mm2 (Hyperon MM2) |
|---|---|---|
| **Repository URL** | `https://github.com/Tesfalegnp/WARMR-Experimental-.git` | `https://github.com/iCog-Labs-Dev/Pattern-miner-mm2.git` |
| **Branch** | `main` | `upstream/main` |
| **Verified Commit SHA** | `527ff5108d80e87c2b91a8d6b21cae833b0f3d21` | `153afdae240d5235cdd045112f5d04b4bfb397a0` |
| **Primary Shared Dataset** | `benchmarks/ugly-sodaDrinker.metta` (SHA256: `3b8b322...`) | `data/ugly-sodaDrinker.metta` (SHA256: `3b8b322...`) |
| **Execution Engine** | Native MORK compiler binary | Native MORK compiler binary |

---

## 2. Twenty-Five Dimension Comparison Matrix

| # | Dimension | Independent WARMR `[CODE]` | Pattern-miner-mm2 `[CODE]` | Practical Consequence | Evidence |
|---|---|---|---|---|:---:|
| 1 | **Representation** | First-Order Datalog Horn Clauses: $? - key(X), P_1(\dots), \dots, P_k(\dots)$ | Hypergraph Link Atoms: `($link $node1 $node2)` | WARMR queries are rooted on an entity; MM2 patterns are arbitrary subgraphs. | `[CODE]` `src/data-model.metta`, `docs/data-model.md` |
| 2 | **Query Syntax** | Staged S-expressions: `(candidate <id> <len> (<body>) <types> <parent>)` | S-expressions: `(expanded-conjunct <size> <candidate> <support>)` | WARMR preserves candidate lineage and types; MM2 preserves size and support. | `[CODE]` `src/warmr.metta`, `src/freq/frequent-pattern-miner.metta` |
| 3 | **Predicate Arity** | Multi-Arity: Unary ($k=1$), Binary ($k=2$), Ternary ($k=3$), 4-Ary ($k=4$) | Strictly Binary Triplet: `($pred $left $right)` | WARMR can mine properties (`active/1`), events (`audit/4`), and transfers (`transfer/3`); MM2 cannot without rewriting. | `[CODE]` `tests/higher-arity-test.metta`, `src/conjunction-expansion-triplet.metta#L14` |
| 4 | **Variable Indexing** | Normalized sequential tags: `(var 0)`, `(var 1)`, `(var 2)` | Normalized sequential tags: `(var 0)`, `(var 1)`, `(var 2)` | Identical variable indexing representations across both systems. | `[CODE]` `src/canonicalize.metta`, `src/common-utils/utils.metta#L201` |
| 5 | **Constants & Arguments** | Declarative constant pool (`type_constant`) and `#` mode slots | Constant literals extracted from database facts during search | WARMR constrains constants via language bias; MM2 discovers constants dynamically. | `[CODE]` `src/language-bias.metta#L103`, `src/freq/components/candidate-patterns.metta#L415` |
| 6 | **Nested Expressions** | Evaluates flat relational conjunctions (first-order standard) | Shallow abstraction decomposes nested expressions | MM2 supports nested trees (`(Evaluation $x (like $y $z))`); WARMR requires Datalog flattening. | `[CODE]` `src/freq/components/candidate-patterns.metta#L305` |
| 7 | **Pattern Abstraction** | Mode-guided specialization from root query $Q_0$ | Shallow abstraction replaces nodes with variables | WARMR generates top-down; MM2 abstracts from observed facts. | `[CODE]` `src/candidate-gen.metta#L118`, `src/freq/components/candidate-patterns.metta#L350` |
| 8 | **Candidate Generation** | Refinement operator $\rho(Q)$ adds 1 valid literal | Expansion joins singletons with existing conjunction | Both specialize incrementally, but WARMR uses explicit mode constraints. | `[CODE]` `src/candidate-gen.metta`, `src/freq/components/conjunction-expansion-triplet.metta` |
| 9 | **Specialization Mechanism** | Adding literal connected to existing variables (`+`, `-`, `#`) | Connecting fresh variable to left or right slot of triplet | WARMR enforces type compatibility; MM2 relies on slot-sharing cases. | `[CODE]` `src/candidate-gen.metta#L180`, `docs/conjunction-expansion-walkthrough.md#L88` |
| 10 | **Search Strategy** | Level-wise Breadth-First Search (BFS) level-by-level | Level-wise BFS expanding size $k \rightarrow k+1$ | Both use BFS to guarantee finding minimal frequent patterns first. | `[CODE]` `src/search-loop.metta`, `src/freq/components/iterative-miner.metta` |
| 11 | **Support Semantics** | **Key-Projected Frequency:** $|\{ K \mid \exists \vec{Y} \text{Body}(K, \vec{Y}) \}|$ | **Tuple Valuation Count:** Total matching hypergraph instances | WARMR support is bounded by domain entities ($N \le 20$); MM2 counts combinations (up to 761). | `[TESTED]` `tests/mm2-benchmark-test.metta`, `tests/frequent-miner/conjunction-expansion-test.metta#L21` |
| 12 | **Duplicate Proof Handling** | Multi-proof collapsing: duplicate matches merge into 1 witness | No multi-proof deduplication: every tuple match is counted | In 1-to-many relationships, MM2 inflates support; WARMR counts distinct entities. | `[TESTED]` `tests/family-test.metta#L75`, `docs/worked-example.md` |
| 13 | **Anti-Monotonic Pruning** | Mathematically safe pruning: $Q \preceq_\theta Q' \implies \text{supp}(Q') \le \text{supp}(Q)$ | Filters by `support-at-least`; relies on connectedness | WARMR pruning is provably safe under key support; MM2 combination growth requires care. | `[PAPER]` `[CODE]` `src/pruning.metta`, `src/common-utils/utils.metta#L162` |
| 14 | **Subsumption Handling** | Syntactic canonicalization (`sort-atom` + $\alpha$-norm) | Syntactic canonicalization (`sort-atom` + $\alpha$-norm) | Neither system implements full NP-complete semantic $\theta$-subsumption. | `[CODE]` `src/canonicalize.metta`, `src/common-utils/utils.metta#L215` |
| 15 | **Canonicalization Algorithm** | 3-step: `sort-atom` $\rightarrow$ `indices_to_vars` $\rightarrow$ `vars_to_indices` | 3-step: `sort-atom` $\rightarrow$ `indices_to_vars` $\rightarrow$ `vars_to_indices` | Exact identical canonicalization logic deployed in both systems. | `[CODE]` `src/canonicalize.metta#L40`, `src/common-utils/utils.metta#L215` |
| 16 | **Connectedness Invariant** | Enforced by language bias (`+` slot must bind existing var) | Enforced by structural mapping (shared choice required) | Both prevent generating disconnected cartesian product queries. | `[CODE]` `src/candidate-gen.metta#L76`, `docs/conjunction-expansion-walkthrough.md#L88` |
| 17 | **Candidate Expansion Scope** | Branching on key and chaining along output variables | Fan-out on left argument and chaining on right argument | WARMR guides chaining by declared types; MM2 connects by argument positions. | `[CODE]` `src/search-loop.metta#L70`, `docs/conjunction-expansion-walkthrough.md#L92` |
| 18 | **Caching & Indexing** | Staged pipeline execution without external cache | Integrated `support-cache` storing previously counted queries | MM2 avoids re-evaluating identical sub-queries across search branches. | `[CODE]` `src/common-utils/utils.metta#L54` |
| 19 | **Computational Complexity** | $\mathcal{O}(|\mathcal{L}_k| \cdot |\mathcal{K}| \cdot \text{cost}(\text{eval}))$ | $\mathcal{O}(|\mathcal{C}_k| \cdot |\text{FACT}|^{\text{size}})$ | MM2 matching can be expensive on high-cardinality combinatorial joins. | `[MANUAL]` |
| 20 | **Memory Considerations** | Witnesses atomically cleaned up after counting (0 leaks) | Support cache retained in AtomSpace across mining run | MM2 trades memory for speed via caching; WARMR prioritizes minimal AtomSpace footprint. | `[CODE]` `src/support-calc.metta#L332`, `src/common-utils/utils.metta#L70` |
| 21 | **Search Completeness** | Complete w.r.t. language bias $\mathcal{L}$ up to $max\_length$ | Complete w.r.t. triplet expansion rules up to $max\_size$ | Both exhaustively explore their defined hypothesis space. | `[CODE]` `src/search-loop.metta`, `src/freq/components/conjunction-expansion-triplet.metta` |
| 22 | **Output Format** | Standardized `(warmr_pattern ...)` S-expression record | `(expanded-conjunct ...)` or `(frequent-pattern ...)` | Both produce structured, machine-readable output in the AtomSpace. | `[CODE]` `src/output.metta`, `src/miner/pattern-miner.metta#L38` |
| 23 | **Interpretability** | First-order relational rules with explicit entity semantics | Hypergraph link conjunctions | WARMR patterns correspond directly to standard relational database queries. | `[PAPER]` |
| 24 | **Hyperon Integration** | Implemented in MeTTa/MM2 on MORK PathMap BTM | Implemented in MeTTa/MM2 on MORK PathMap BTM | Both run natively inside the Hyperon/MORK software ecosystem. | `[CODE]` |
| 25 | **Recursive Background Knowledge** | Native Datalog deductive rules (`ancestor/2` from `parent/2`) | None (strictly extensional facts loaded from DB) | WARMR can mine over derived intensional relationships; MM2 cannot. | `[TESTED]` `tests/recursive-datalog-test.metta` |

---

## 3. Verified Strengths and Weaknesses of Pattern Miner MM2

### 3.1. Strengths of Pattern Miner MM2 `[CODE]`
1. **Integrated Surprisingness Scoring (ISURP / JSD):** Unlike standard frequency-only miners, MM2 includes sophisticated information-theoretic scoring using Beta distribution CDFs and Jensen-Shannon Divergence (`src/common-utils/beta-cdf.metta`, `src/surp/`).
2. **Support Caching:** The `support-cache` module in `src/common-utils/utils.metta#L54` memoizes support counts for canonicalized conjunctions, avoiding redundant database passes.
3. **Nested Expression Handling:** The shallow abstraction pipeline in `src/freq/components/candidate-patterns.metta` can abstract structured expression trees (e.g. `(Evaluation $x (like $y $z))`), allowing mining over higher-order MeTTa links.

### 3.2. Evidence-Based Weaknesses and Gaps in Pattern Miner MM2 `[CODE]` `[TESTED]`
1. **Rigid Predicate Arity (Binary Triplet Restriction):**
   - *Evidence:* `src/conjunction-expansion-triplet.metta#L1` explicitly specifies: `;; Standalone conjunction expansion for triplet patterns.`
   - *Consequence:* MM2 cannot mine unary properties (e.g. `(active $x)`), ternary relations (`(transfer $x $y $bank)`), or 4-ary audit events (`(audit_log $u $s $a $r)`).
2. **Absence of Key-Based Entity Support:**
   - *Evidence:* `tests/frequent-miner/conjunction-expansion-test.metta#L21` reports support of **761** for `((Inheritance (var 0) (var 1)) (Inheritance (var 2) (var 1)))` on a 60-fact database.
   - *Consequence:* MM2 counts raw tuple valuations. In databases with 1-to-many relationships (e.g. patients with multiple visits), support reflects visit counts rather than patient prevalence, violating the basic semantics of entity-centric association mining.
3. **Lack of Intensional Datalog Background Knowledge:**
   - *Evidence:* MM2 only unifies against active `(FACT ...)` atoms.
   - *Consequence:* MM2 cannot leverage recursive background rules (such as transitive closures or taxonomies) during pattern search.
4. **No Declarative Language Bias (WRMODE):**
   - *Evidence:* MM2 has no `modeh` or `modeb` mechanism to designate input (`+`), output (`-`), or constant (`#`) slot roles.
   - *Consequence:* Search cannot be semantically constrained by types or directed entity flows.

---

## 4. Verified Strengths and Weaknesses of the Independent WARMR Engine

### 4.1. Strengths of Independent WARMR `[CODE]` `[TESTED]`
1. **True Distinct-Key Entity Support:** Projects substitutions onto key variable `(var 0)` and deduplicates multiple witnesses via AtomSpace set semantics, guaranteeing accurate entity prevalence without false inflation.
2. **Multi-Arity Relational Generalization:** Seamlessly mines relations of arities 1, 2, 3, and 4 (tested and verified in `tests/unary-test.metta`, `tests/ternary-test.metta`, `tests/higher-arity-test.metta`).
3. **Recursive Datalog Engine:** Successfully evaluates intensional background knowledge (e.g. `ancestor/2` from `parent/2`) natively in MORK PathMap BTM before candidate evaluation.
4. **Declarative Language Bias Compiler:** Supports fine-grained semantic constraints (`modeh`, `modeb`, determinations, and constant domains) via `src/language-bias.metta`.
5. **Pure 64-Bit Arithmetic:** Uses native MORK 64-bit integer instructions (`gte_i64`), supporting arbitrary non-negative thresholds (verified at 500 and 1,000+).

### 4.2. Weaknesses and Boundaries of Independent WARMR `[CODE]`
1. **Finite Verified BFS Staging:** The automated BFS driver in `src/search-loop.metta` is explicitly staged for Levels 1–3. While multi-literal support evaluation is verified up to depth 5 in `tests/deep-search-test.metta`, expanding beyond Level 3 in the main search loop requires adding corresponding staged rules.
2. **Phase 1 Only (No Association Rule Generation):** The engine discovers frequent relational patterns $\mathcal{F}$; it does not yet generate association rules with confidence scores ($Q_1 \Rightarrow Q_2$).
3. **No Information-Theoretic Surprisingness:** WARMR outputs frequency and relative support, but does not compute Jensen-Shannon Divergence or Beta CDF scores like MM2.
