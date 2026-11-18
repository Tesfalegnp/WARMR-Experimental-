# WARMR Fundamentals: Concepts, Mathematics, and Foundations

**Evidence Categories:**  
`[PAPER]` Supported by Dehaspe & Toivonen (1999) / Dehaspe & De Raedt (1997)  
`[CODE]` Verified in implementation source code  
`[TESTED]` Verified by executing automated tests  
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

**WARMR** (Dehaspe & Toivonen, 1999) was developed in the field of **Inductive Logic Programming (ILP)** to solve this problem by discovering patterns directly over multi-relational databases represented in **First-Order Horn Clause Logic (Datalog)** `[PAPER]`.

---

## 2. Essential Concepts

### 2.1. First-Order Relational Query
A WARMR pattern is a Datalog query represented as a conjunction of relational atoms `[PAPER]`:
$$? - \text{key}(X), P_1(X, Y_1), P_2(Y_1, Y_2), \dots, P_m(Y_{m-1}, Y_m)$$
- **Variables ($X, Y_1, Y_2$):** Placeholders for entities. In MeTTa/MM2 on MORK, variables are indexed as `(var 0)`, `(var 1)`, etc. `[CODE]`.
- **Relational Atoms ($P_i$):** Relations over entities, such as `parent(X, Y)` or `Inheritance(X, man)`.
- **Shared Variables:** Variables occurring in multiple atoms (e.g., $Y$ occurring in both $P_1(X, Y)$ and $P_2(Y, Z)$) link entities along a relational chain `[PAPER]`.

### 2.2. Substitutions and Query Satisfaction
- A **substitution** $\theta = \{ X_1 \mapsto t_1, \dots, X_k \mapsto t_k \}$ assigns domain constants to variables `[PAPER]`.
- A query $Q$ is **satisfied** by an entity $k$ in database $\mathcal{D}$ with background knowledge $\mathcal{B}$ (denoted $\mathcal{D} \cup \mathcal{B} \models Q[X/k]$) if there exists a substitution for the existential body variables $\vec{Y}$ such that all body atoms are true facts in $\mathcal{D} \cup \mathcal{B}$ `[PAPER]`.

### 2.3. The Key Atom
In WARMR, counting is always performed with respect to a designated **key predicate** $key(X)$ `[PAPER]`:
- The key specifies the **unit of analysis** (e.g., Customer, Patient, Gene, Molecule).
- In our implementation, the key predicate is standardized as `positive_example(X)` `[CODE]`.
- The set of all key entities in the domain is $\mathcal{K} = \{ k \mid \text{positive\_example}(k) \in \mathcal{D} \}$ `[PAPER]`, with domain size $N = |\mathcal{K}|$ `[CODE]`.

---

## 3. Mathematical Foundations

### 3.1. Relational Support (Key-Based Frequency)
Unlike propositional algorithms that count transactions, and unlike graph miners that count every subgraph match, WARMR defines support as the number of **distinct key entities** that satisfy the query `[PAPER]`.

#### Definition (Absolute Support) `[PAPER]`
Let $Q = ? - key(X), \text{Body}(X, \vec{Y})$ be a candidate query. The absolute support of $Q$ w.r.t. database $\mathcal{D}$, background knowledge $\mathcal{B}$, and key set $\mathcal{K}$ is:
$$\text{supp}_{\mathcal{D}}(Q) = |\{ k \in \mathcal{K} \mid \mathcal{D} \cup \mathcal{B} \models \exists \vec{Y} \text{Body}(k, \vec{Y}) \}|$$

#### Definition (Relative Support) `[PAPER]`
The relative support (frequency) is the fraction of key entities satisfying $Q$:
$$\text{rel\_supp}_{\mathcal{D}}(Q) = \frac{\text{supp}_{\mathcal{D}}(Q)}{|\mathcal{K}|} = \frac{\text{supp}_{\mathcal{D}}(Q)}{N}$$

`[CODE]` In our MORK implementation, absolute support is computed via `(count (candidate_support $qid $count) $count $key)` in `src/support-calc.metta#L303-L307`, and relative support is emitted as `(candidate_relative_support $qid $count $tot)` in `src/support-calc.metta#L326-L330`.

### 3.2. Why Complete Substitutions $\neq$ Key-Based Support
Consider a database where customer `Alice` has 10 purchases, and customer `Bob` has 1 purchase.
For the query:
$$Q(X) \leftarrow \text{purchase}(X, Item)$$
- **Total complete substitutions:** $10 + 1 = 11$ tuples.
- **Distinct key support:** $|\{ \text{Alice}, \text{Bob} \}| = 2$ customers.

If an algorithm counts complete substitutions:
- `Alice` dominates the count by 91% (10/11).
- The metric reflects purchase volume, not customer frequency.
- Adding child relations (e.g. items inside purchases) causes combinatorial multiplication ($10 \times 5 = 50$).

