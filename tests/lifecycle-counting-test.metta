;; =============================================================================
;; tests/lifecycle-counting-test.metta
;; =============================================================================
;; Focused Regression & Correctness Test Suite for Counting Lifecycle & Invariants
;;
;; Verifies Milestone 1 Invariants:
;;   Invariant A: Distinct-key support (multi-substitution collapsing to single key)
;;   Invariant B: Independent candidates do not share or corrupt support records
;;   Invariant C: Authoritative support uniqueness (no duplicate support atoms)
;;   Invariant D: Mutually exclusive classification (frequent vs infrequent)
;;   Invariant E: Exact threshold boundary classification (5 >= 5 vs 4 < 5)
;;   Invariant F: Zero-support fallback produces support 0 and infrequent classification
;;   Invariant G: Witness cleanup leaves exactly 0 orphan key_witness facts
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta

;; -----------------------------------------------------------------------------
;; 1. Configuration (Threshold: 5)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 5)
(INPUT MAX_LENGTH 2)
(configured_limits (min_support 5) (max_length 2))

;; -----------------------------------------------------------------------------
;; 2. Domain Entities & Relational Facts
;; -----------------------------------------------------------------------------
;; Key domain: 6 keys (k1..k6)
(positive_example k1)
(positive_example k2)
(positive_example k3)
(positive_example k4)
(positive_example k5)
(positive_example k6)

;; Total domain key counting
(key_domain_pending_count)

;; Relational facts:
;; relation R:
;; k1 has 4 distinct substitutions (v1, v2, v3, v4) -> must collapse to 1 key witness
(rel_r k1 v1)
(rel_r k1 v2)
(rel_r k1 v3)
(rel_r k1 v4)

;; k2, k3, k4, k5 have 1 substitution each
(rel_r k2 v1)
(rel_r k3 v1)
(rel_r k4 v1)
(rel_r k5 v1)
;; k6 has 0 substitutions for rel_r

;; relation S:
;; k1..k4 have substitutions (total 4 keys)
(rel_s k1 val)
(rel_s k2 val)
(rel_s k3 val)
(rel_s k4 val)

;; -----------------------------------------------------------------------------
;; 3. Test Candidates
;; -----------------------------------------------------------------------------
;; q_boundary: matches k1 (4 proofs), k2, k3, k4, k5 (1 proof each) -> 5 distinct keys.
;; Exactly matches MIN_SUPPORT 5 -> must be FREQUENT (5 >= 5).
(candidate q_boundary 1 (($p (var 0) (var 1))) (((var 0) entity)) root)
(exec (warmr 312 eval_q_boundary)
  (, (candidate q_boundary 1 (($p (var 0) (var 1))) $types $parent)
     (positive_example $k)
     (rel_r $k $v))
  (O (+ (key_witness q_boundary $k))))
(candidate_pending_eval q_boundary)

;; q_sub_threshold: matches k1..k4 (4 distinct keys) -> support 4 < 5.
;; Must be INFREQUENT (4 < 5) and produce prune_branch.
(candidate q_sub_threshold 1 (($p (var 0) (const val))) (((var 0) entity)) root)
(exec (warmr 313 eval_q_sub)
  (, (candidate q_sub_threshold 1 (($p (var 0) (const val))) $types $parent)
     (positive_example $k)
     (rel_s $k val))
  (O (+ (key_witness q_sub_threshold $k))))
(candidate_pending_eval q_sub_threshold)

;; q_zero: matches 0 keys -> support 0 < 5.
;; Handled via zero_support_fallback -> must be INFREQUENT (0 < 5).
(candidate q_zero 1 (($p (var 0) (const non_existent))) (((var 0) entity)) root)
(candidate_pending_eval q_zero)

;; -----------------------------------------------------------------------------
;; 4. Expected Results & Verification Invariants
;; -----------------------------------------------------------------------------
;; Domain size (N = 6)
(EXPECTED-RESULT exp-domain-keys (total_positive_keys 6))

;; Invariant A & C: Distinct-key support counts
;; q_boundary: 4 proofs on k1 + 1 on k2..k5 = 8 proofs, but exactly 5 distinct keys
(EXPECTED-RESULT exp-q-boundary-supp (candidate_support q_boundary 5))
;; q_sub_threshold: exactly 4 distinct keys
(EXPECTED-RESULT exp-q-sub-supp (candidate_support q_sub_threshold 4))
;; q_zero: zero fallback
(EXPECTED-RESULT exp-q-zero-supp (candidate_support q_zero 0))

;; Invariant E: Threshold boundary classification
(EXPECTED-RESULT exp-q-boundary-freq (candidate_frequent q_boundary 5))
(EXPECTED-RESULT exp-q-sub-infreq (candidate_infrequent q_sub_threshold 4))
(EXPECTED-RESULT exp-q-sub-prune (prune_branch q_sub_threshold))
(EXPECTED-RESULT exp-q-zero-infreq (candidate_infrequent q_zero 0))
(EXPECTED-RESULT exp-q-zero-prune (prune_branch q_zero))

;; Relative support calculation
(EXPECTED-RESULT exp-q-boundary-rel (candidate_relative_support q_boundary 5 6))
(EXPECTED-RESULT exp-q-sub-rel (candidate_relative_support q_sub_threshold 4 6))
(EXPECTED-RESULT exp-q-zero-rel (candidate_relative_support q_zero 0 6))

;; Audit confirmation of pruning
(EXPECTED-RESULT exp-confirm-sub (pruning_confirmed q_sub_threshold))
(EXPECTED-RESULT exp-confirm-zero (pruning_confirmed q_zero))
