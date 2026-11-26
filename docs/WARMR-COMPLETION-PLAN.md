# WARMR Completion Plan

**Based on:** `docs/WARMR-IMPLEMENTATION-AUDIT.md`  
**Repository:** `~/Projects/warmr-experiment` (`main` @ `5ac8483b`)  
**Date:** 2026-11-26  
**Status:** Pending approval — no implementation changes permitted until review

---

> [!IMPORTANT]
> This document is a **plan only**. No source files are to be modified until this plan is reviewed and explicitly approved. All milestones are ordered by dependency and correctness priority.

---

## Table of Contents

1. Critical Path Overview
2. Priority Classification
3. Milestone 0 — Establish a Reproducible Baseline
4. Milestone 1 — Correct Core Data Model and Key Semantics
5. Milestone 2 — Complete Language Bias
6. Milestone 3 — Integrate and Complete General Candidate Generation
7. Milestone 4 — Integrate Canonicalization into the CLI Pipeline
8. Milestone 5 — Correct Pruning and Search Loop
9. Milestone 6 — Extend BFS to General MAX_LENGTH
10. Milestone 7 — Output and WARMR Extensions
11. Milestone 8 — Full Regression and Acceptance
12. Risk Assessment
13. Definition of Done
14. Final Acceptance Checklist

---

## 1. Critical Path Overview

```
M0 (Baseline) → M1 (Key semantics) → M5 (Pruning correctness)
                                   ↗
M2 (Language bias) → M3 (Candidate gen) → M4 (Canonicalization)
                                        ↘
                                          M6 (General BFS) → M7 (Output) → M8 (Acceptance)
```

**Critical-path items:**
1. Restore MORK binary (M0) — blocks all runtime testing.
2. Integrate `candidate-gen.metta` into CLI (M3) — currently the most significant architectural gap.
3. Integrate `canonicalize.metta` into CLI (M4) — required for correct deduplication.
4. Implement general BFS loop (M6) — required for MAX_LENGTH > 3.
5. Fix `unary_lt` missing definition (M5) — blocks L2 unary expansion.

---

## 2. Priority Classification

| Priority | Milestones | Rationale |
|----------|------------|-----------|
| **P0 — Critical** | M0, M3, M4 | Blocks runtime verification; core correctness gap |
| **P1 — High** | M5, M6 | WARMR completeness (search correctness, BFS generality) |
| **P2 — Medium** | M1, M2 | Semantic correctness improvements |
| **P3 — Low** | M7, M8 | Optional extensions and acceptance |

---

## 3. Milestone 0 — Establish a Reproducible Baseline

### Objective
Restore a working runtime environment and document the actual current behavior before any changes.

### Current Status
- MORK binary is a broken symlink; no test can be executed.
- 270 test assertions are declared as passing but cannot be verified.

### Problem
`/home/hope/.local/bin/mork` → (broken) `/home/hope/Projects/MORK/target/release/mork`

### Required Behavior
Running `./scripts/run-tests.sh` should report actual pass/fail counts.

### Dependencies
- Cargo / Rust toolchain (to compile MORK), OR
- Alternative MORK binary source (pre-built package, CI artifact).

### Implementation Steps

1. **Compile MORK from source:**
   ```bash
   cd /home/hope/Projects/MORK
   # Identify the correct crate root (kernel/ or root Cargo.toml)
   find . -name "Cargo.toml" -maxdepth 2
   cargo build --release
   ln -sf /home/hope/Projects/MORK/target/release/mork /home/hope/.local/bin/mork
   ```

2. **Verify MORK binary:**
   ```bash
   /home/hope/.local/bin/mork --version
   ```

3. **Run the full test suite from a clean state:**
   ```bash
   cd /home/hope/Projects/warmr-experiment
   MORK_BIN=/home/hope/.local/bin/mork ./scripts/run-tests.sh 2>&1 | tee /tmp/baseline-test-results.txt
   ```

4. **Record baseline results:**
   - Exact MORK version string.
   - Number of suites discovered.
   - Number of assertions: passed / failed / skipped.
   - Exact exit code.
   - Save output to `docs/baseline-test-results-$(date +%Y%m%d).txt`.

5. **Run a CLI smoke test:**
   ```bash
   ./scripts/run-warmr.sh \
     --dataset benchmarks/ugly-sodaDrinker.metta \
     --keys benchmarks/ugly-sodaDrinker-keys.metta \
     --bias config/mm2-bias.metta \
     --min-support 5 \
     --max-length 3 \
     --dataset-id smoke_test
   ```
   Verify: 20 `warmr_pattern` records, `warmr_search_status completed 3`.

6. **Record the git commit hash and tree status** in baseline documentation.

### Acceptance Criteria
- MORK binary executes without error.
- Test runner completes without crashing.
- Exact assertion counts are recorded (whether passing or failing).
- CLI smoke test produces at least one `warmr_pattern` record.

### Completion Evidence
- `docs/baseline-test-results-YYYYMMDD.txt` with exact output.
- Reproduced test execution visible in CI or local logs.

---

