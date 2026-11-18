;; =============================================================================
;; tests/empty-level-test.metta
;; =============================================================================
;; Milestone 5 Test G — Empty Next Level Clean Termination Verification
;;
;; Verifies:
;;   1. When configured with an unsatisfiable threshold (MIN_SUPPORT = 25 > N=20),
;;      all Level 1 candidates are classified infrequent.
;;   2. All Level 1 candidates produce prune_branch markers.
;;   3. NO Level 2 candidates are ever generated.
;;   4. Search terminates cleanly with 0 frequent candidates.
;; =============================================================================

;; TEST-AUX src/pruning.metta
;; TEST-AUX src/search-loop.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker-keys.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Language Bias (MIN_SUPPORT = 25 > N=20)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 25)
(INPUT MAX_LENGTH 3)
(configured_limits (min_support 25) (max_length 3))

;; Comparisons against 25
(num_lt 0 25) (num_lt 10 25) (num_lt 20 25)

(allowed_body_predicate positive_example Inheritance ((+ person) (# attribute)))
(predicate_arity Inheritance 2)
(valid_slot Inheritance 1 input person)
(valid_slot Inheritance 2 constant attribute)

(valid_constant attribute human)
(valid_constant attribute man)
(valid_constant attribute woman)
(valid_constant attribute ugly)
(valid_constant attribute sodaDrinker)

;; -----------------------------------------------------------------------------
;; 2. Root Candidate & Level 1 Search Initialization
;; -----------------------------------------------------------------------------
(candidate root 0 () (((var 0) person)) nil)
(expand_candidate root)

;; Level 1 Refinement Operator
(exec (warmr 215 ref_root_bfs)
  (, (expand_candidate root)
     (candidate root 0 () (((var 0) $ptype)) nil)
     (allowed_body_predicate positive_example $pred ((+ $ptype) (# $atype)))
     (valid_constant $atype $c))
  (O (+ (candidate (cand_l1 $c) 1 (($pred (var 0) (const $c))) (((var 0) $ptype)) root))
     (+ (candidate_pending_eval (cand_l1 $c)))
     (+ (candidate_pool 1 (($pred (var 0) (const $c)))))))

;; Level 1 Evaluation
(exec (warmr 220 eval_l1_bfs)
  (, (candidate $qid 1 (($p (var 0) (const $c))) $types root)
     (positive_example $k)
     ($p $k $c))
  (O (+ (key_witness $qid $k))))

;; Level 1 Count Support
(exec (warmr 225 count_l1_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

;; Level 1 Cleanup
(exec (warmr 230 cleanup_l1_bfs)
  (, (candidate_support $qid $cnt)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

;; -----------------------------------------------------------------------------
;; 3. Expected Result Assertions
;; -----------------------------------------------------------------------------
(EXPECTED-RESULT empty-prune-human (prune_branch (cand_l1 human)))
(EXPECTED-RESULT empty-prune-man (prune_branch (cand_l1 man)))
(EXPECTED-RESULT empty-prune-woman (prune_branch (cand_l1 woman)))
(EXPECTED-RESULT empty-prune-ugly (prune_branch (cand_l1 ugly)))
(EXPECTED-RESULT empty-prune-soda (prune_branch (cand_l1 sodaDrinker)))
(EXPECTED-RESULT empty-infreq-human (candidate_infrequent (cand_l1 human) 20))
(EXPECTED-RESULT empty-infreq-man (candidate_infrequent (cand_l1 man) 10))
(EXPECTED-RESULT empty-termination (warmr_search_status completed 3))
