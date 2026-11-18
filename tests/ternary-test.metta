;; =============================================================================
;; tests/ternary-test.metta
;; =============================================================================
;; Milestone 7 Generalization Test: Ternary Relational Predicates (Arity 3)
;;
;; Validates:
;;   1. Language-bias compilation for ternary relation:
;;        transfer(+account, -account, #bank)
;;   2. Ternary support calculation with mixed input, output, and constant slots.
;;   3. Multi-proof collapsing: acc1 transfers to both acc2 and acc3 via chase,
;;      yielding 2 substitution proofs but collapsing into exactly 1 key witness.
;;   4. Ground-truth support counts (N = 6 accounts):
;;        transfer(var 0, var 1, const chase): 2 / 6 (acc1, acc2 -> Frequent)
;;        transfer(var 0, var 1, var 2):       5 / 6 (acc1..acc5 -> Frequent)
;;        transfer(var 0, var 1, unknown_bank):0 / 6 (0 < 2 -> Infrequent)
;;   5. Level 2 Chained Ternary Conjunction:
;;        transfer(X, Y, chase) ∧ transfer(Y, Z, chase): 1 / 6 (acc1)
;;   6. Rational relative support (2/6, 5/6, 0/6, 1/6).
;;   7. Anti-monotonic pruning of zero-support candidate.
;;   8. Structured output records.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta
;; TEST-AUX benchmarks/ternary-transactions.metta
;; TEST-AUX benchmarks/ternary-transactions-keys.metta
;; TEST-AUX config/ternary-bias.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 2)
(INPUT MAX_LENGTH 2)
(INPUT DATASET_ID ternary_trans)
(configured_limits (min_support 2) (max_length 2))

;; Initialize key domain counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 2. Evaluated Candidates (Ternary Predicates)
;; -----------------------------------------------------------------------------
;; Q1: transfer(var 0, var 1, const chase)
;; acc1 has 2 transfers -> 1 witness; acc2 has 1 transfer -> 1 witness; total = 2.
(candidate q_chase 1 ((transfer (var 0) (var 1) (const chase))) (((var 0) account) ((var 1) account)) root)
(candidate_pending_eval q_chase)

;; Q2: transfer(var 0, var 1, var 2) [All free variables]
;; Matches acc1, acc2, acc3, acc4, acc5 -> total = 5.
(candidate q_any 1 ((transfer (var 0) (var 1) (var 2))) (((var 0) account) ((var 1) account) ((var 2) bank)) root)
(candidate_pending_eval q_any)

;; Q3: transfer(var 0, var 1, const unknown_bank)
;; Matches 0 -> total = 0.
(candidate q_unknown 1 ((transfer (var 0) (var 1) (const unknown_bank))) (((var 0) account) ((var 1) account)) root)
(candidate_pending_eval q_unknown)

;; Q4: Level 2 Chained Ternary Conjunction: transfer(X, Y, chase) ∧ transfer(Y, Z, chase)
;; acc1 -> acc2 -> acc4 -> total = 1.
(candidate q_chain 2
  ((transfer (var 0) (var 1) (const chase)) (transfer (var 1) (var 2) (const chase)))
  (((var 0) account) ((var 1) account) ((var 2) account))
  q_chase)
(candidate_pending_eval q_chain)

;; -----------------------------------------------------------------------------
;; 3. Expected Results (Verification Invariants)
;; -----------------------------------------------------------------------------
;; Domain size
(EXPECTED-RESULT tern-total-keys (total_positive_keys 6))

;; Support counts
(EXPECTED-RESULT tern-supp-chase (candidate_support q_chase 2))
(EXPECTED-RESULT tern-supp-any (candidate_support q_any 5))
(EXPECTED-RESULT tern-supp-unknown (candidate_support q_unknown 0))
(EXPECTED-RESULT tern-supp-chain (candidate_support q_chain 1))

;; Relative support
(EXPECTED-RESULT tern-rel-chase (candidate_relative_support q_chase 2 6))
(EXPECTED-RESULT tern-rel-any (candidate_relative_support q_any 5 6))
(EXPECTED-RESULT tern-rel-unknown (candidate_relative_support q_unknown 0 6))
(EXPECTED-RESULT tern-rel-chain (candidate_relative_support q_chain 1 6))

;; Frequency classifications
(EXPECTED-RESULT tern-freq-chase (candidate_frequent q_chase 2))
(EXPECTED-RESULT tern-freq-any (candidate_frequent q_any 5))
(EXPECTED-RESULT tern-infreq-unknown (candidate_infrequent q_unknown 0))
(EXPECTED-RESULT tern-infreq-chain (candidate_infrequent q_chain 1))

;; Anti-monotonic pruning
(EXPECTED-RESULT tern-prune-unknown (prune_branch q_unknown))
(EXPECTED-RESULT tern-confirm-unknown (pruning_confirmed q_unknown))

;; Structured output records
(EXPECTED-RESULT tern-out-chase
  (warmr_pattern
    (id q_chase)
    (length 1)
    (body ((transfer (var 0) (var 1) (const chase))))
    (absolute_support 2)
    (relative_support 2 6)
    (classification frequent)
    (dataset ternary_trans)
    (min_support 2)))

(EXPECTED-RESULT tern-out-any
  (warmr_pattern
    (id q_any)
    (length 1)
    (body ((transfer (var 0) (var 1) (var 2))))
    (absolute_support 5)
    (relative_support 5 6)
    (classification frequent)
    (dataset ternary_trans)
    (min_support 2)))