## 4. Milestone 1 — Correct Core Data Model and Key Semantics

### Objective
Verify and document the exact key-domain semantics, confirm distinct-key counting works as designed, and fix any structural issues found during baseline execution.

### Current Status
- Distinct-key counting is **correctly designed** in `src/support-calc.metta:303-307`.
- Multiple parallel counting implementations exist (warmr.metta stages 225–226, search-loop.metta stages 420–425, 520–525, support-calc.metta stage 320).
- Two parallel classification pipelines exist (warmr.metta 235–236 vs pruning.metta 350–352).
- **UNVERIFIED at runtime.**

### Problems

**P1.1: Duplicate counting rules**  
`warmr.metta` (stages 225, 226), `search-loop.metta` (stages 420, 420, 520), and `support-calc.metta` (stage 320) all define variants of the `count_witnesses` → `candidate_support` pattern. These rules may fire at conflicting priority levels and cause double-counting or premature zero-fallback.

**P1.2: Duplicate classification rules**  
`warmr.metta` (stages 235–236) and `pruning.metta` (stages 350–352) both classify candidates from `candidate_support`. The warmr.metta rules are level-specific (`frequent_status_l1`, `frequent_status_l2`, `frequent_status_l3`); the pruning.metta rules use a generic `frequent_status`. It is unclear which fires first and whether they conflict.

**P1.3: Legacy PoC rules in data-model.metta**  
`src/data-model.metta` defines bare-syntax evaluation rules (stages 310–311) that duplicate logic in `src/support-calc.metta`. The file is loaded only in `poc-support-test.metta` but could cause confusion if accidentally loaded.

### Required Behavior
- Exactly one `candidate_support` atom per candidate per evaluation cycle.
- Exactly one classification atom (`candidate_frequent` or `candidate_infrequent`) per candidate.
- Zero orphan `key_witness` atoms after each evaluation cycle.
- Duplicate-count prevention: if a candidate is somehow generated twice, it receives exactly one `candidate_support` atom.

### Files to Modify/Inspect
- `src/warmr.metta` (stages 225–236 counting and classification)
- `src/search-loop.metta` (stages 420–442, 520–542)
- `src/support-calc.metta` (stage 320 counting)
- `src/pruning.metta` (stages 350–352 classification)
- `src/data-model.metta` (legacy PoC — assess whether to deprecate)

### Proposed Implementation Approach

**Step 1:** After baseline (M0), run the MM2 integration test with `mork run --verbose` or `mork run --dump-atomspace` and inspect the actual atoms produced for counting and classification. Identify which rules fire for each candidate.

**Step 2:** Consolidate counting into a single mechanism. Option A: use only `src/support-calc.metta` stage 320 (currently the clearest generic implementation). Option B: use the level-specific counting in warmr.metta and search-loop.metta, and remove the generic rule from support-calc.metta.

**Step 3:** Consolidate classification. If the level-specific classifiers in warmr.metta and search-loop.metta are sufficient, remove the duplicate generic classifier from pruning.metta, or ensure they target different atoms.

**Step 4:** Mark `src/data-model.metta` as deprecated. Remove from future CLI consideration.

### New Tests to Add
```metta
;; Test: exactly one candidate_support per candidate (no double-count)
;; Given: two separate witnesses generated through different rules
;; Expected: candidate_support q1 2  (not 4)
(EXPECTED-RESULT dedup-count-once (candidate_support q1 2))
;; Expected: no double-classification
(EXPECTED-RESULT dedup-class-once (candidate_frequent q1 2))
```

### Expected Test Results
- `(candidate_support q_grandparent 2)` for the family test: 2, not 3 or 6.
- No `(key_witness ...)` atoms remain after evaluation.
- All existing support tests continue to pass.

### Acceptance Criteria
- `candidate_support` for the grandparent query on the family dataset is exactly 2.
- `candidate_support` atom count per candidate is always exactly 1 after the pipeline completes.
- Zero orphan `key_witness` atoms verified by an explicit "no orphan" assertion.

### Risks
- Removing rules from `warmr.metta` may break level-specific evaluation that depends on the intermediate atom names (`frequent_status_l1`, etc.).
- Consolidation requires careful priority-level management to avoid re-ordering effects.

---

## 5. Milestone 2 — Complete Language Bias

### Objective
Make the language bias compiler handle all commonly required DLAB/WRMODE declarations, including error cases.

### Current Status
Core declarations (`modeh`, `modeb`, `determination`, slot modes) are supported. Missing: `±` bidirectional mode, type hierarchy, recall bounds.

### Problems

**P2.1: `±` mode not supported**  
The original WARMR paper defines a `±` mode for bidirectional (input or output) arguments. The current `valid_mode_symbol` table only has `+`, `-`, `#`. If a bias file uses `±`, it will silently fail (treated as an unmapped determination error or ignored).

**P2.2: Recall and recall-bound declarations**  
Some DLAB specifications include recall declarations that limit variable reuse. Not supported.

