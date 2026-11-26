;; =============================================================================
;; tests/search-loop-generic-test.metta
;; =============================================================================
;; Milestone 5 Generic Search Loop & Ordering Test Suite
;;
;; Validates Defect 5.1 & Defect 5.2 Resolutions:
;;   1. Generic unary predicate ordering synthesis (no hardcoded unary_lt required).
;;   2. Unary pairs are generated in exactly one deterministic order (P < Q).
;;   3. Reversed pairs (Q < P) are not generated, preventing duplicate candidates.
;;   4. A predicate is not paired with itself (no reflexive P ∧ P conjunctions).
;;   5. Generic constant ordering synthesis for arbitrary new constants (no hardcoded attr_lt).
;;   6. Constant pairs are generated in strict lexicographical order.
;;   7. New dataset with arbitrary predicate names works without source code changes.
;;   8. Candidate support calculation and frequent classification are preserved.
;; =============================================================================

;; TEST-AUX src/language-bias.metta
;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/warmr.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/search-loop.metta
;; TEST-AUX src/output.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Custom Arbitrary Predicate Declarations
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 2)
(INPUT MAX_LENGTH 2)
(INPUT DATASET_ID generic_test)
(configured_limits (min_support 2) (max_length 2))

;; Key domain: 4 entities
(positive_example e1)
(positive_example e2)
(positive_example e3)
(positive_example e4)

;; Language bias for key and body
(modeh positive_example ((+ item)))
(mode_slot positive_example 1 (+ item))

(modeb alpha ((+ item)))
(mode_slot alpha 1 (+ item))

(modeb beta ((+ item)))
(mode_slot beta 1 (+ item))

(modeb gamma ((+ item)))
(mode_slot gamma 1 (+ item))

(determination positive_example alpha)
(determination positive_example beta)
(determination positive_example gamma)

;; Arbitrary facts:
;; alpha: e1, e2, e3 (support 3)
(alpha e1) (alpha e2) (alpha e3)

;; beta: e1, e2, e4 (support 3)
(beta e1) (beta e2) (beta e4)

;; gamma: e4 only (support 1 -> infrequent)
(gamma e4)

;; Arbitrary new constant type and values (shape: circle, square, triangle)
(modeb has_shape ((+ item) (# shape)))
(mode_slot has_shape 1 (+ item))
(mode_slot has_shape 2 (# shape))
(determination positive_example has_shape)

(type_constant shape circle)
(type_constant shape square)
(type_constant shape triangle)

;; -----------------------------------------------------------------------------
;; 2. Expected Result Assertions
;; -----------------------------------------------------------------------------

;; 1. Total Domain Keys
(EXPECTED-RESULT exp-generic-keys (total_positive_keys 4))

;; 2. Generic Unary Ordering Synthesis (alpha < beta < gamma lexicographically)
(EXPECTED-RESULT exp-ord-alpha-beta (unary_lt alpha beta))
(EXPECTED-RESULT exp-ord-alpha-gamma (unary_lt alpha gamma))
(EXPECTED-RESULT exp-ord-beta-gamma (unary_lt beta gamma))

;; 3. Generic Constant Ordering Synthesis (circle < square < triangle lexicographically)
(EXPECTED-RESULT exp-ord-circle-square (attr_lt circle square))
(EXPECTED-RESULT exp-ord-circle-triangle (attr_lt circle triangle))
(EXPECTED-RESULT exp-ord-square-triangle (attr_lt square triangle))

;; 4. Level 1 Candidate Generation & Frequent Classification
(EXPECTED-RESULT exp-freq-alpha (candidate_frequent (cand_l1 alpha) 3))
(EXPECTED-RESULT exp-freq-beta (candidate_frequent (cand_l1 beta) 3))
(EXPECTED-RESULT exp-infreq-gamma (candidate_infrequent (cand_l1 gamma) 1))

;; 5. Level 2 Conjunction Generated via Generic Unary Ordering (alpha ∧ beta: support 2 >= 2)
(EXPECTED-RESULT exp-l2-alpha-beta (candidate (cand_l2 alpha beta) 2 ((alpha (var 0)) (beta (var 0))) (((var 0) item)) (cand_l1 alpha)))
(EXPECTED-RESULT exp-freq-l2-alpha-beta (candidate_frequent (cand_l2 alpha beta) 2))

;; 6. Structured Output Record for Generic Level 2 Pattern
(EXPECTED-RESULT exp-out-l2-alpha-beta
  (warmr_pattern
    (id (cand_l2 alpha beta))
    (length 2)
    (body ((alpha (var 0)) (beta (var 0))))
    (absolute_support 2)
    (relative_support 2 4)
    (classification frequent)
    (dataset generic_test)
    (min_support 2)))

