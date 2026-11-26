;; =============================================================================
;; tests/anti-monotonicity-test.metta
;; =============================================================================
;; Milestone 8 Mathematical Invariant Verification:
;;
;; Invariants Verified:
;;   1. Support Anti-Monotonicity:
;;        For every candidate Q' specializing Q (parent-child relationship):
;;        supp(Q') <= supp(Q)
;;   2. Classification Isolation (No Conflicting Dual-Classification):
;;        Frequent(Q) ∩ Infrequent(Q) = ∅
;;        No candidate is ever classified as BOTH frequent and infrequent.
;;   3. Duplicate Proof Collapsing:
;;        Multiple paths/substitutions for the same key entity collapse to
;;        exactly 1 key witness (Milestone 1 distinct-key projection).
;;   4. Synthetic Anti-Monotonicity Violation Detector:
;;        Tests that if an artificial candidate were to have supp(child) > supp(parent),
;;        the mathematical violation check flags it as an invariant breach.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging (MIN_SUPPORT = 5)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 5)
(INPUT MAX_LENGTH 3)
(INPUT DATASET_ID anti_monotonicity_audit)
(configured_limits (min_support 5) (max_length 3))

;; -----------------------------------------------------------------------------
;; 2. Relational Candidates Representing Search Tree Branches (MM2 Benchmark)
;; -----------------------------------------------------------------------------
;; Q_root: Length 0 (Key Domain = 20)
(total_positive_keys 20)

;; Branch A: Frequent Parent -> Frequent Child
;; L1: human (supp = 20 >= 5 -> Frequent)
(candidate (cand_l1 human) 1 ((Inheritance (var 0) (const human))) (((var 0) person)) root)
(candidate_support (cand_l1 human) 20)

;; L2: human ∧ man (supp = 10, 10 <= 20 -> Invariant Holds, Frequent: 10 >= 5)
(candidate (cand_l2 human man) 2 ((Inheritance (var 0) (const human)) (Inheritance (var 0) (const man))) (((var 0) person)) (cand_l1 human))
(candidate_support (cand_l2 human man) 10)

;; L3: human ∧ man ∧ ugly (supp = 5, 5 <= 10 -> Invariant Holds, Boundary Frequent: 5 == 5)
(candidate (cand_l3 human man ugly) 3 ((Inheritance (var 0) (const human)) (Inheritance (var 0) (const man)) (Inheritance (var 0) (const ugly))) (((var 0) person)) (cand_l2 human man))
(candidate_support (cand_l3 human man ugly) 5)

;; Branch B: Frequent Parent -> Infrequent Child (Safe Pruning)
;; L1: man (supp = 10 >= 5 -> Frequent)
(candidate (cand_l1 man) 1 ((Inheritance (var 0) (const man))) (((var 0) person)) root)
(candidate_support (cand_l1 man) 10)

;; L2: man ∧ woman (supp = 0, 0 <= 10 -> Invariant Holds, Infrequent: 0 < 5 -> Pruned)
(candidate (cand_l2 man woman) 2 ((Inheritance (var 0) (const man)) (Inheritance (var 0) (const woman))) (((var 0) person)) (cand_l1 man))
(candidate_support (cand_l2 man woman) 0)

;; Branch C: Multi-Proof Collapsing (Key n0 has 2 distinct proofs -> supp = 1)
(candidate q_multi_proof 2 ((step (var 0) (var 1)) (step (var 1) (var 2))) (((var 0) node)) root)
(key_witness q_multi_proof n0)
(key_witness q_multi_proof n0) ;; Duplicate witness atom
(candidate_pending_eval q_multi_proof)

;; Branch D: Synthetic Hypothetical Candidate to Test Violation Detector
(candidate c_parent_hypo 1 ((p (var 0))) () root)
(candidate_support c_parent_hypo 4)

(candidate c_child_violation 2 ((p (var 0)) (q (var 0))) () c_parent_hypo)
(candidate_support c_child_violation 7) ;; Hypothetical violation: 7 > 4

;; -----------------------------------------------------------------------------
;; 3. Mathematical Invariant Verification Rules
;; -----------------------------------------------------------------------------

;; Check 1: Anti-monotonicity validation rule
;; If child support <= parent support, assert (anti_monotonicity_valid <child> <parent>)
(exec (warmr 360 check_anti_monotonicity_valid)
  (, (candidate $child $len $body $types $parent)
     (candidate_support $child $cnt_c)
     (candidate_support $parent $cnt_p))
  (O (pure (anti_mono_status $child $parent $is_valid) $is_valid
       (i8_to_string (gte_i64 (i64_from_string $cnt_p) (i64_from_string $cnt_c))))))

(exec (warmr 361 confirm_anti_monotonicity)
  (, (anti_mono_status $child $parent 1))
  (O (+ (anti_monotonicity_valid $child $parent))
     (- (anti_mono_status $child $parent 1))))

(exec (warmr 361 catch_anti_monotonicity_violation)
  (, (anti_mono_status $child $parent 0))
  (O (+ (anti_monotonicity_violation $child $parent))
     (- (anti_mono_status $child $parent 0))))

;; Check 2: Classification Conflict Detection: Frequent(Q) ∩ Infrequent(Q) = ∅
(exec (warmr 362 catch_classification_conflict)
  (, (candidate_frequent $cid $cnt1)
     (candidate_infrequent $cid $cnt2))
  (O (+ (classification_conflict_detected $cid))))

;; -----------------------------------------------------------------------------
;; 4. Expected Results & Verification Assertions
;; -----------------------------------------------------------------------------

;; 1. Branch A Invariants: supp(human ∧ man) <= supp(human) (10 <= 20)
(EXPECTED-RESULT inv-human-man (anti_monotonicity_valid (cand_l2 human man) (cand_l1 human)))

;; 2. Branch A Invariants: supp(human ∧ man ∧ ugly) <= supp(human ∧ man) (5 <= 10)
(EXPECTED-RESULT inv-human-man-ugly (anti_monotonicity_valid (cand_l3 human man ugly) (cand_l2 human man)))

;; 3. Branch B Invariants: supp(man ∧ woman) <= supp(man) (0 <= 10)
(EXPECTED-RESULT inv-man-woman (anti_monotonicity_valid (cand_l2 man woman) (cand_l1 man)))

;; 4. Violation Detector: flags hypothetical child where supp(child) > supp(parent) (7 > 4)
(EXPECTED-RESULT inv-violation-flagged (anti_monotonicity_violation c_child_violation c_parent_hypo))

;; 5. Classification Statuses (Strict Partitioning)
(EXPECTED-RESULT freq-human (candidate_frequent (cand_l1 human) 20))
(EXPECTED-RESULT freq-human-man (candidate_frequent (cand_l2 human man) 10))
(EXPECTED-RESULT freq-human-man-ugly (candidate_frequent (cand_l3 human man ugly) 5))
(EXPECTED-RESULT infreq-man-woman (candidate_infrequent (cand_l2 man woman) 0))

;; 6. Anti-Monotonic Pruning
(EXPECTED-RESULT prune-man-woman (prune_branch (cand_l2 man woman)))
(EXPECTED-RESULT confirm-prune-man-woman (pruning_confirmed (cand_l2 man woman)))

;; 7. Multi-Proof Collapsing
(EXPECTED-RESULT multi-proof-collapsed (candidate_support q_multi_proof 1))
(EXPECTED-RESULT multi-proof-infreq (candidate_infrequent q_multi_proof 1))