**P2.3: Multiple modeh declarations**  
Stage 150 (`init_warmr_pipeline`) only matches `valid_modeh $kpred ((+ $ktype))` — a single unary-argument modeh. If modeh has multiple arguments or multiple modeh declarations, Stage 150 may fire multiple times or not at all.

### Required Behavior
- `±` mode should be compiled into both `input` and `output` slots (or handled explicitly).
- Multiple modeh arguments should be handled.
- Invalid declarations produce clear `bias_error` atoms.

### Files to Modify
- `src/language-bias.metta` (add `valid_mode_symbol ± bidirectional`, multi-arg modeh handling)
- `src/warmr.metta` Stage 150 (generalize from single unary modeh pattern)

### Proposed Implementation Approach

**Step 1:** Add `(valid_mode_symbol ± bidirectional)` to `language-bias.metta:34-36`.

**Step 2:** Add a compiler rule that expands `±` slots into both `(valid_slot $pred $idx input $type)` and `(valid_slot $pred $idx output $type)`.

**Step 3:** Generalize Stage 150 to handle modeh with any number of arguments:
```metta
;; Current (too restrictive):
(exec (warmr 150 init_warmr_pipeline)
  (, (valid_modeh $kpred ((+ $ktype))))
  ...)

;; Proposed (general):
(exec (warmr 150 init_warmr_pipeline)
  (, (valid_modeh $kpred $modes))
  ...)
  ;; Then extract first + slot for $ktype
```

### New Tests to Add
```metta
;; Test: ± mode compiles to both input and output slots
(mode_slot test_pred 1 (± person))
(EXPECTED-RESULT pm-input (valid_slot test_pred 1 input person))
(EXPECTED-RESULT pm-output (valid_slot test_pred 1 output person))

;; Test: multi-arg modeh handled correctly
(modeh key_pred ((+ type_a) (- type_b)))
(EXPECTED-RESULT multi-modeh-compiled (valid_modeh key_pred ((+ type_a) (- type_b))))
```

### Acceptance Criteria
- All `valid_mode_symbol` entries cover `+`, `-`, `#`, `±`.
- Bias file with `±` mode compiles without error.
- Stage 150 fires for modeh with any argument count.

### Risks
- Low risk; additive changes only.
- Stage 150 generalization requires care to avoid multiple root initializations if multiple modeh declarations exist.

---

## 6. Milestone 3 — Integrate and Complete General Candidate Generation

### Objective
Load `src/candidate-gen.metta` as part of the production CLI pipeline, or confirm that the production templates in `warmr.metta` and `search-loop.metta` cover the required search space.

### Current Status
`src/candidate-gen.metta` has a broad general refinement operator covering L1 (unary/binary/ternary/4-ary) and L2 (branched/chained/unary combinations) and partial L3. It is **not loaded by the CLI**.

The production pipeline has hardcoded template rules in `warmr.metta` (L1 from root) and `search-loop.metta` (L2–L3) that cover only specific pattern shapes.

### Problem
**Decision required:** Should the production pipeline use `candidate-gen.metta` or the inline template rules?

**Option A: Integrate `candidate-gen.metta`** — Add `--aux-path src/candidate-gen.metta` to `run-warmr.sh`. This immediately gives a broader general candidate space. Risk: rules in `candidate-gen.metta` and `warmr.metta` have overlapping priority ranges (warmr 215–219 appear in both) and may conflict or fire twice.

**Option B: Extend the inline templates in `warmr.metta` and `search-loop.metta`** — Add missing templates (ternary L1, branched var-var L2, etc.) and remove the redundant `candidate-gen.metta`. This keeps the production pipeline self-contained. Risk: more maintenance per new predicate shape.

**Recommendation: Option A with conflict resolution.** The general candidate-gen module is architecturally cleaner and already tested. The integration risk (overlapping priorities) can be resolved by renaming priority stages.

### Required Behavior
- All valid 1-literal specializations of a frequent query Q that are permitted by the loaded mode declarations are generated and evaluated.
- No valid candidate is silently skipped.
- Duplicate candidates are not generated (or are deduplicated before evaluation).

### Files to Modify
- `scripts/run-warmr.sh` — add `--aux-path "$WORKSPACE_ROOT/src/candidate-gen.metta"`
- `scripts/run-warmr.sh` — add `--aux-path "$WORKSPACE_ROOT/src/canonicalize.metta"` (required for dedup)
- `src/candidate-gen.metta` — rename conflicting priority ranges if needed (e.g., move from warmr 215–219 to warmr 250–259 if warmr.metta occupies 215–217)
- `src/warmr.metta` — assess whether L1 rules (215–217) should be removed if candidate-gen takes over

### Implementation Steps

**Step 1:** Audit all priority ranges used in `warmr.metta` vs `candidate-gen.metta`:

| Rule | warmr.metta | candidate-gen.metta |
|------|-------------|---------------------|
| ref_root_const | 215 | 215 (conflict!) |
| ref_root_var | 216 | 216 (conflict!) |
| ref_root_unary | 217 | 217 (conflict!) |

