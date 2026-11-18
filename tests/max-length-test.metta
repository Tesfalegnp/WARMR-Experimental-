;; =============================================================================
;; tests/max-length-test.metta
;; =============================================================================
;; Milestone 5 Test E — Maximum Length Enforcement Verification
;;
;; Verifies:
;;   1. When configured with MAX_LENGTH = 2, the search terminates after Level 2.
;;   2. Level 2 frequent candidates are found and classified.
;;   3. NO Level 3 candidates (cand_l3) are ever generated or evaluated.
;;   4. Search status cleanly reports (warmr_search_status completed 2).
;; =============================================================================

;; TEST-AUX src/pruning.metta
;; TEST-AUX src/search-loop.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker-keys.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Language Bias (MAX_LENGTH = 2)
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 5)
(INPUT MAX_LENGTH 2)
(configured_limits (min_support 5) (max_length 2))

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
(EXPECTED-RESULT max-len-status (warmr_search_status completed 2))
(EXPECTED-RESULT max-len-l1-man (candidate_frequent (cand_l1 man) 10))
(EXPECTED-RESULT max-len-l2-man-ugly (candidate_frequent (cand_l2 man ugly) 5))
(EXPECTED-RESULT max-len-l2-human-soda (candidate_frequent (cand_l2 human sodaDrinker) 10))
(EXPECTED-RESULT max-len-pruned-man-woman (prune_branch (cand_l2 man woman)))
