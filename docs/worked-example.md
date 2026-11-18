# Worked Example: Relational Substitutions, Key Projection, and Witness Deduplication

**Evidence Categories:**  
`[PAPER]` Supported by Dehaspe & Toivonen (1999) / Dehaspe & De Raedt (1997)  
`[CODE]` Verified in implementation source code (`src/support-calc.metta`, `data.metta`)  
`[TESTED]` Verified by executing `tests/family-test.metta` (12/12 assertions passing)  
`[MANUAL]` Hand-calculated derivation and substitution trace  

---

## 1. Database Specification

Consider the standard family benchmark from `data.metta` `[CODE]`:

### 1.1. Background Relational Facts (Extensional Database $\mathcal{D}$) `[CODE]`
```metta
(parent abel hana)
(parent hana sami)
(parent hana lidiya)
(parent bereket sara)
(parent sara noah)
```
Total relational facts: **5 facts**.

### 1.2. Key Domain Individuals ($\mathcal{K}$) `[CODE]`
The domain contains 7 distinct individuals:
```metta
(positive_example abel)
(positive_example hana)
(positive_example sami)
(positive_example lidiya)
(positive_example bereket)
(positive_example sara)
(positive_example noah)
```
Total positive key entities: **$N = 7$**.

---

## 2. Relational Query: Two-Hop Chain (Grandparent)

We analyze the two-literal relational chain:
$$Q(X) \leftarrow \text{parent}(X, Y) \wedge \text{parent}(Y, Z)$$

In MeTTa/MM2 candidate syntax `[CODE]`:
```metta
(candidate q_grandparent 2
  ((parent (var 0) (var 1))
   (parent (var 1) (var 2)))
  (((var 0) person) ((var 1) person) ((var 2) person))
  q_parent)
```

---

## 3. Complete Substitutions vs. Key-Projected Witnesses

### 3.1. Complete Substitutions (Tuple-Wise Unification) `[MANUAL]`
Finding all substitutions $\theta = \{ X \mapsto u, Y \mapsto v, Z \mapsto w \}$ such that $\text{parent}(u, v) \in \mathcal{D}$ and $\text{parent}(v, w) \in \mathcal{D}$:

1. **Substitution $\theta_1$:**
   $$\{ X \mapsto \text{abel}, Y \mapsto \text{hana}, Z \mapsto \text{sami} \}$$
   - Fact 1: `(parent abel hana)` $\in \mathcal{D}$
   - Fact 2: `(parent hana sami)` $\in \mathcal{D}$

2. **Substitution $\theta_2$:**
   $$\{ X \mapsto \text{abel}, Y \mapsto \text{hana}, Z \mapsto \text{lidiya} \}$$
   - Fact 1: `(parent abel hana)` $\in \mathcal{D}$
   - Fact 2: `(parent hana lidiya)` $\in \mathcal{D}$

3. **Substitution $\theta_3$:**
   $$\{ X \mapsto \text{bereket}, Y \mapsto \text{sara}, Z \mapsto \text{noah} \}$$
   - Fact 1: `(parent bereket sara)` $\in \mathcal{D}$
   - Fact 2: `(parent sara noah)` $\in \mathcal{D}$

**Total Complete Satisfying Substitutions = 3 tuples.**

---

### 3.2. WARMR Support under Unary Key: `Person(X)` `[PAPER]` `[TESTED]`
In WARMR, support is evaluated with respect to key entities: $X \equiv (\text{var } 0)$.
Each satisfying substitution is projected onto its key variable:
$$\pi_X(\theta) = \theta(X)$$

- Projection of $\theta_1$: $\pi_X(\theta_1) = \text{abel} \implies (+ (\text{key\_witness } q\_grandparent \ \text{abel}))$ `[CODE]`
- Projection of $\theta_2$: $\pi_X(\theta_2) = \text{abel} \implies (+ (\text{key\_witness } q\_grandparent \ \text{abel}))$ `[CODE]`
- Projection of $\theta_3$: $\pi_X(\theta_3) = \text{bereket} \implies (+ (\text{key\_witness } q\_grandparent \ \text{bereket}))$ `[CODE]`

#### Witness Deduplication in MORK AtomSpace
Because MORK stores facts in a PathMap BTM set `[CODE]`, duplicate assertions of `(key_witness q_grandparent abel)` collapse into exactly **one** atom:

$$\text{Witness Set} = \{ \text{abel}, \text{bereket} \}$$

#### Final Metric Values `[TESTED]`
- **Absolute Support:** $|\{ \text{abel}, \text{bereket} \}| = \mathbf{2}$ `[TESTED]`
- **Relative Support:** $\frac{2}{7} \approx \mathbf{28.57\%}$ `[TESTED]`
- **Complete Tuple Count:** **3**

`[TESTED]` Verified in `tests/family-test.metta#L75-L82`:
```metta
(EXPECTED-RESULT fam-chain-supp (candidate_support q_chain 2))
(EXPECTED-RESULT fam-chain-rel  (candidate_relative_support q_chain 2 7))
```

---

### 3.3. WARMR Support under Binary Key: `Parent(X, Y)` `[PAPER]` `[MANUAL]`
What if the key predicate is the binary relation itself:
$$\text{key}(X, Y) \equiv \text{parent}(X, Y)$$
Here, the question changes from:
> *"How many individuals are grandparents?"* (Unary Key: 2/7)

to:
> *"What fraction of parenting relationships extend to grandchildren?"* (Binary Key)

#### Key Domain ($\mathcal{K}_{pairs}$) `[MANUAL]`
The domain consists of the 5 parent pairs:
1. `(abel, hana)`
2. `(hana, sami)`
3. `(hana, lidiya)`
4. `(bereket, sara)`
5. `(sara, noah)`

Total key pairs: $N_{pairs} = 5$.

#### Key-Projected Witnesses `[MANUAL]`
- $\theta_1 = \{ X \mapsto \text{abel}, Y \mapsto \text{hana}, Z \mapsto \text{sami} \} \implies \pi_{(X, Y)}(\theta_1) = (\text{abel}, \text{hana})$
- $\theta_2 = \{ X \mapsto \text{abel}, Y \mapsto \text{hana}, Z \mapsto \text{lidiya} \} \implies \pi_{(X, Y)}(\theta_2) = (\text{abel}, \text{hana})$ (Deduplicated!)
- $\theta_3 = \{ X \mapsto \text{bereket}, Y \mapsto \text{sara}, Z \mapsto \text{noah} \} \implies \pi_{(X, Y)}(\theta_3) = (\text{bereket}, \text{sara})$

Distinct satisfying key pairs:
$$\{ (\text{abel}, \text{hana}), (\text{bereket}, \text{sara}) \}$$

#### Final Metric Values `[MANUAL]`
- **Absolute Support:** $2$ parent relationships.
- **Relative Support:** $\frac{2}{5} = \mathbf{40.0\%}$.
- **Complete Tuple Count:** **3** tuples.

---

## 4. Summary of Comparison

| Metric | Value | Meaning |
|---|:---:|---|
| **Complete Substitutions** | **3** | Total tuple combinations satisfying the query in the database. |
| **Unary Key Support (`Person(X)`)** | **2 / 7 (28.6%)** | Fraction of individuals who are grandparents (`abel`, `bereket`). |
| **Binary Key Support (`Parent(X, Y)`)** | **2 / 5 (40.0%)** | Fraction of parent relationships where the child also has children. |

This concrete example proves why WARMR's key-based support metric is essential: it gives precise, unambiguous semantic control over what is being measured and prevents 1-to-many relationships from corrupting statistical frequencies `[PAPER]`.