**Step 2:** Decide on consolidation strategy:
- **Remove** the duplicate L1 rules from `warmr.metta` (stages 215–217) if `candidate-gen.metta` will cover them.
- Rename `candidate-gen.metta` stages to 250–279 (clear of `warmr.metta` 150–236) to avoid conflicts.

**Step 3:** Add `src/candidate-gen.metta` and `src/canonicalize.metta` to `run-warmr.sh`.

**Step 4:** Add validation: after integration, the CLI should produce exactly the candidates expected by the bias (verify via test assertions).

**Step 5:** Add missing candidate templates where needed:
- L1 ternary with 2 output vars: `pred(var0, var1, var2)` — not in candidate-gen.metta.
- L2 chain with ternary first literal: `pred1(var0,var1,const) ∧ pred2(var1,var2)`.
- L3 chain: `P1(v0,v1) ∧ P2(v1,v2) ∧ P3(v2,v3)` — no production rule.

### New Tests to Add

```metta
;; Test: CLI produces ternary L1 candidates when bias declares ternary modeb
;; Setup: transfer(+account, -account, #bank) with 3 available banks
;; Expected: 3 raw_candidates, one per bank constant
(EXPECTED-RESULT gen-ternary-cli (canonical_candidate (cand_l1 transfer chase) 1 ...))

;; Test: CLI produces all variable-slot L2 branched candidates
;; parent(v0,v1) ∧ parent(v0,v2) should be generated
(EXPECTED-RESULT gen-l2-branch-var-var ...)

;; Test: No duplicate candidates evaluated
;; If parent(v0,v1) can be generated by two different templates, candidate_support fires only once
(EXPECTED-RESULT no-duplicate-eval (candidate_support (cand_l1 parent var1) 4))
;; (not 8 from double evaluation)
```

### Acceptance Criteria
- `./scripts/run-warmr.sh` with the family dataset produces both `parent(X,Y)` and `parent(X,Y) ∧ parent(Y,Z)` as frequent patterns.
- `./scripts/run-warmr.sh` with the ternary dataset produces ternary candidates.
- No candidate is evaluated more than once (verified by `candidate_support` atom count = 1 per candidate).

### Risks
- Priority conflicts between `candidate-gen.metta` and `warmr.metta` may cause rules to fire in wrong order.
- Removing L1 rules from `warmr.metta` may break tests that depend on `cand_l1` naming.
- Integration may expose latent bugs in `candidate-gen.metta` rules that passed tests in isolation but fail in full pipeline.

---

## 7. Milestone 4 — Integrate Canonicalization into the CLI Pipeline

### Objective
Load `src/canonicalize.metta` in the production pipeline to ensure candidate deduplication is active during CLI execution.

### Current Status
`src/canonicalize.metta` implements correct 3-step canonicalization (sort, vars, indices). It is **not CLI-loaded**. The production pipeline relies on:
- `attr_lt` ordering constraints to prevent duplicate const-const pairs.
- `unary_lt` ordering (not defined in production files — defect D6).

### Problem
Without canonicalization, permutation-equivalent candidates (e.g., `P ∧ Q` and `Q ∧ P`) may both be evaluated, consuming extra compute and potentially producing duplicate `warmr_pattern` outputs.

### Required Behavior
- Every pair of syntactically permutation-equivalent or alpha-equivalent candidates collapses to a single canonical form.
- `candidate_pool` contains exactly one entry per unique canonical form.
- A candidate is evaluated at most once per canonical form.

### Files to Modify
- `scripts/run-warmr.sh` — add `--aux-path "$WORKSPACE_ROOT/src/canonicalize.metta"`
- Optionally: add a gate rule that prevents evaluation of `candidate` atoms that do not appear in `candidate_pool` (requires a pipeline stage after canonicalization)

### Implementation Steps

**Step 1:** Add `src/canonicalize.metta` to the `run-warmr.sh` `--aux-path` list.

**Step 2:** Verify that the `raw_candidate` → `canonical_candidate` → `candidate_pool` pipeline fires for all candidates generated by `candidate-gen.metta`.

Currently `warmr.metta` and `search-loop.metta` emit `candidate` atoms directly (not `raw_candidate`). The canonicalization pipeline operates only on `raw_candidate` atoms. **Decision required:** either convert production rules to emit `raw_candidate` first (then let canonicalization promote to `candidate`), or add a parallel canonicalization trigger for `candidate` atoms.

**Step 3:** Proposed intermediate atom flow:
```
raw_candidate → sort-atom → sorted_candidate
             → indices_to_vars → vars_candidate
             → vars_to_indices → canonical_candidate
             → candidate_pool (dedup gate)
             → candidate (ready for evaluation, only if new to pool)
```

This requires adding a "gate" rule:
```metta
(exec (warmr 234 promote_canonical_to_candidate)
  (, (canonical_candidate $id $len $canon $types $parent))
  (O (+ (candidate $id $len $canon $types $parent))
     (+ (candidate_pending_eval $id))))
```

**Step 4:** Remove the direct `(+ (candidate ...))` and `(+ (candidate_pending_eval ...))` emissions from the refinement rules in `candidate-gen.metta`, replacing them with `(+ (raw_candidate ...))` only. The canonicalization pipeline then promotes to `candidate`.

