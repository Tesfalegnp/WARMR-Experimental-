;; =============================================================================
;; tests/support-test.metta
;; =============================================================================
;; Milestone 3 Support Calculation Test Suite — Synthetic Gene Dataset
;;
;; Validates:
;;   1. One-literal candidate evaluation (q1).
;;   2. Multiple proofs per key individual collapsing into 1 distinct witness (q2: gene_a 6 proofs).
;;   3. Two-literal branched conjunction (q2).
;;   4. Two-literal constant-variable branched conjunction (q_cv).
;;   5. Two-literal chained conjunction (q_chain).
;;   6. Zero-support candidate fallback (q_zero).
;;   7. Milestone 1 PoC legacy bare syntax backward compatibility (q_poc).
;;   8. Key domain total counting and exact relative support (denominator = 3).
;;   9. Atomic witness cleanup (0 orphan facts).
;; =============================================================================

;; TEST-AUX src/support-calc.metta

;; -----------------------------------------------------------------------------
;; 1. Synthetic Gene Domain Facts & Background Knowledge
;; -----------------------------------------------------------------------------
;; Positive Key Domain (Isolated: 3 distinct gene keys)
(positive_example gene_a)
(positive_example gene_b)
(positive_example gene_c)

;; Background Relational Facts
(pathway gene_a metabolism)
(pathway gene_a energy)
(pathway gene_a signaling)
(pathway gene_b metabolism)

(regulates gene_a gene_x)
(regulates gene_a gene_y)
(regulates gene_b gene_z)

(pathway gene_x metabolism)

;; Initialize domain key counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 2. Synthetic Gene Candidates
;; -----------------------------------------------------------------------------

;; q_poc: PoC legacy syntax (1 bare literal)
;; positive_example(A), pathway(A, P)
(candidate q_poc 1 (pathway (var 0) (var 1)))
(candidate_pending_eval q_poc)

;; q1: Level 1 full syntax
;; positive_example(A), pathway(A, P)
(candidate q1 1
  ((pathway (var 0) (var 1)))
  (((var 0) gene) ((var 1) pathway))
  root)
(candidate_pending_eval q1)

;; q2: Level 2 branched conjunction
;; positive_example(A), pathway(A, P), regulates(A, B)
;; gene_a: 3 pathways * 2 regulates = 6 proofs -> 1 distinct key witness
;; gene_b: 1 pathway * 1 regulates = 1 proof   -> 1 distinct key witness
;; gene_c: 0 pathways                          -> 0 witnesses
;; Expected distinct support = 2
(candidate q2 2
  ((pathway (var 0) (var 1))
   (regulates (var 0) (var 2)))
  (((var 0) gene) ((var 1) pathway) ((var 2) gene))
  q1)
(candidate_pending_eval q2)

;; q_cv: Level 2 constant-variable branched conjunction
;; positive_example(A), pathway(A, metabolism), regulates(A, B)
;; gene_a has metabolism & regulates (gene_x, gene_y) -> 1 witness
;; gene_b has metabolism & regulates (gene_z)         -> 1 witness
;; Expected distinct support = 2
(candidate q_cv 2
  ((pathway (var 0) (const metabolism))
   (regulates (var 0) (var 1)))
  (((var 0) gene) ((var 1) gene))
  q1)
(candidate_pending_eval q_cv)

;; q_chain: Level 2 chained conjunction
;; positive_example(A), regulates(A, B), pathway(B, P)
;; gene_a regulates gene_x (pathway metabolism) -> 1 witness
;; gene_b regulates gene_z (no pathway)         -> 0 witnesses
;; Expected distinct support = 1
(candidate q_chain 2
  ((regulates (var 0) (var 1))
   (pathway (var 1) (var 2)))
  (((var 0) gene) ((var 1) gene) ((var 2) pathway))
  q_reg)
(candidate_pending_eval q_chain)

;; q_zero: Level 2 candidate with zero support
;; positive_example(A), pathway(A, respiration), regulates(A, B)
;; No gene has pathway respiration -> 0 witnesses
;; Expected support = 0 (handled via zero_support_fallback)
(candidate q_zero 2
  ((pathway (var 0) (const respiration))
   (regulates (var 0) (var 1)))
  (((var 0) gene) ((var 1) gene))
  q_resp)
(candidate_pending_eval q_zero)

;; -----------------------------------------------------------------------------
;; 3. Expected Results & Assertions
;; -----------------------------------------------------------------------------

;; Isolated Domain Total: 3 Positive Keys
(EXPECTED-RESULT exp-total-keys (total_positive_keys 3))

;; Absolute Support Counts
(EXPECTED-RESULT exp-q-poc (candidate_support q_poc 2))
(EXPECTED-RESULT exp-q1 (candidate_support q1 2))
(EXPECTED-RESULT exp-q2 (candidate_support q2 2))
(EXPECTED-RESULT exp-q-cv (candidate_support q_cv 2))
(EXPECTED-RESULT exp-q-chain (candidate_support q_chain 1))
(EXPECTED-RESULT exp-q-zero (candidate_support q_zero 0))

;; Relative Support Values (Exact Rational: count / 3)
(EXPECTED-RESULT exp-q-poc-rel (candidate_relative_support q_poc 2 3))
(EXPECTED-RESULT exp-q1-rel (candidate_relative_support q1 2 3))
(EXPECTED-RESULT exp-q2-rel (candidate_relative_support q2 2 3))
(EXPECTED-RESULT exp-q-cv-rel (candidate_relative_support q_cv 2 3))
(EXPECTED-RESULT exp-q-chain-rel (candidate_relative_support q_chain 1 3))
(EXPECTED-RESULT exp-q-zero-rel (candidate_relative_support q_zero 0 3))
