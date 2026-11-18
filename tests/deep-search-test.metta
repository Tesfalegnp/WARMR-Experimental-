;; =============================================================================
;; tests/deep-search-test.metta
;; =============================================================================
;; Milestone 7 Generalization Test: Deep Relational Conjunctions (Lengths 4 & 5)
;;
;; Validates:
;;   1. Execution of relational conjunctions beyond Level 3:
;;        Length 4: step(A, B) ∧ step(B, C) ∧ step(C, D) ∧ step(D, E)
;;        Length 5: step(A, B) ∧ step(B, C) ∧ step(C, D) ∧ step(D, E) ∧ step(E, F)
;;   2. Multi-proof collapsing at depth 5: node n0 has 2 distinct 5-hop paths
;;      (through n1 and n1_alt), collapsing into exactly 1 distinct key witness.
;;   3. Ground-truth support counts (N = 6 nodes):
;;        Length 1: 5 / 6 (n0..n4 -> Frequent)
;;        Length 2: 4 / 6 (n0..n3 -> Frequent)
;;        Length 3: 3 / 6 (n0..n2 -> Frequent)
;;        Length 4: 2 / 6 (n0, n1 -> Frequent: 2 >= 2)
;;        Length 5: 1 / 6 (n0     -> Infrequent: 1 < 2)
;;   4. Exact rational relative support across all 5 depths:
;;        5/6, 4/6, 3/6, 2/6, 1/6.
;;   5. Anti-monotonic pruning at depth 5 (prune_branch q_len5).
;;   6. Structured output record emission for length 4 frequent pattern.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta
;; TEST-AUX benchmarks/deep-chain.metta
;; TEST-AUX benchmarks/deep-chain-keys.metta
;; TEST-AUX config/deep-chain-bias.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging (MIN_SUPPORT = 2)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 2)
(INPUT MAX_LENGTH 5)
(INPUT DATASET_ID deep_chain)
(configured_limits (min_support 2) (max_length 5))

;; Initialize key domain counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 2. Evaluated Candidates (Lengths 1 Through 5)
;; -----------------------------------------------------------------------------
;; Q1: Length 1
(candidate q_len1 1
  ((step (var 0) (var 1)))
  (((var 0) node) ((var 1) node))
  root)
(candidate_pending_eval q_len1)

;; Q2: Length 2
(candidate q_len2 2
  ((step (var 0) (var 1)) (step (var 1) (var 2)))
  (((var 0) node) ((var 1) node) ((var 2) node))
  q_len1)
(candidate_pending_eval q_len2)

;; Q3: Length 3
(candidate q_len3 3
  ((step (var 0) (var 1)) (step (var 1) (var 2)) (step (var 2) (var 3)))
  (((var 0) node) ((var 1) node) ((var 2) node) ((var 3) node))
  q_len2)
(candidate_pending_eval q_len3)

;; Q4: Length 4
(candidate q_len4 4
  ((step (var 0) (var 1)) (step (var 1) (var 2)) (step (var 2) (var 3)) (step (var 3) (var 4)))
  (((var 0) node) ((var 1) node) ((var 2) node) ((var 3) node) ((var 4) node))
  q_len3)
(candidate_pending_eval q_len4)

;; Q5: Length 5 (n0 matches via 2 distinct proofs -> collapses to 1 key witness)
(candidate q_len5 5
  ((step (var 0) (var 1)) (step (var 1) (var 2)) (step (var 2) (var 3)) (step (var 3) (var 4)) (step (var 4) (var 5)))
  (((var 0) node) ((var 1) node) ((var 2) node) ((var 3) node) ((var 4) node) ((var 5) node))
  q_len4)
(candidate_pending_eval q_len5)

;; -----------------------------------------------------------------------------
;; 3. Expected Results (Verification Invariants)
;; -----------------------------------------------------------------------------
;; Domain size
(EXPECTED-RESULT deep-total-keys (total_positive_keys 6))

;; Support counts
(EXPECTED-RESULT deep-supp-l1 (candidate_support q_len1 5))
(EXPECTED-RESULT deep-supp-l2 (candidate_support q_len2 4))
(EXPECTED-RESULT deep-supp-l3 (candidate_support q_len3 3))
(EXPECTED-RESULT deep-supp-l4 (candidate_support q_len4 2))
(EXPECTED-RESULT deep-supp-l5 (candidate_support q_len5 1))

;; Relative support
(EXPECTED-RESULT deep-rel-l1 (candidate_relative_support q_len1 5 6))
(EXPECTED-RESULT deep-rel-l2 (candidate_relative_support q_len2 4 6))
(EXPECTED-RESULT deep-rel-l3 (candidate_relative_support q_len3 3 6))
(EXPECTED-RESULT deep-rel-l4 (candidate_relative_support q_len4 2 6))
(EXPECTED-RESULT deep-rel-l5 (candidate_relative_support q_len5 1 6))

;; Frequency classifications
(EXPECTED-RESULT deep-freq-l1 (candidate_frequent q_len1 5))
(EXPECTED-RESULT deep-freq-l2 (candidate_frequent q_len2 4))
(EXPECTED-RESULT deep-freq-l3 (candidate_frequent q_len3 3))
(EXPECTED-RESULT deep-freq-l4 (candidate_frequent q_len4 2))
(EXPECTED-RESULT deep-infreq-l5 (candidate_infrequent q_len5 1))

;; Anti-monotonic pruning of length 5 candidate
(EXPECTED-RESULT deep-prune-l5 (prune_branch q_len5))
(EXPECTED-RESULT deep-confirm-l5 (pruning_confirmed q_len5))

;; Structured output record for length 4 frequent pattern
(EXPECTED-RESULT deep-out-l4
  (warmr_pattern
    (id q_len4)
    (length 4)
    (body ((step (var 0) (var 1)) (step (var 1) (var 2)) (step (var 2) (var 3)) (step (var 3) (var 4))))
    (absolute_support 2)
    (relative_support 2 6)
    (classification frequent)
    (dataset deep_chain)
    (min_support 2)))