**Step 5:** This requires the production warmr.metta and search-loop.metta rules to also emit `raw_candidate` instead of `candidate`. **Assess impact on existing tests.**

### New Tests to Add

```metta
;; Test: Permutation-equivalent L2 candidates collapse to one pool entry
(raw_candidate c1 2 ((P (var 0) (const a)) (Q (var 0) (const b))) ...)
(raw_candidate c2 2 ((Q (var 0) (const b)) (P (var 0) (const a))) ...)
;; Expected: exactly 1 candidate_pool entry
(EXPECTED-RESULT canon-dedup-pool (candidate_pool 2 ((P (var 0) (const a)) (Q (var 0) (const b)))))
;; Expected: exactly 1 candidate evaluated (not 2)
;; This requires checking that candidate_support is counted once total
```

### Acceptance Criteria
- `candidate_pool` contains no duplicates (atom set semantics guarantees this).
- `candidate_support` for each logical query occurs exactly once.
- Existing `canonicalize-test.metta` assertions continue to pass.

### Risks
- Changing `candidate` to `raw_candidate` emission is a breaking change for all test files that inject `candidate` atoms directly.
- May require updating all 19 test files to inject `raw_candidate` instead of `candidate` — significant work.
- **Alternative approach:** Keep `candidate` injection in tests, add `raw_candidate` as an additional parallel path for the production pipeline. Document that test files bypass canonicalization intentionally (this is a valid test isolation strategy).

---

## 8. Milestone 5 — Correct Pruning and Search Loop

### Objective
Fix the two confirmed defects in `src/search-loop.metta` that prevent correct L2 unary expansion and that limit the pipeline to domain-specific constants.

### Problem 5.1: Missing `unary_lt` Definition (Defect D6)

`src/search-loop.metta:102` references `(unary_lt $p1 $p2)` as a guard for L2 unary expansion:
```metta
(exec (warmr 374 ref_l1_to_l2_unary)
  (, (expand_candidate_l1 (cand_l1 $p1))
     ...
     (unary_lt $p1 $p2))
  ...)
```

No `unary_lt` facts exist in any CLI-loaded file. This means the `ref_l1_to_l2_unary` rule never fires in the production CLI, silently suppressing all L2 unary–unary candidates for datasets with unary predicates.

**Fix:** Add `unary_lt` ordering facts to either:
- `src/search-loop.metta` (generic solution: derive from `allowed_body_predicate` ordering)
- Or generate dynamically from predicate names during bias compilation.

**Proposed approach:** Add a bias-compilation stage that generates `unary_lt` from alphabetical ordering of unary predicates:
```metta
;; In language-bias.metta: derive unary_lt from unary predicate ordering
(exec (warmr 145 derive_unary_lt)
  (, (allowed_body_predicate $key_pred $p1 ((+ $t)))
     (allowed_body_predicate $key_pred $p2 ((+ $t)))
     (atom_lt $p1 $p2))  ;; uses MORK's natural atom ordering
  (O (+ (unary_lt $p1 $p2))))
```

Alternatively, derive it from the `attr_lt` pattern already used for constants.

### Problem 5.2: Dataset-Specific `attr_lt` Constants (Defect D7)

`src/search-loop.metta` hardcodes:
```metta
(attr_lt human man)
(attr_lt human woman)
...
```

These are domain-specific attribute names from the MM2 `ugly-sodaDrinker` benchmark. For the family, synthetic-gene, ternary, or 4-ary datasets, no `attr_lt` facts apply, so the `ref_l1_to_l2_ordered` rule never fires.

**Fix:** Move `attr_lt` facts to `config/mm2-bias.metta` (or the dataset-specific bias file), not into `search-loop.metta`. The bias file is dataset-specific; the core engine should be dataset-agnostic.

**Proposed changes:**
1. Remove hardcoded `attr_lt` facts from `src/search-loop.metta`.
2. Add them to `config/mm2-bias.metta`.
3. The `ref_l1_to_l2_ordered` rule should work for any dataset that provides `attr_lt` ordering in its bias.

Similarly, the `ref_l1_to_l2_ordered` rule requires `(allowed_body_predicate positive_example $p2 ((+ $ptype) (# attribute)))` — the constant type must be named `attribute`. This should be generalized to any constant type.

### Files to Modify
- `src/search-loop.metta` (remove hardcoded `attr_lt` facts; fix unary_lt reference; generalize `# attribute` to `# $ctype`)
- `config/mm2-bias.metta` (add `attr_lt` facts moved from search-loop.metta)
- `src/language-bias.metta` (optional: add `unary_lt` derivation stage)

### New Tests to Add

```metta
;; Test: unary_lt ordering derived correctly
;; Given: active/1 and verified/1 declared in bias
;; Expected: unary_lt active verified (or verified active, whichever is alphabetical)
(EXPECTED-RESULT derived-unary-lt (unary_lt active verified))

;; Test: L2 unary expansion fires for dataset with unary predicates
;; Given: candidate (cand_l1 active) is frequent
;; Expected: (candidate (cand_l2 active verified) 2 ...) generated
(EXPECTED-RESULT l2-unary-generated (candidate (cand_l2 active verified) 2 ...))
```

