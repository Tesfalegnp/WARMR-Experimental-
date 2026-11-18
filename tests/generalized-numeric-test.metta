;; =============================================================================
;; tests/generalized-numeric-test.metta
;; =============================================================================
;; Milestone 7 Generalization Test: 64-bit Numeric Thresholding & Pruning
;;
;; Validates:
;;   1. Support thresholds far exceeding bounded tables (> 25, tested at 500).
;;   2. Large absolute support counts (1,000 positive key witnesses).
;;   3. Boundary condition: support equal to threshold (500 == 500 -> frequent).
;;   4. Strict inequality: support one less than threshold (499 < 500 -> infrequent).
;;   5. Zero support candidate handling (0 < 500 -> infrequent + prune_branch).
;;   6. Clean emission of (candidate_frequent) and (prune_branch) markers.
;;   7. Execution without table lookup dependencies.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration (High Threshold: MIN_SUPPORT = 500)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 500)
(INPUT MAX_LENGTH 2)
(configured_limits (min_support 500) (max_length 2))

;; -----------------------------------------------------------------------------
;; 2. Simulated Candidate Support Facts (Covering 0, Boundary, and 1,000)
;; -----------------------------------------------------------------------------
;; Candidate q_large: 1,000 keys (Frequent: 1000 >= 500)
(candidate_support q_large 1000)

;; Candidate q_boundary: Exactly 500 keys (Frequent: 500 >= 500)
(candidate_support q_boundary 500)

;; Candidate q_near_miss: 499 keys (Infrequent: 499 < 500)
(candidate_support q_near_miss 499)

;; Candidate q_zero: 0 keys (Infrequent: 0 < 500)
(candidate_support q_zero 0)

;; -----------------------------------------------------------------------------
;; 3. Expected Results (Verification Invariants)
;; -----------------------------------------------------------------------------
;; Frequent classifications
(EXPECTED-RESULT num-q-large-freq (candidate_frequent q_large 1000))
(EXPECTED-RESULT num-q-boundary-freq (candidate_frequent q_boundary 500))

;; Infrequent classifications
(EXPECTED-RESULT num-q-near-infreq (candidate_infrequent q_near_miss 499))
(EXPECTED-RESULT num-q-zero-infreq (candidate_infrequent q_zero 0))

;; Anti-monotonic pruning branch markers
(EXPECTED-RESULT num-q-near-prune (prune_branch q_near_miss))
(EXPECTED-RESULT num-q-zero-prune (prune_branch q_zero))

;; Pruning audit confirmations
(EXPECTED-RESULT num-q-near-confirm (pruning_confirmed q_near_miss))
(EXPECTED-RESULT num-q-zero-confirm (pruning_confirmed q_zero))
