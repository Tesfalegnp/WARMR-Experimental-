# Algorithmic Foundations: WARMR Relational Pattern Mining

## 1. Introduction

**WARMR** (Dehaspe & Toivonen, 1999) is the foundational Inductive Logic Programming (ILP) algorithm for discovering frequent relational association rules and datalog patterns over multi-relational databases.

While classical association rule mining algorithms (such as **Apriori**) operate over single flat tables or sets of propositional items:
$$\mathcal{I} = \{i_1, i_2, \dots, i_m\}$$
WARMR operates over **First-Order Relational Horn Clauses**:
$$Q = \text{key}(X) \leftarrow P_1(X, Y_1) \wedge P_2(Y_1, Y_2) \wedge \dots \wedge P_k(Y_{k-1}, Y_k)$$
where relations have arbitrary arities, variables are shared across literals, and entities are connected through relational paths.

---

## 2. Declarative Language Bias ($\mathcal{L}$)

To keep the search space finite, connected, and domain-appropriate, WARMR constrains candidate queries using **DLAB (Declarative Language Bias)** mode declarations:

1. **Key Predicate (`modeh`):**
   Defines the primary unit of analysis (the *key entity*).
   $$\text{modeh}(\text{positive\_example}(+K))$$
   All queries are rooted in variable $X \equiv (\text{var } 0)$, representing the key entity.

2. **Body Predicates (`modeb`):**
   Defines permitted relation symbols and the role of each argument slot:
   - **Input Slot (`+`):** Must bind to an already existing variable in the query prefix with a compatible declared type.
   - **Output Slot (`-`):** Introduces a fresh existential variable of declared type, expanding relational connectivity.
   - **Constant Slot (`#`):** Binds to an active constant from the domain's declared constant pool (`type_constant`).

3. **Determinations (`determination`):**
   Explicitly permits which body predicates may specialize a particular head relation.

4. **Connectivity Invariant:**
   Every added body literal must share at least one input variable (`+`) that connects back (directly or transitively) to the key variable $(\text{var } 0)$. Disconnected cartesian products are strictly prohibited.

---

## 3. The Refinement Operator $\rho(Q)$

WARMR traverses the hypothesis space $\mathcal{L}$ top-down from the most general query to more specific queries using a specialization operator $\rho$:

$$\rho(Q) = \{ Q' \in \mathcal{L} \mid Q' = Q \wedge L \}$$

where $L$ is a single relational literal permitted by the language bias:
- **Base Query ($Q_0$, Level 0):** $\text{positive\_example}(X) \leftarrow \text{true}$ (empty body, 100% support).
- **Level 1 ($\rho(Q_0)$):** Single-literal specializations rooted on $(\text{var } 0)$.
- **Level $k+1$ ($\rho(Q_k)$):** Appending one valid literal to a frequent Level $k$ query.

---

## 4. Relational Support: Distinct Key Entity Projection

In propositional mining, the support of an itemset is simply the number of transactions containing the itemset. In relational databases, however, a candidate query can match a single entity multiple times through different relational paths.

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

### 5.1. Theorem (Anti-Monotonicity of Relational Support)
For any candidate query $Q$ and any specialization $Q' \in \rho(Q)$:
$$\text{supp}_{\mathcal{D}}(Q') \le \text{supp}_{\mathcal{D}}(Q)$$

*Proof:*  
Let $k \in \mathcal{K}$ be an arbitrary key witness for $Q'$. Then $\mathcal{D} \models \exists \vec{Y}' (\text{Body}(Q)(k, \vec{Y}) \wedge L(k, \vec{Y}, \vec{Z}))$. Since conjunction is monotonic, $\mathcal{D} \models \exists \vec{Y} \text{Body}(Q)(k, \vec{Y})$. Therefore, every key witness for $Q'$ is necessarily a key witness for $Q$. It follows that:
$$\{ k \in \mathcal{K} \mid \mathcal{D} \models Q'(k) \} \subseteq \{ k \in \mathcal{K} \mid \mathcal{D} \models Q(k) \}$$
Taking set cardinalities yields $\text{supp}(Q') \le \text{supp}(Q)$. $\blacksquare$

### 5.2. Search Space Pruning
If $\text{supp}(Q) < \text{MIN\_SUPPORT}$, then by the Anti-Monotonicity Theorem, **no specialization** of $Q$ can possibly achieve support $\ge \text{MIN\_SUPPORT}$. Therefore, $Q$ is marked with `(prune_branch Q)`, and the entire subtree rooted at $Q$ is pruned without evaluation.

---

## 6. Breadth-First Search (BFS) Algorithm

```text
Algorithm: WARMR in MeTTa/MORK
Input: Relational database D, Language bias L, Thresholds (min_support, max_length)
Output: Set of frequent relational patterns F

1. Compile language bias mode declarations: modeh, modeb, determination, type_constant
2. Count positive key domain size: N = |{ k | positive_example(k) in D }|
3. Initialize Q0 = (candidate root 0 () ((var 0) ktype))
4. Level k = 1
5. While k <= max_length and CandidateQueue is not empty:
     a. Generate candidate set C_k = rho(F_{k-1}) using language bias L
     b. Canonicalize each Q in C_k: sort body atoms and re-index variables sequentially
     c. Deduplicate C_k into candidate_pool
     d. For each candidate Q in C_k:
          i. Evaluate Q against D; emit key_witness(Q, k) for each satisfied key
          ii. Count distinct witnesses: supp(Q) = |{ k | key_witness(Q, k) }|
          iii. Compute relative support: rel_supp(Q) = supp(Q) / N
          iv. Retract temporary key_witness facts
          v. If supp(Q) >= min_support:
               Mark Q as frequent: F_k = F_k U { Q }
               Emit structured pattern record: warmr_pattern(Q, supp(Q), rel_supp(Q))
             Else:
               Mark Q as infrequent; prune branch rho(Q)
     e. If F_k is empty, terminate search early (empty level)
     f. k = k + 1
6. Return all discovered frequent patterns F
```