### Acceptance Criteria
- Running with the unary-properties dataset and MAX_LENGTH=2 produces `active ∧ verified` as a Level 2 candidate.
- `attr_lt` facts are only present when loading an MM2-compatible bias file.
- For non-MM2 datasets, L2 ordered-const expansion works if the bias file provides appropriate ordering facts.

### Risks
- Moving `attr_lt` to the bias file is a breaking change for the pruning-test.metta and integration-test.metta, which currently inject `attr_lt` directly in the test body but also depend on search-loop.metta. Verify test impact.

---

## 9. Milestone 6 — Extend BFS to General MAX_LENGTH

### Objective
Implement a general BFS level progression mechanism that respects MAX_LENGTH for any depth, not just hardcoded L1→L2→L3.

### Current Status
The BFS in `search-loop.metta` explicitly handles:
- L1 → L2 (warmr 365–374)
- L2 → L3 (warmr 465–470)

For MAX_LENGTH = 4 or 5, there is no L3 → L4 expansion rule or L4 → L5. The search silently terminates at L3.

### Required Behavior
If MAX_LENGTH = k (for any k ≥ 1), the BFS should explore candidates up to length k.

### Design Approach

MORK's execution model is event-driven (priority-based rule firing), not procedural. A "loop" must be encoded as a recursive or staged pattern.

**Option A: Extend templates to L4 and L5**  
Add explicit L4 and L5 expansion gates and refinement rules, mirroring L2 and L3. Already partially done in `src/support-calc.metta` (L4/L5 evaluators exist). This approach:
- Is straightforward to implement.
- Does not solve the general case (L6+ still unsupported).
- Consistent with the existing design pattern.

**Option B: General recursive BFS using level counters**  
Use a `bfs_level` counter atom and a single generic rule that increments it:
```metta
(exec (warmr N expand_at_level_k)
  (, (bfs_level $k)
     (candidate_frequent $cid $cnt)
     (candidate $cid $k_len $body $types $parent)
     (num_lt $k_len $max_l))
  (O (+ (expand_at_level (+ $k_len 1) $cid))))
```

This requires MORK to support integer arithmetic in pattern matching or requires the `num_lt` table (bounded at 25 in the current pruning.metta).

**Recommendation: Option A extended to L5**  
Given the documented limitation (depth > 5 is not practically needed), extending templates to L5 is the least risky approach. The `num_lt` and `num_gte` tables already support values to 25.

### Files to Create/Modify
- `src/search-loop.metta` — add L3 expansion gate (warmr 548 `expand_frequent_l3`) and L4 refinement rules (warmr 550+)
- `src/search-loop.metta` — add L4 evaluation, counting, and classification stages
- `src/search-loop.metta` — add L4 expansion gate and L5 refinement/evaluation

### Implementation Steps

**Step 1:** Add L3 chain expansion (missing from current production pipeline):
```metta
;; Stage: expand_frequent_l3_chain (for chain-type L3 candidates)
(exec (warmr 548 expand_frequent_l3_chain)
  (, (candidate_frequent (cand_l3_chain $p1 $p2 $p3) $cnt)
     (candidate (cand_l3_chain $p1 $p2 $p3) 3 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 3 $max_l))
  (O (+ (expand_candidate_l3 (cand_l3_chain $p1 $p2 $p3)))))
```

**Step 2:** Add L4 refinement from frequent L3 candidates.

**Step 3:** Add L4 evaluation patterns in `src/support-calc.metta` (already partially done for chain-only patterns at warmr 319 `eval_l4_chain` and `eval_l4_branched_const`).

**Step 4:** Add L4 counting/classification rules mirroring L3 (stages 520–542).

### New Tests to Add

```metta
;; Test: MAX_LENGTH=4 produces L4 candidates
;; Setup: deep-chain dataset (n0→n1→n2→n3→n4→n5), MIN_SUPPORT=2, MAX_LENGTH=4
;; Expected: q_len4 is frequent and no q_len5 exists
(EXPECTED-RESULT l4-generated (candidate_frequent q_len4 2))
;; Expected: search terminates at L4 (not L5)
(EXPECTED-RESULT l4-termination (warmr_search_status completed 4))
```

### Acceptance Criteria
- `MAX_LENGTH=4` produces L4 candidates and terminates at L4.
- `MAX_LENGTH=3` still terminates at L3 (no regression).
- `deep-search-test.metta` L4 candidates are discovered via the BFS pipeline (not just via manual evaluation).

### Risks
- Adding more stages may cause priority collisions.
- The `cand_l3_chain` naming convention must be consistent with the naming in `search-loop.metta`'s existing L3 rules.

---

## 10. Milestone 7 — Output and WARMR Extensions

### Objective
Verify and clean up output formatting. Assess whether Phase 2 (association rule generation) is in scope.

