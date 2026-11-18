;; =============================================================================
;; tests/higher-arity-test.metta
;; =============================================================================
;; Milestone 7 Generalization Test: 4-Ary Relational Predicates (Arity 4)
;;
;; Validates:
;;   1. Language-bias compilation for 4-ary relation:
;;        audit_log(+user, #action, #device, #status)
;;   2. 4-Ary support calculation with mixed input, variable, and constant slots.
;;   3. Multi-proof collapsing: usr1 has 2 successful audit events, collapsing
;;      into exactly 1 key witness.
;;   4. Ground-truth support counts (N = 5 users):
;;        audit_log(X, login, mobile, success): 2 / 5 (usr1, usr2 -> Frequent)
;;        audit_log(X, V1, V2, success):        4 / 5 (usr1, usr2, usr3, usr5 -> Frequent)
;;        audit_log(X, transfer, mobile, success): 0 / 5 (0 < 2 -> Infrequent)
;;   5. Rational relative support (2/5, 4/5, 0/5).
;;   6. Anti-monotonic pruning of zero-support candidate.
;;   7. Structured output records.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta
;; TEST-AUX benchmarks/events-4ary.metta
;; TEST-AUX benchmarks/events-4ary-keys.metta
;; TEST-AUX config/events-4ary-bias.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 2)
(INPUT MAX_LENGTH 2)
(INPUT DATASET_ID 4ary_events)
(configured_limits (min_support 2) (max_length 2))

;; Initialize key domain counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 2. Evaluated Candidates (4-Ary Predicates)
;; -----------------------------------------------------------------------------
;; Q1: audit_log(var 0, const login, const mobile, const success)
;; Matches usr1, usr2 -> total = 2.
(candidate q_login_mobile 1
  ((audit_log (var 0) (const login) (const mobile) (const success)))
  (((var 0) user))
  root)
(candidate_pending_eval q_login_mobile)

;; Q2: audit_log(var 0, var 1, var 2, const success)
;; Matches usr1, usr2, usr3, usr5 -> total = 4.
(candidate q_any_success 1
  ((audit_log (var 0) (var 1) (var 2) (const success)))
  (((var 0) user) ((var 1) action) ((var 2) device))
  root)
(candidate_pending_eval q_any_success)

;; Q3: audit_log(var 0, const transfer, const mobile, const success)
;; Matches 0 -> total = 0.
(candidate q_transfer_zero 1
  ((audit_log (var 0) (const transfer) (const mobile) (const success)))
  (((var 0) user))
  root)
(candidate_pending_eval q_transfer_zero)

;; -----------------------------------------------------------------------------
;; 3. Expected Results (Verification Invariants)
;; -----------------------------------------------------------------------------
;; Domain size
(EXPECTED-RESULT fourary-total-keys (total_positive_keys 5))

;; Support counts
(EXPECTED-RESULT fourary-supp-login (candidate_support q_login_mobile 2))
(EXPECTED-RESULT fourary-supp-success (candidate_support q_any_success 4))
(EXPECTED-RESULT fourary-supp-zero (candidate_support q_transfer_zero 0))

;; Relative support
(EXPECTED-RESULT fourary-rel-login (candidate_relative_support q_login_mobile 2 5))
(EXPECTED-RESULT fourary-rel-success (candidate_relative_support q_any_success 4 5))
(EXPECTED-RESULT fourary-rel-zero (candidate_relative_support q_transfer_zero 0 5))

;; Frequency classifications
(EXPECTED-RESULT fourary-freq-login (candidate_frequent q_login_mobile 2))
(EXPECTED-RESULT fourary-freq-success (candidate_frequent q_any_success 4))
(EXPECTED-RESULT fourary-infreq-zero (candidate_infrequent q_transfer_zero 0))

;; Anti-monotonic pruning
(EXPECTED-RESULT fourary-prune-zero (prune_branch q_transfer_zero))
(EXPECTED-RESULT fourary-confirm-zero (pruning_confirmed q_transfer_zero))

;; Structured output records
(EXPECTED-RESULT fourary-out-login
  (warmr_pattern
    (id q_login_mobile)
    (length 1)
    (body ((audit_log (var 0) (const login) (const mobile) (const success))))
    (absolute_support 2)
    (relative_support 2 5)
    (classification frequent)
    (dataset 4ary_events)
    (min_support 2)))

(EXPECTED-RESULT fourary-out-success
  (warmr_pattern
    (id q_any_success)
    (length 1)
    (body ((audit_log (var 0) (var 1) (var 2) (const success))))
    (absolute_support 4)
    (relative_support 4 5)
    (classification frequent)
    (dataset 4ary_events)
    (min_support 2)))
