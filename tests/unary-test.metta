;; =============================================================================
;; tests/unary-test.metta
;; =============================================================================
;; Milestone 7 Generalization Test: Unary Relational Predicates (Arity 1)
;;
;; Validates:
;;   1. Language-bias compilation for unary predicates (modeb active (+ user)).
;;   2. Unary predicate support calculation against positive key domain (N = 10).
;;   3. Ground-truth absolute support:
;;        active(X):   8 / 10  (Frequent: 8 >= 5)
;;        verified(X): 6 / 10  (Frequent: 6 >= 5)
;;        premium(X):  4 / 10  (Infrequent: 4 < 5)
;;   4. Level 2 Conjunction of Unary Predicates:
;;        active(X) ∧ verified(X): 6 / 10 (Frequent: 6 >= 5)
;;   5. Rational relative support (8/10, 6/10, 4/10).
;;   6. Anti-monotonic pruning of infrequent unary branch (premium/1).
;;   7. Structured output record emission.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta
;; TEST-AUX benchmarks/unary-properties.metta
;; TEST-AUX benchmarks/unary-properties-keys.metta
;; TEST-AUX config/unary-bias.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 5)
(INPUT MAX_LENGTH 2)
(INPUT DATASET_ID unary_users)
(configured_limits (min_support 5) (max_length 2))

;; Initialize key domain counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 2. Evaluated Candidates (Unary Predicates)
;; -----------------------------------------------------------------------------
;; Q1: active(var 0)
(candidate q_active 1 ((active (var 0))) (((var 0) user)) root)
(candidate_pending_eval q_active)

;; Q2: verified(var 0)
(candidate q_verified 1 ((verified (var 0))) (((var 0) user)) root)
(candidate_pending_eval q_verified)

;; Q3: premium(var 0)
(candidate q_premium 1 ((premium (var 0))) (((var 0) user)) root)
(candidate_pending_eval q_premium)

;; Q4: active(var 0) ∧ verified(var 0)
(candidate q_active_verified 2 ((active (var 0)) (verified (var 0))) (((var 0) user)) q_active)
(candidate_pending_eval q_active_verified)

;; -----------------------------------------------------------------------------
;; 3. Expected Results (Verification Invariants)
;; -----------------------------------------------------------------------------
;; Domain size
(EXPECTED-RESULT unary-total-keys (total_positive_keys 10))

;; Support counts
(EXPECTED-RESULT unary-supp-active (candidate_support q_active 8))
(EXPECTED-RESULT unary-supp-verified (candidate_support q_verified 6))
(EXPECTED-RESULT unary-supp-premium (candidate_support q_premium 4))
(EXPECTED-RESULT unary-supp-conj (candidate_support q_active_verified 6))

;; Relative support
(EXPECTED-RESULT unary-rel-active (candidate_relative_support q_active 8 10))
(EXPECTED-RESULT unary-rel-verified (candidate_relative_support q_verified 6 10))
(EXPECTED-RESULT unary-rel-premium (candidate_relative_support q_premium 4 10))
(EXPECTED-RESULT unary-rel-conj (candidate_relative_support q_active_verified 6 10))

;; Frequency classifications
(EXPECTED-RESULT unary-freq-active (candidate_frequent q_active 8))
(EXPECTED-RESULT unary-freq-verified (candidate_frequent q_verified 6))
(EXPECTED-RESULT unary-infreq-premium (candidate_infrequent q_premium 4))
(EXPECTED-RESULT unary-freq-conj (candidate_frequent q_active_verified 6))

;; Anti-monotonic pruning of infrequent unary predicate
(EXPECTED-RESULT unary-prune-premium (prune_branch q_premium))
(EXPECTED-RESULT unary-confirm-premium (pruning_confirmed q_premium))

;; Structured output records
(EXPECTED-RESULT unary-out-active
  (warmr_pattern
    (id q_active)
    (length 1)
    (body ((active (var 0))))
    (absolute_support 8)
    (relative_support 8 10)
    (classification frequent)
    (dataset unary_users)
    (min_support 5)))

(EXPECTED-RESULT unary-out-conj
  (warmr_pattern
    (id q_active_verified)
    (length 2)
    (body ((active (var 0)) (verified (var 0))))
    (absolute_support 6)
    (relative_support 6 10)
    (classification frequent)
    (dataset unary_users)
    (min_support 5)))