### Current Status
`src/output.metta` correctly emits `warmr_pattern` records for `candidate_frequent` atoms. Output is correct by design.

### Problem 7.1: Output depends on `candidate` and `total_positive_keys`

The output rule at stage 560 requires:
1. `(candidate_frequent $cid $count)` — always present if classification ran.
2. `(candidate $cid $len $body $types $parent)` — the full candidate record.
3. `(total_positive_keys $tot)` — from stage 305 counting.
4. `(INPUT MIN_SUPPORT $min_s)` — from config.
5. `(INPUT DATASET_ID $did)` — from config.

If canonicalization (M4) changes `candidate` atoms to be promoted from `canonical_candidate`, the output rule should still work without modification. Verify after M4.

### Problem 7.2: Association Rule Generation (Phase 2)

The original WARMR paper describes generating rules Q1 ⇒ Q2 with confidence = supp(Q2) / supp(Q1).

**Assessment:** `docs/warmr-fundamentals.md` explicitly defers this as "Phase 2 (post-processing)." Unless the task document explicitly requires Phase 2, it remains out of scope.

**Recommendation:** Add a placeholder `src/assoc-rules.metta` documenting the formula and noting that it requires frequent patterns from Phase 1. Do not implement until Phase 1 is verified correct.

### Implementation Steps

**Step 1:** After M3 and M4, re-run the integration test and verify output records match expected patterns.

**Step 2:** If association rules are required by the task, implement:
```metta
;; For each pair of frequent patterns Q1 ⊂ Q2:
(exec (warmr 590 emit_association_rule)
  (, (candidate_frequent $cid1 $cnt1)
     (candidate_frequent $cid2 $cnt2)
     (candidate $cid1 $len1 $body1 $types $parent)
     (candidate $cid2 $len2 $body2 $types $parent2)
     ;; $body1 ⊂ $body2 — requires a subset-check primitive
     (is_subseteq $body1 $body2))
  (O (+ (warmr_rule (antecedent $cid1) (consequent $cid2) (confidence $cnt2 $cnt1)))))
```

This requires a `is_subseteq` primitive in MORK or a built-in body-containment check. Assess feasibility.

### New Tests to Add (If Phase 2 Required)
```metta
;; Test: association rule confidence
;; human (support 20) ⇒ human ∧ man (support 10)
;; confidence = 10/20 = 0.5
(EXPECTED-RESULT rule-human-man
  (warmr_rule (antecedent (cand_l1 human)) (consequent (cand_l2 human man)) (confidence 10 20)))
```

### Acceptance Criteria
- `warmr_pattern` records are emitted correctly for all frequent patterns.
- If Phase 2 is required: at least one test validates rule confidence computation.
- If Phase 2 is not required: `docs/limitations.md` clearly documents this boundary.

---

## 11. Milestone 8 — Full Regression and Acceptance

### Objective
Run the complete test suite, add end-to-end pipeline tests, and verify all supported configurations.

### Dependencies
All previous milestones (M0–M7) must be complete.

### Implementation Steps

**Step 1:** Run the full test suite: `./scripts/run-tests.sh`. All 270 existing assertions must pass.

**Step 2:** Add end-to-end CLI tests for each dataset:
```bash
# Family dataset: should produce parent and grandparent patterns
./scripts/run-warmr.sh --dataset data.metta --keys benchmarks/family-keys.metta \
  --bias config/family-bias.metta --min-support 2 --max-length 2
# Assert: warmr_pattern for parent(X,Y) and parent(X,Y)∧parent(Y,Z)

# Unary dataset: should produce active, verified, active∧verified
./scripts/run-warmr.sh --dataset benchmarks/unary-properties.metta \
  --keys benchmarks/unary-properties-keys.metta --bias config/unary-bias.metta \
  --min-support 5 --max-length 2
# Assert: 3 warmr_pattern records; premium is pruned

# Ternary dataset
./scripts/run-warmr.sh --dataset benchmarks/ternary-transactions.metta \
  --keys benchmarks/ternary-transactions-keys.metta --bias config/ternary-bias.metta \
  --min-support 2 --max-length 2
```

**Step 3:** Add an anti-monotonicity invariant test:
```metta
;; For every pair (parent, child) in the search tree:
;; support(child) <= support(parent)
;; This can be verified programmatically for the MM2 benchmark
```

**Step 4:** Add a "no duplicate evaluation" regression test:
```metta
;; Assert: no candidate is classified both frequent and infrequent
;; (which would indicate double-evaluation with conflicting results)
```

**Step 5:** Update `docs/verification-and-reproducibility.md` with new actual results and MORK version.

### Acceptance Criteria (Definition of Done)

See Section 13.

---

