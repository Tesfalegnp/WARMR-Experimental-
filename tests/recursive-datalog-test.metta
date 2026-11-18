;; =============================================================================
;; tests/recursive-datalog-test.metta
;; =============================================================================
;; Milestone 7 Generalization Test: Recursive Datalog Background Knowledge
;;
;; Validates:
;;   1. Execution of intensional recursive Datalog rules in MORK:
;;        Base:      ancestor(X, Y) :- parent(X, Y).
;;        Recursive: ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
;;   2. Transitive closure computation up to 3 hops (abel -> hana -> sami -> noah).
;;   3. Deduplication of recursive derivation proofs in the AtomSpace.
;;   4. WARMR candidate evaluation over derived intensional predicates.
;;   5. Ground-truth distinct-key support (N = 7 individuals):
;;        ancestor(var 0, var 1):      4 / 7 (abel, hana, sami, bereket -> Frequent: 4 >= 3)
;;        ancestor(var 0, const noah): 3 / 7 (abel, hana, sami          -> Frequent: 3 >= 3)
;;        ancestor(var 0, unknown):    0 / 7 (0 < 3 -> Infrequent)
;;   6. Exact rational relative support (4/7, 3/7, 0/7).
;;   7. Anti-monotonic pruning of zero-support candidate.
;;   8. Structured output record emission.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta
;; TEST-AUX benchmarks/recursive-family.metta
;; TEST-AUX benchmarks/family-keys.metta
;; TEST-AUX config/family-bias.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging (MIN_SUPPORT = 3)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 3)
(INPUT MAX_LENGTH 2)
(INPUT DATASET_ID recursive_family)
(configured_limits (min_support 3) (max_length 2))

;; Initialize key domain counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 2. Evaluated Candidates over Derived Intensional Relation (ancestor/2)
;; -----------------------------------------------------------------------------
;; Q1: Who is an ancestor of someone? ancestor(var 0, var 1)
;; Matches: abel (4 descendants), hana (3 descendants), sami (1 descendant), bereket (1 descendant).
;; Total distinct keys = 4.
(candidate q_anc 1 ((ancestor (var 0) (var 1))) (((var 0) person) ((var 1) person)) root)
(candidate_pending_eval q_anc)

;; Q2: Who is an ancestor of Noah? ancestor(var 0, const noah)
;; Matches: abel, hana, sami.
;; Total distinct keys = 3.
(candidate q_noah 1 ((ancestor (var 0) (const noah))) (((var 0) person)) root)
(candidate_pending_eval q_noah)

;; Q3: Ancestor of non-existent entity
;; Matches: 0. Total distinct keys = 0.
(candidate q_unknown 1 ((ancestor (var 0) (const unknown_person))) (((var 0) person)) root)
(candidate_pending_eval q_unknown)

;; -----------------------------------------------------------------------------
;; 3. Expected Results (Verification Invariants)
;; -----------------------------------------------------------------------------
;; Intensional Transitive Deductions Verified
(EXPECTED-RESULT datalog-hop1 (ancestor abel hana))
(EXPECTED-RESULT datalog-hop2 (ancestor abel sami))
(EXPECTED-RESULT datalog-hop3 (ancestor abel noah))
(EXPECTED-RESULT datalog-hana-noah (ancestor hana noah))

;; Domain size
(EXPECTED-RESULT datalog-total-keys (total_positive_keys 7))

;; Support counts
(EXPECTED-RESULT datalog-supp-anc (candidate_support q_anc 4))
(EXPECTED-RESULT datalog-supp-noah (candidate_support q_noah 3))
(EXPECTED-RESULT datalog-supp-unknown (candidate_support q_unknown 0))

;; Relative support
(EXPECTED-RESULT datalog-rel-anc (candidate_relative_support q_anc 4 7))
(EXPECTED-RESULT datalog-rel-noah (candidate_relative_support q_noah 3 7))
(EXPECTED-RESULT datalog-rel-unknown (candidate_relative_support q_unknown 0 7))

;; Frequency classifications
(EXPECTED-RESULT datalog-freq-anc (candidate_frequent q_anc 4))
(EXPECTED-RESULT datalog-freq-noah (candidate_frequent q_noah 3))
(EXPECTED-RESULT datalog-infreq-unknown (candidate_infrequent q_unknown 0))

;; Anti-monotonic pruning
(EXPECTED-RESULT datalog-prune-unknown (prune_branch q_unknown))
(EXPECTED-RESULT datalog-confirm-unknown (pruning_confirmed q_unknown))

;; Structured output records
(EXPECTED-RESULT datalog-out-anc
  (warmr_pattern
    (id q_anc)
    (length 1)
    (body ((ancestor (var 0) (var 1))))
    (absolute_support 4)
    (relative_support 4 7)
    (classification frequent)
    (dataset recursive_family)
    (min_support 3)))

(EXPECTED-RESULT datalog-out-noah
  (warmr_pattern
    (id q_noah)
    (length 1)
    (body ((ancestor (var 0) (const noah))))
    (absolute_support 3)
    (relative_support 3 7)
    (classification frequent)
    (dataset recursive_family)
    (min_support 3)))