Under WARMR's distinct-key support:
- `Alice` is projected to exactly 1 key witness `[CODE]`.
- `Bob` is projected to exactly 1 key witness `[CODE]`.
- The metric correctly reflects that 2 out of 2 customers made purchases (100% support) `[MANUAL]`.

### 3.3. Minimum Support Threshold
- **Absolute threshold:** An integer threshold $min\_supp \in \mathbb{N}$ (e.g. $min\_supp = 5$). A candidate is frequent if $\text{supp}(Q) \ge min\_supp$ `[PAPER]`.
- **Relative threshold:** A rational fraction $minsup \in [0, 1]$ (e.g. $minsup = 0.20$). A candidate is frequent if $\text{rel\_supp}(Q) \ge minsup$ `[PAPER]`.

`[CODE]` Our MORK engine accepts `(INPUT MIN_SUPPORT <n>)` and evaluates frequency using pure 64-bit integer arithmetic: `gte_i64(count, min_support)` in `src/pruning.metta#L69-L73` `[TESTED]`.

---

## 4. The Anti-Monotonicity Principle

In Inductive Logic Programming, query $Q'$ is a **specialization** of $Q$ ($Q \preceq_\theta Q'$, meaning $Q$ $\theta$-subsumes $Q'$) if $\text{Body}(Q) \subseteq \text{Body}(Q')$ `[PAPER]`.

### 4.1. Theorem (Anti-Monotonicity of Key Support) `[PAPER]`
For any database $\mathcal{D}$, background knowledge $\mathcal{B}$, candidate query $Q$, and specialization $Q' = Q \wedge L$:
$$\text{supp}_{\mathcal{D}}(Q') \le \text{supp}_{\mathcal{D}}(Q)$$

### 4.2. Proof `[MANUAL]`
Let $k \in \mathcal{K}$ be an arbitrary key witness for $Q'$.  
By definition of query satisfaction:
$$\mathcal{D} \cup \mathcal{B} \models \exists \vec{Y}, \vec{Z} (\text{Body}(Q)(k, \vec{Y}) \wedge L(k, \vec{Y}, \vec{Z}))$$
By existential quantification over conjunctions:
$$(\exists \vec{Y}, \vec{Z} (A \wedge B)) \implies (\exists \vec{Y} A)$$
Therefore:
$$\mathcal{D} \cup \mathcal{B} \models \exists \vec{Y} \text{Body}(Q)(k, \vec{Y})$$
Thus, every key witness $k$ for $Q'$ is necessarily a key witness for $Q$:
$$\{ k \in \mathcal{K} \mid \mathcal{D} \cup \mathcal{B} \models Q'[X/k] \} \subseteq \{ k \in \mathcal{K} \mid \mathcal{D} \cup \mathcal{B} \models Q[X/k] \}$$
Taking set cardinalities yields:
$$|\{ k \mid Q'[X/k] \}| \le |\{ k \mid Q[X/k] \}| \implies \text{supp}(Q') \le \text{supp}(Q) \quad \blacksquare$$

### 4.3. Algorithmic Consequence: Safe Pruning
If $\text{supp}(Q) < min\_supp$, then by the Anti-Monotonicity Theorem:
$$\forall Q' \in \rho^*(Q): \quad \text{supp}(Q') \le \text{supp}(Q) < min\_supp$$
**No specialization of $Q$ can ever be frequent.** Therefore, the search tree below $Q$ is safely pruned without evaluating a single descendant query `[PAPER]`.

`[CODE]` Implemented via `(+ (prune_branch $cid))` in `src/pruning.metta#L87-L92` and verified in `tests/pruning-test.metta` `[TESTED]`.

---

## 5. Association-Rule Confidence in WARMR

Once frequent queries $\mathcal{F}$ are discovered, WARMR can generate relational association rules of the form `[PAPER]`:
$$Q_1 \Rightarrow Q_2$$
where $Q_1$ and $Q_2$ are queries such that $\text{Body}(Q_1) \subset \text{Body}(Q_2)$.

### 5.1. Confidence Definition `[PAPER]`
The **confidence** of a relational rule $Q_1 \Rightarrow Q_2$ is the conditional probability that a key entity satisfies $Q_2$ given that it satisfies $Q_1$:
$$\text{conf}(Q_1 \Rightarrow Q_2) = \frac{\text{supp}(Q_2)}{\text{supp}(Q_1)}$$

### 5.2. Example `[MANUAL]`
Suppose in `ugly-sodaDrinker`:
- $\text{supp}(\text{human}(X)) = 20$
- $\text{supp}(\text{human}(X) \wedge \text{man}(X)) = 10$

The rule $\text{human}(X) \Rightarrow \text{man}(X)$ has confidence:
$$\text{conf} = \frac{10}{20} = 0.50 \quad (50\%)$$

`[CODE]` Our current MORK engine implements **Phase 1: Frequent Relational Pattern Mining**. Rule generation (Phase 2) is a post-processing step over the discovered frequent patterns `[PAPER]`.