## 12. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| MORK binary cannot be compiled (Rust/Cargo unavailable) | Medium | Critical | Obtain pre-built binary; check package repositories |
| Priority conflicts when integrating candidate-gen.metta | High | High | Carefully map all priority ranges; rename stages to avoid overlap |
| Changing `candidate` → `raw_candidate` emission breaks all 19 tests | High | High | Use alternative path: add `raw_candidate` as parallel emission, don't remove `candidate` |
| `unary_lt` derivation collides with existing `attr_lt` logic | Low | Medium | Isolate unary and constant ordering into separate fact namespaces |
| Canonicalization changes break level-specific evaluation ordering | Medium | Medium | Test each change incrementally; run full suite after each module integration |
| General BFS (M6) introduces performance regression for large datasets | Low | Low | Add MAX_LENGTH guard; test with deep-chain benchmark |
| Moving `attr_lt` to bias file breaks pruning-test.metta | Medium | Low | Update test to inject `attr_lt` explicitly or use mm2-bias.metta |

---

## 13. Definition of Done

The project is **complete** when all of the following are true:

1. ✅ MORK binary executes correctly and can be installed reproducibly.
2. ✅ `./scripts/run-tests.sh` reports 100% pass rate on all existing assertions.
3. ✅ The CLI loads `candidate-gen.metta` and `canonicalize.metta` as part of the production pipeline.
4. ✅ Distinct-key support is correct: `family-test.metta` asserts `(candidate_support q_grandparent 2)` and this passes at runtime (not just by design inspection).
5. ✅ Anti-monotonic pruning is verified: `integration-test.metta` asserts `(candidate_infrequent (cand_l2 man woman) 0)` and this passes at runtime.
6. ✅ Candidate generation covers the declared language-bias search space: at least L1 (unary, binary, ternary) and L2 (branched, chained) for any configured bias.
7. ✅ BFS terminates correctly at MAX_LENGTH for any value from 1 to 5.
8. ✅ `unary_lt` ordering is defined in the production pipeline and L2 unary expansion works for the unary-properties dataset.
9. ✅ `attr_lt` ordering is moved to dataset-specific bias files, not embedded in `search-loop.metta`.
10. ✅ All meaningful tests cover realistic relational data with independently verified expected results.
11. ✅ End-to-end CLI tests (actual `run-warmr.sh` invocation) exist for at least 3 distinct datasets.
12. ✅ `docs/limitations.md` accurately reflects all remaining restrictions.
13. ✅ No claim of "complete WARMR implementation" is made without explicit scope qualification (arities 1–4, depths 1–N, Phase 1 only, no θ-subsumption).

---

## 14. Final Acceptance Checklist

```
[ ] M0: MORK binary compiled and symlink restored
[ ] M0: Baseline test execution recorded in docs/
[ ] M0: CLI smoke test passes for MM2 benchmark
[ ] M1: Duplicate counting rules resolved; single candidate_support per candidate
[ ] M1: Zero orphan key_witness atoms confirmed
[ ] M2: ± mode supported in language-bias.metta
[ ] M2: Multi-arg modeh handled in Stage 150
[ ] M3: candidate-gen.metta added to run-warmr.sh
[ ] M3: Priority conflicts between candidate-gen.metta and warmr.metta resolved
[ ] M3: Ternary L1 candidates generated by CLI for ternary dataset
[ ] M4: canonicalize.metta added to run-warmr.sh
[ ] M4: Duplicate candidate deduplication verified by test
[ ] M5: unary_lt ordering defined and L2 unary expansion works
[ ] M5: attr_lt moved from search-loop.metta to dataset bias files
[ ] M5: MM2 integration test still passes after attr_lt move
[ ] M6: L4 BFS expansion implemented and tested
[ ] M6: MAX_LENGTH=4 produces L4 candidates and terminates correctly
[ ] M7: Output records verified post-M3 and M4 changes
[ ] M8: 270+ assertions pass (new tests included)
[ ] M8: End-to-end CLI tests exist for ≥3 datasets
[ ] M8: Anti-monotonicity invariant test added and passing
[ ] M8: docs/verification-and-reproducibility.md updated with actual results
[ ] M8: docs/limitations.md accurately describes remaining scope restrictions
```

---

## Appendix A: Milestone Dependency Graph

```
M0 (Baseline)
│
├─► M1 (Key semantics)         [P2 — can proceed in parallel after M0]
│
├─► M2 (Language bias)         [P2 — can proceed after M0]
│       │
│       └─► M3 (Candidate gen) [P0 — depends on M2 for bias correctness]
│               │
│               └─► M4 (Canonicalization) [P0 — depends on M3]
│
└─► M5 (Pruning/search fixes)  [P1 — depends on M0]
        │
        └─► M6 (General BFS)   [P1 — depends on M5]
                │
                └─► M7 (Output) [P3 — depends on M6]
                        │
                        └─► M8 (Acceptance) [Final]
```

## Appendix B: Files That Must Not Be Modified Until Approval

Per audit task rules (Section 19 of the task document):
- All `.metta` source files in `src/`
- All test files in `tests/`
- All dataset files in `benchmarks/` and `data.metta`
- All configuration files in `config/`
- `scripts/run-warmr.sh` and `scripts/run-tests.sh`
- `README.md`

**Only `docs/WARMR-IMPLEMENTATION-AUDIT.md` and `docs/WARMR-COMPLETION-PLAN.md` are created by this audit task.**
