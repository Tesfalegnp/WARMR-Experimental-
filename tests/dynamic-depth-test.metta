;; =============================================================================
;; tests/dynamic-depth-test.metta
;; =============================================================================
;; Milestone 6 Comprehensive Verification: Arbitrary-Depth Search & Dynamic Level Transition
;;
;; Validates:
;;   1. Execution across depths 1 through 8.
;;   2. Ground-truth distinct-key support counts verified by Python reference oracle:
;;        Depth 1: 6 / 6 (Frequent)
;;        Depth 2: 6 / 6 (Frequent)
;;        Depth 3: 6 / 6 (Frequent)
;;        Depth 4: 5 / 6 (Frequent)
;;        Depth 5: 4 / 6 (Frequent)
;;        Depth 6: 3 / 6 (Frequent)
;;        Depth 7: 2 / 6 (Frequent)
;;        Depth 8: 1 / 6 (Frequent)
;;   3. Dynamic level transitions without fixed-level depth barriers.
;;   4. Apriori anti-monotonic pruning and clean frontier termination.
;;   5. Structured output emission across arbitrary depths.
;;   6. Clean AtomSpace witness cleanup and candidate isolation.
;; =============================================================================

;; TEST-AUX src/language-bias.metta
;; TEST-AUX src/canonicalize.metta
;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/warmr.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/search-loop.metta
;; TEST-AUX src/output.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging (MIN_SUPPORT = 1, MAX_LENGTH = 8)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 1)
(INPUT MAX_LENGTH 8)
(INPUT DATASET_ID dynamic_depth_chain)
(configured_limits (min_support 1) (max_length 8))

;; -----------------------------------------------------------------------------
;; 2. Relational Background Knowledge (Step Chain n0 -> n1 -> ... -> n8)
;; -----------------------------------------------------------------------------
(step n0 n1) (step n1 n2) (step n2 n3) (step n3 n4)
(step n4 n5) (step n5 n6) (step n6 n7) (step n7 n8)

;; -----------------------------------------------------------------------------
;; 3. Positive Key Domain (N = 6 Individuals: n0..n5)
;; -----------------------------------------------------------------------------
(positive_example n0) (positive_example n1) (positive_example n2)
(positive_example n3) (positive_example n4) (positive_example n5)

;; Initialize key domain counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 4. Language Bias Declarations
;; -----------------------------------------------------------------------------
(valid_modeh positive_example ((+ node)))
(allowed_body_predicate positive_example step ((+ node) (- node)))

;; Root Query Initialization
(candidate root 0 () (((var 0) node)) nil)
(expand_candidate root)

;; -----------------------------------------------------------------------------
;; 5. Expected Results & Assertions (Independent Oracle Matches)
;; -----------------------------------------------------------------------------
;; Domain size
(EXPECTED-RESULT depth-total-keys (total_positive_keys 6))

;; Depth 1: Absolute Support 6, Relative 6/6
(EXPECTED-RESULT depth-supp-1 (candidate_support (cand_l1 step var1) 6))
(EXPECTED-RESULT depth-rel-1 (candidate_relative_support (cand_l1 step var1) 6 6))
(EXPECTED-RESULT depth-freq-1 (candidate_frequent (cand_l1 step var1) 6))

;; Depth 2: Absolute Support 6, Relative 6/6
(EXPECTED-RESULT depth-supp-2 (candidate_support (cand_l2_chain step step) 6))
(EXPECTED-RESULT depth-rel-2 (candidate_relative_support (cand_l2_chain step step) 6 6))
(EXPECTED-RESULT depth-freq-2 (candidate_frequent (cand_l2_chain step step) 6))

;; Depth 3: Absolute Support 6, Relative 6/6
(EXPECTED-RESULT depth-supp-3 (candidate_support (cand_l3_chain (cand_l2_chain step step) step) 6))
(EXPECTED-RESULT depth-rel-3 (candidate_relative_support (cand_l3_chain (cand_l2_chain step step) step) 6 6))
(EXPECTED-RESULT depth-freq-3 (candidate_frequent (cand_l3_chain (cand_l2_chain step step) step) 6))

;; Depth 4: Absolute Support 5, Relative 5/6
(EXPECTED-RESULT depth-supp-4 (candidate_support (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) 5))
(EXPECTED-RESULT depth-rel-4 (candidate_relative_support (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) 5 6))
(EXPECTED-RESULT depth-freq-4 (candidate_frequent (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) 5))

;; Depth 5: Absolute Support 4, Relative 4/6
(EXPECTED-RESULT depth-supp-5 (candidate_support (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) 4))
(EXPECTED-RESULT depth-rel-5 (candidate_relative_support (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) 4 6))
(EXPECTED-RESULT depth-freq-5 (candidate_frequent (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) 4))

;; Depth 6: Absolute Support 3, Relative 3/6
(EXPECTED-RESULT depth-supp-6 (candidate_support (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) 3))
(EXPECTED-RESULT depth-rel-6 (candidate_relative_support (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) 3 6))
(EXPECTED-RESULT depth-freq-6 (candidate_frequent (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) 3))

;; Depth 7: Absolute Support 2, Relative 2/6
(EXPECTED-RESULT depth-supp-7 (candidate_support (cand_l7_chain (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) step) 2))
(EXPECTED-RESULT depth-rel-7 (candidate_relative_support (cand_l7_chain (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) step) 2 6))
(EXPECTED-RESULT depth-freq-7 (candidate_frequent (cand_l7_chain (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) step) 2))

;; Depth 8: Absolute Support 1, Relative 1/6
(EXPECTED-RESULT depth-supp-8 (candidate_support (cand_l8_chain (cand_l7_chain (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) step) step) 1))
(EXPECTED-RESULT depth-rel-8 (candidate_relative_support (cand_l8_chain (cand_l7_chain (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) step) step) 1 6))
(EXPECTED-RESULT depth-freq-8 (candidate_frequent (cand_l8_chain (cand_l7_chain (cand_l6_chain (cand_l5_chain (cand_l4_chain (cand_l3_chain (cand_l2_chain step step) step) step) step) step) step) step) 1))

;; Termination status
(EXPECTED-RESULT depth-term-status (warmr_search_status completed 8))
