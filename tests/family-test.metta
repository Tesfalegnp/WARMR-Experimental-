;; =============================================================================
;; tests/family-test.metta
;; =============================================================================
;; Milestone 6 Family Relational Dataset & Multi-Proof Chaining Regression Test
;;
;; Validates:
;;   1. Seven positive-example individuals declared as key entities:
;;      abel, hana, sami, lidiya, bereket, sara, noah (total_positive_keys = 7).
;;   2. Five original background parent/2 relations from data.metta:
;;      (parent abel hana), (parent hana sami), (parent hana lidiya),
;;      (parent bereket sara), (parent sara noah).
;;   3. One-literal candidate parent(X, Y) matches keys: abel, hana, bereket, sara.
;;      Support = 4 (relative support = 4/7).
;;   4. Two-literal relational chain: parent(X, Y) ∧ parent(Y, Z) produces
;;      three complete substitution paths:
;;        - (abel hana sami)
;;        - (abel hana lidiya)
;;        - (bereket sara noah)
;;      Multi-proof deduplication: abel matches 2 paths but counts as 1 key witness.
;;      bereket matches 1 path and counts as 1 key witness.
;;      Exact distinct key support = 2 (relative support = 2/7).
;;   5. Structured output emission via output.metta.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta
;; TEST-AUX data.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 2)
(INPUT MAX_LENGTH 2)
(INPUT DATASET_ID family_benchmark)
(configured_limits (min_support 2) (max_length 2))

;; -----------------------------------------------------------------------------
;; 2. Positive Key Domain (7 Distinct Individuals)
;; -----------------------------------------------------------------------------
(positive_example abel)
(positive_example hana)
(positive_example sami)
(positive_example lidiya)
(positive_example bereket)
(positive_example sara)
(positive_example noah)

;; Initialize domain key counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 3. Candidate Queries
;; -----------------------------------------------------------------------------
;; Q_parent: Single-literal relation: parent(X, Y)
;; Key individuals who are parents: abel, hana, bereket, sara -> support = 4.
(candidate q_parent 1
  ((parent (var 0) (var 1)))
  (((var 0) person) ((var 1) person))
  root)
(candidate_pending_eval q_parent)

;; Q_grandparent: Two-literal chain: parent(X, Y) ∧ parent(Y, Z)
;; Matches 3 substitutions ((abel hana sami), (abel hana lidiya), (bereket sara noah)).
;; Distinct ancestor keys = 2 (abel, bereket).
(candidate q_grandparent 2
  ((parent (var 0) (var 1)) (parent (var 1) (var 2)))
  (((var 0) person) ((var 1) person) ((var 2) person))
  q_parent)
(candidate_pending_eval q_grandparent)

;; Q_zero: Zero-support candidate (parent(X, noah) where noah is never a parent)
(candidate q_zero 2
  ((parent (var 0) (const noah)) (parent (var 1) (var 2)))
  (((var 0) person) ((var 1) person) ((var 2) person))
  q_parent)
(candidate_pending_eval q_zero)

;; -----------------------------------------------------------------------------
;; 4. Expected Result Assertions
;; -----------------------------------------------------------------------------
;; Key domain counting (N = 7)
(EXPECTED-RESULT fam-total-keys (total_positive_keys 7))

;; Support counts
(EXPECTED-RESULT fam-parent-supp (candidate_support q_parent 4))
(EXPECTED-RESULT fam-grandparent-supp (candidate_support q_grandparent 2))
(EXPECTED-RESULT fam-zero-supp (candidate_support q_zero 0))

;; Rational relative support (counts against isolated denominator = 7)
(EXPECTED-RESULT fam-parent-rel (candidate_relative_support q_parent 4 7))
(EXPECTED-RESULT fam-grandparent-rel (candidate_relative_support q_grandparent 2 7))
(EXPECTED-RESULT fam-zero-rel (candidate_relative_support q_zero 0 7))

;; Classification & Pruning
(EXPECTED-RESULT fam-parent-freq (candidate_frequent q_parent 4))
(EXPECTED-RESULT fam-grandparent-freq (candidate_frequent q_grandparent 2))
(EXPECTED-RESULT fam-zero-prune (prune_branch q_zero))

;; Structured output records
(EXPECTED-RESULT fam-out-parent
  (warmr_pattern
    (id q_parent)
    (length 1)
    (body ((parent (var 0) (var 1))))
    (absolute_support 4)
    (relative_support 4 7)
    (classification frequent)
    (dataset family_benchmark)
    (min_support 2)))

(EXPECTED-RESULT fam-out-grandparent
  (warmr_pattern
    (id q_grandparent)
    (length 2)
    (body ((parent (var 0) (var 1)) (parent (var 1) (var 2))))
    (absolute_support 2)
    (relative_support 2 7)
    (classification frequent)
    (dataset family_benchmark)
    (min_support 2)))
