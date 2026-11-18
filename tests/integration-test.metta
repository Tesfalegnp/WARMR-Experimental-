;; =============================================================================
;; tests/integration-test.metta
;; =============================================================================
;; Milestone 6 Shared MM2 Benchmark End-to-End Integration Test
;;
;; Validates the entire integrated WARMR pipeline on ugly-sodaDrinker (N=20):
;;   1. Dataset provenance and key domain isolation (20 positive keys).
;;   2. All 5 Level 1 frequent patterns (human, man, woman, ugly, sodaDrinker).
;;   3. Correct Level 2 pair support (human ∧ man: 10, man ∧ ugly: 5, etc.).
;;   4. Correct anti-monotonic pruning of zero-support pair (man ∧ woman: support 0).
;;   5. Correct Level 3 triplet support (human ∧ man ∧ ugly: 5, etc.).
;;   6. No descendants generated from pruned branches (zero man ∧ woman ∧ * triplets).
;;   7. Maximum-length enforcement and clean termination status (completed 3).
;;   8. Publication of structured output records via output.metta.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/warmr.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/search-loop.metta
;; TEST-AUX src/output.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker-keys.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 5)
(INPUT MAX_LENGTH 3)
(INPUT DATASET_ID ugly_sodaDrinker)
(configured_limits (min_support 5) (max_length 3))

;; Initialize domain key counting
(key_domain_pending_count)

;; Bias & Mode Declarations
(allowed_body_predicate positive_example Inheritance ((+ person) (# attribute)))
(predicate_arity Inheritance 2)
(valid_slot Inheritance 1 input person)
(valid_slot Inheritance 2 constant attribute)

(valid_constant attribute human)
(valid_constant attribute man)
(valid_constant attribute woman)
(valid_constant attribute ugly)
(valid_constant attribute sodaDrinker)

;; Root Candidate & Search Initialization
(candidate root 0 () (((var 0) person)) nil)
(expand_candidate root)

;; -----------------------------------------------------------------------------
;; 2. Expected Results & Assertions
;; -----------------------------------------------------------------------------

;; A. Key Domain Counting (N = 20)
(EXPECTED-RESULT int-total-keys (total_positive_keys 20))

;; B. Level 1 Frequent Patterns (All 5 Singletons)
(EXPECTED-RESULT int-l1-human (candidate_frequent (cand_l1 human) 20))
(EXPECTED-RESULT int-l1-man (candidate_frequent (cand_l1 man) 10))
(EXPECTED-RESULT int-l1-woman (candidate_frequent (cand_l1 woman) 10))
(EXPECTED-RESULT int-l1-ugly (candidate_frequent (cand_l1 ugly) 10))
(EXPECTED-RESULT int-l1-soda (candidate_frequent (cand_l1 sodaDrinker) 10))

;; C. Level 2 Conjunctions & Pair Support
(EXPECTED-RESULT int-l2-human-man (candidate_frequent (cand_l2 human man) 10))
(EXPECTED-RESULT int-l2-human-woman (candidate_frequent (cand_l2 human woman) 10))
(EXPECTED-RESULT int-l2-human-ugly (candidate_frequent (cand_l2 human ugly) 10))
(EXPECTED-RESULT int-l2-human-soda (candidate_frequent (cand_l2 human sodaDrinker) 10))
(EXPECTED-RESULT int-l2-man-ugly (candidate_frequent (cand_l2 man ugly) 5))
(EXPECTED-RESULT int-l2-man-soda (candidate_frequent (cand_l2 man sodaDrinker) 5))
(EXPECTED-RESULT int-l2-woman-ugly (candidate_frequent (cand_l2 woman ugly) 5))
(EXPECTED-RESULT int-l2-woman-soda (candidate_frequent (cand_l2 woman sodaDrinker) 5))
(EXPECTED-RESULT int-l2-ugly-soda (candidate_frequent (cand_l2 ugly sodaDrinker) 5))

;; D. Level 2 Anti-Monotonic Pruning
(EXPECTED-RESULT int-l2-man-woman-infreq (candidate_infrequent (cand_l2 man woman) 0))
(EXPECTED-RESULT int-l2-man-woman-prune (prune_branch (cand_l2 man woman)))
(EXPECTED-RESULT int-l2-man-woman-confirm (pruning_confirmed (cand_l2 man woman)))

;; E. Level 3 Triplet Conjunctions
(EXPECTED-RESULT int-l3-human-man-ugly (candidate_frequent (cand_l3 human man ugly) 5))
(EXPECTED-RESULT int-l3-human-man-soda (candidate_frequent (cand_l3 human man sodaDrinker) 5))
(EXPECTED-RESULT int-l3-human-woman-ugly (candidate_frequent (cand_l3 human woman ugly) 5))
(EXPECTED-RESULT int-l3-human-woman-soda (candidate_frequent (cand_l3 human woman sodaDrinker) 5))
(EXPECTED-RESULT int-l3-human-ugly-soda (candidate_frequent (cand_l3 human ugly sodaDrinker) 5))
(EXPECTED-RESULT int-l3-man-ugly-soda (candidate_frequent (cand_l3 man ugly sodaDrinker) 5))

;; F. Termination Status
(EXPECTED-RESULT int-termination (warmr_search_status completed 3))

;; G. Structured Output Records (output.metta)
(EXPECTED-RESULT int-out-l1-human
  (warmr_pattern
    (id (cand_l1 human))
    (length 1)
    (body ((Inheritance (var 0) (const human))))
    (absolute_support 20)
    (relative_support 20 20)
    (classification frequent)
    (dataset ugly_sodaDrinker)
    (min_support 5)))

(EXPECTED-RESULT int-out-l2-man-ugly
  (warmr_pattern
    (id (cand_l2 man ugly))
    (length 2)
    (body ((Inheritance (var 0) (const man)) (Inheritance (var 0) (const ugly))))
    (absolute_support 5)
    (relative_support 5 20)
    (classification frequent)
    (dataset ugly_sodaDrinker)
    (min_support 5)))

(EXPECTED-RESULT int-out-l3-man-ugly-soda
  (warmr_pattern
    (id (cand_l3 man ugly sodaDrinker))
    (length 3)
    (body ((Inheritance (var 0) (const man)) (Inheritance (var 0) (const ugly)) (Inheritance (var 0) (const sodaDrinker))))
    (absolute_support 5)
    (relative_support 5 20)
    (classification frequent)
    (dataset ugly_sodaDrinker)
    (min_support 5)))
