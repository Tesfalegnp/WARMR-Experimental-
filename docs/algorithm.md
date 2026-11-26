# Algorithmic Foundations: WARMR Relational Pattern Mining

**Evidence Categories:**
`[PAPER]` Supported by Dehaspe & Toivonen (1999) / Dehaspe & De Raedt (1997)
`[CODE]` Verified in implementation source code (`src/support-calc.metta`, `src/candidate-gen.metta`, `src/search-loop.metta`)
`[TESTED]` Verified by executing automated tests (`tests/family-test.metta`, `tests/anti-monotonicity-test.metta`)
`[MANUAL]` Hand-calculated derivation or mathematical proof

---

## 1. What is Relational Pattern Mining?

Classical association rule mining algorithms—such as **Apriori**—were designed for flat transactional databases (e.g., supermarket basket data) `[PAPER]`. In that setting, data is conceptually a single matrix:
$$\text{Transactions} \times \text{Items}$$
where each transaction is a simple set of propositional items:
$$\mathcal{T}_1 = \{ \text{bread}, \text{butter} \}$$

However, real-world data in biology, finance, knowledge graphs, and relational databases is **multi-relational** `[PAPER]`:
- Entities belong to multiple tables (`Customer`, `Account`, `Transaction`, `AuditLog`).
- Entities are connected by 1-to-many and many-to-many relationships.
- Relationships have variable arities, shared entities, and recursive dependencies (e.g., molecular bonds, genealogical trees).

Flattening multi-relational databases into a single propositional table causes two fatal problems `[PAPER]`:
1. **Combinatorial explosion / Denormalization bias:** Repeating 1-to-many child rows inflates counts artificially.
2. **Loss of structural relational topology:** Information about variable sharing, cycles, and multi-hop paths is destroyed.

**WARMR** (Dehaspe & Toivonen, 1999) was developed in Inductive Logic Programming (ILP) to solve this problem by discovering patterns directly over multi-relational databases represented in **First-Order Horn Clause Logic (Datalog)** `[PAPER]`:
$$Q = \text{key}(X) \leftarrow P_1(X, Y_1) \wedge P_2(Y_1, Y_2) \wedge \dots \wedge P_k(Y_{k-1}, Y_k)$$

---

## 2. Essential Concepts and Declarative Language Bias ($\mathcal{L}$)

### 2.1. First-Order Relational Query
A WARMR pattern is a Datalog query represented as a conjunction of relational atoms `[PAPER]`:
$$? - \text{key}(X), P_1(X, Y_1), P_2(Y_1, Y_2), \dots, P_m(Y_{m-1}, Y_m)$$
- **Variables ($X, Y_1, Y_2$):** Placeholders for entities. In MeTTa/MM2 on MORK, variables are indexed as `(var 0)`, `(var 1)`, etc. `[CODE]`.
- **Relational Atoms ($P_i$):** Relations over entities, such as `parent(X, Y)` or `Inheritance(X, man)`.
- **Shared Variables:** Variables occurring in multiple atoms link entities along a relational chain `[PAPER]`.

### 2.2. Declarative Language Bias (DLAB / WRMODE)
To keep the search space finite, connected, and domain-appropriate, candidate queries are constrained using declarative mode declarations `[PAPER]`:

1. **Key Predicate (`modeh`):**
   Defines the primary unit of analysis (the *key entity*).
   $$\text{modeh}(\text{positive\_example}(+K))$$
   All queries are rooted in variable $X \equiv (\text{var } 0)$, representing the key entity.

2. **Body Predicates (`modeb`):**
   Defines permitted relation symbols and argument slot roles `[CODE]`:
   - **Input Slot (`+`):** Must bind to an already existing variable in the query prefix with compatible type.
   - **Output Slot (`-`):** Introduces a fresh existential variable of declared type.
   - **Constant Slot (`#`):** Binds to an active constant from the domain's declared constant pool (`type_constant`).

3. **Determinations (`determination`):**
   Explicitly permits which body predicates may specialize a particular head relation.

4. **Connectivity Invariant:**
   Every added body literal must share at least one input variable (`+`) that connects back (directly or transitively) to the key variable $(\text{var } 0)$. Disconnected cartesian products are strictly prohibited.

---

## 3. High-Level Algorithm and the Refinement Operator $\rho(Q)$

WARMR traverses the hypothesis space $\mathcal{L}$ top-down from the most general query to more specific queries using a specialization operator $\rho$:
$$\rho(Q) = \{ Q' \in \mathcal{L} \mid Q' = Q \wedge L \}$$
where $L$ is a single relational literal permitted by the language bias:
- **Base Query ($Q_0$, Level 0):** $\text{positive\_example}(X) \leftarrow \text{true}$ (empty body, 100% support).
- **Level 1 ($\rho(Q_0)$):** Single-literal specializations rooted on $(\text{var } 0)$.
- **Level $k+1$ ($\rho(Q_k)$):** Appending one valid literal to a frequent Level $k$ query.

### 3.1. Algorithmic Pseudocode

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

## 4. Relational Support: Distinct Key Entity Projection

### 4.1. Definition
Let $\mathcal{D}$ be the relational database, and let $\mathcal{K} = \{ k \mid \text{positive\_example}(k) \in \mathcal{D} \}$ be the set of positive key individuals ($|\mathcal{K}| = N$).

The **absolute support** of candidate query $Q = \text{key}(X) \leftarrow \text{Body}(X, \vec{Y})$ is defined as:
$$\text{supp}_{\mathcal{D}}(Q) = |\{ k \in \mathcal{K} \mid \mathcal{D} \models \exists \vec{Y} \text{Body}(k, \vec{Y}) \}|$$

The **relative support** is:
$$\text{rel\_supp}_{\mathcal{D}}(Q) = \frac{\text{supp}_{\mathcal{D}}(Q)}{|\mathcal{K}|} = \frac{\text{supp}_{\mathcal{D}}(Q)}{N}$$

### 4.2. Multi-Proof Collapsing
Suppose entity `abel` has two children: `hana` and `bereket`. For the query:
$$Q(X) \leftarrow \text{parent}(X, Y)$$
there exist two distinct substitution proofs:
1. $\theta_1 = \{ X \mapsto \text{abel}, Y \mapsto \text{hana} \}$
2. $\theta_2 = \{ X \mapsto \text{abel}, Y \mapsto \text{bereket} \}$

In WARMR, both proofs project onto the same key entity:
$$\pi_X(\theta_1) = \text{abel}, \quad \pi_X(\theta_2) = \text{abel}$$
Through AtomSpace set semantics, only **one** key witness fact is stored:
$$\text{key\_witness}(Q, \text{abel})$$
Thus, `abel` contributes exactly **1** to the support of $Q$, preventing false support inflation from 1-to-many relationships.

---

## 5. Anti-Monotonic Pruning

A candidate query $Q'$ $\theta$-subsumes $Q$ ($Q' \succeq_\theta Q$) if there exists a substitution $\theta$ such that $\text{Body}(Q')\theta \subseteq \text{Body}(Q)$. In WARMR's top-down search, extending query $Q$ with additional body literals produces a specialization $Q_{spec}$:
$$\text{Body}(Q_{spec}) = \text{Body}(Q) \cup \{ L \}$$

### 5.1. Theorem (Anti-Monotonicity of Relational Support) `[PAPER]`
For any candidate query $Q$ and any specialization $Q' \in \rho(Q)$:
$$\text{supp}_{\mathcal{D}}(Q') \le \text{supp}_{\mathcal{D}}(Q)$$

*Proof:*
Let $k \in \mathcal{K}$ be an arbitrary key witness for $Q'$. Then $\mathcal{D} \models \exists \vec{Y}' (\text{Body}(Q)(k, \vec{Y}) \wedge L(k, \vec{Y}, \vec{Z}))$. Since conjunction is monotonic:
$$\mathcal{D} \models \exists \vec{Y} \text{Body}(Q)(k, \vec{Y})$$
Therefore, every key witness for $Q'$ is necessarily a key witness for $Q$:
$$\{ k \in \mathcal{K} \mid \mathcal{D} \models Q'(k) \} \subseteq \{ k \in \mathcal{K} \mid \mathcal{D} \models Q(k) \}$$
Taking set cardinalities yields $\text{supp}(Q') \le \text{supp}(Q)$. $\blacksquare$

### 5.2. Search Space Pruning
If $\text{supp}(Q) < \text{MIN\_SUPPORT}$, then by the Anti-Monotonicity Theorem, **no specialization** of $Q$ can possibly achieve support $\ge \text{MIN\_SUPPORT}$. Therefore, $Q$ is marked with `(prune_branch Q)`, and the entire subtree rooted at $Q$ is pruned without evaluation.

---

## 6. Association-Rule Confidence in WARMR

Once frequent queries $\mathcal{F}$ are discovered, WARMR can generate relational association rules of the form `[PAPER]`:
$$Q_1 \Rightarrow Q_2$$
where $Q_1$ and $Q_2$ are queries such that $\text{Body}(Q_1) \subset \text{Body}(Q_2)$.

### 6.1. Confidence Definition
The **confidence** of a relational rule $Q_1 \Rightarrow Q_2$ is the conditional probability that a key entity satisfies $Q_2$ given that it satisfies $Q_1$:
$$\text{conf}(Q_1 \Rightarrow Q_2) = \frac{\text{supp}(Q_2)}{\text{supp}(Q_1)}$$

### 6.2. Example
Suppose in `ugly-sodaDrinker`:
- $\text{supp}(\text{human}(X)) = 20$
- $\text{supp}(\text{human}(X) \wedge \text{man}(X)) = 10$

The rule $\text{human}(X) \Rightarrow \text{man}(X)$ has confidence:
$$\text{conf} = \frac{10}{20} = 0.50 \quad (50\%)$$

*(Note: As specified in project scope, Phase 1 frequent pattern mining is the engine's core implementation; post-processing Phase 2 rule generation operates downstream of frequent patterns).*
