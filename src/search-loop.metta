;; =============================================================================
;; src/search-loop.metta
;; =============================================================================
;; Purpose:
;;   Breadth-First Search (BFS) Loop and Level-Wise Orchestration for the WARMR
;;   relational pattern miner in MeTTa/MM2 on MORK.
;;
;; Search Flow:
;;   Level 0: Initialize root candidate (empty body, 100% support).
;;   Level 1: Refine root -> Canonicalize -> Evaluate Support -> Classify.
;;   Level 2: Specialization of frequent Level 1 candidates -> Canonicalize
;;            -> Evaluate Support -> Classify & Prune.
;;   Level 3: Specialization of frequent Level 2 candidates -> Canonicalize
;;            -> Evaluate Support -> Classify & Prune.
;;   Termination: Stops cleanly when MAX_LENGTH is reached or next level is empty.
;;
;; Anti-Monotonic Pruning Invariant:
;;   Only candidates marked with (candidate_frequent <cid> <support>) are ever
;;   eligible for expansion. Candidates marked with (prune_branch <cid>) or
;;   (candidate_infrequent <cid> <support>) NEVER receive expansion tokens.
;;
;; Priority Convention:
;;   (warmr 365..399): Level 1 Expansion & Level 2 Candidate Generation
;;   (warmr 400..449): Level 2 Evaluation, Support Counting, and Classification
;;   (warmr 465..499): Level 2 Expansion & Level 3 Candidate Generation
;;   (warmr 500..549): Level 3 Evaluation, Support Counting, and Classification
;;   (warmr 580..599): Search Status and Termination Detection
;; =============================================================================

;; -----------------------------------------------------------------------------
;; Canonical Ordering Compilation & Fallback
;; -----------------------------------------------------------------------------
;; Default benchmark ordering facts (fallback for legacy tests that load search-loop without custom bias)
(default_attr_lt human man)
(default_attr_lt human woman)
(default_attr_lt human ugly)
(default_attr_lt human sodaDrinker)
(default_attr_lt man woman)
(default_attr_lt man ugly)
(default_attr_lt man sodaDrinker)
(default_attr_lt woman ugly)
(default_attr_lt woman sodaDrinker)
(default_attr_lt ugly sodaDrinker)

(default_unary_lt active verified)
(default_unary_lt verified premium)
(default_unary_lt active premium)

(exec (warmr 144 adopt_default_attr_lt)
  (, (default_attr_lt $c1 $c2))
  (O (+ (attr_lt $c1 $c2))
     (+ (has_custom_attr_order attribute))))

(exec (warmr 144 adopt_default_unary_lt)
  (, (default_unary_lt $p1 $p2))
  (O (+ (unary_lt $p1 $p2))
     (+ (has_custom_unary_order positive_example user))))

;; Generic constant ordering synthesis for arbitrary new constants
(exec (warmr 145 gen_generic_const_pair)
  (, (valid_constant $type $c1)
     (valid_constant $type $c2))
  (O (pure (sorted_const_pair $type $c1 $c2 $sorted) $sorted (sort-atom (' ($c1 $c2))))))

(exec (warmr 146 select_generic_lt_const)
  (, (sorted_const_pair $type $c1 $c2 ($c1 $c2)))
  (O (+ (cand_attr_lt $type $c1 $c2))))

(exec (warmr 147 filter_custom_attr_lt)
  (, (cand_attr_lt $type $c1 $c2)
     (has_custom_attr_order $type))
  (O (- (cand_attr_lt $type $c1 $c2))))

(exec (warmr 148 promote_generic_attr_lt)
  (, (cand_attr_lt $type $c1 $c2))
  (O (+ (attr_lt $c1 $c2))
     (- (cand_attr_lt $type $c1 $c2))))

(exec (warmr 149 drop_reflexive_attr_lt)
  (, (attr_lt $c $c))
  (O (- (attr_lt $c $c))))

;; Generic unary predicate ordering synthesis for arbitrary new unary predicates
(exec (warmr 145 gen_generic_unary_pair)
  (, (allowed_body_predicate $head $p1 ((+ $type)))
     (allowed_body_predicate $head $p2 ((+ $type))))
  (O (pure (sorted_unary_pair $head $type $p1 $p2 $sorted) $sorted (sort-atom (' ($p1 $p2))))))

(exec (warmr 146 select_generic_lt_unary)
  (, (sorted_unary_pair $head $type $p1 $p2 ($p1 $p2)))
  (O (+ (cand_unary_lt $head $type $p1 $p2))))

(exec (warmr 147 filter_custom_unary_lt)
  (, (cand_unary_lt $head $type $p1 $p2)
     (has_custom_unary_order $head $type))
  (O (- (cand_unary_lt $head $type $p1 $p2))))

(exec (warmr 148 promote_generic_unary_lt)
  (, (cand_unary_lt $head $type $p1 $p2))
  (O (+ (unary_lt $p1 $p2))
     (- (cand_unary_lt $head $type $p1 $p2))))

(exec (warmr 149 drop_reflexive_unary_lt)
  (, (unary_lt $p $p))
  (O (- (unary_lt $p $p))))

;; -----------------------------------------------------------------------------
;; STAGE 365: Level 1 Expansion Gate
;; -----------------------------------------------------------------------------
;; If candidate is frequent and length 1 < MAX_LENGTH, emit expansion token.
;; Case 1: Constant slot candidate
(exec (warmr 365 expand_frequent_l1)
  (, (candidate_frequent (cand_l1 $c1) $cnt)
     (candidate (cand_l1 $c1) 1 (($p1 (var 0) (const $c1))) (((var 0) $ptype)) root)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 1 $max_l))
  (O (+ (expand_candidate_l1 (cand_l1 $c1)))))

;; Case 2: Relational variable candidate (e.g. parent or regulates)
(exec (warmr 366 expand_frequent_l1_chain)
  (, (candidate_frequent (cand_l1 $p1 var1) $cnt)
     (candidate (cand_l1 $p1 var1) 1 (($p1 (var 0) (var 1))) (((var 0) $ktype) ((var 1) $t1)) root)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 1 $max_l))
  (O (+ (expand_candidate_l1 (cand_l1 $p1 var1)))))

;; Case 3: Unary relational candidate (e.g. active)
(exec (warmr 367 expand_frequent_l1_unary)
  (, (candidate_frequent (cand_l1 $p1) $cnt)
     (candidate (cand_l1 $p1) 1 (($p1 (var 0))) (((var 0) $ktype)) root)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 1 $max_l))
  (O (+ (expand_candidate_l1 (cand_l1 $p1)))))

;; Case 4: Ternary relational candidate (e.g. transfer)
(exec (warmr 368 expand_frequent_l1_ternary)
  (, (candidate_frequent (cand_l1 $p1 $c1) $cnt)
     (candidate (cand_l1 $p1 $c1) 1 (($p1 (var 0) (var 1) (const $c1))) (((var 0) $ktype) ((var 1) $t1)) root)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 1 $max_l))
  (O (+ (expand_candidate_l1 (cand_l1 $p1 $c1)))))

;; Case 5: 4-Ary relational candidate (e.g. audit_log)
(exec (warmr 369 expand_frequent_l1_4ary)
  (, (candidate_frequent (cand_l1 $p1 $c1 $c2 $c3) $cnt)
     (candidate (cand_l1 $p1 $c1 $c2 $c3) 1 (($p1 (var 0) (const $c1) (const $c2) (const $c3))) (((var 0) $ktype)) root)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 1 $max_l))
  (O (+ (expand_candidate_l1 (cand_l1 $p1 $c1 $c2 $c3)))))

;; -----------------------------------------------------------------------------
;; STAGE 370: Level 2 Refinement from Frequent Level 1 Candidates
;; -----------------------------------------------------------------------------
;; Case 1: Branched on key with ordered constants (MM2 benchmark)
(exec (warmr 370 ref_l1_to_l2_ordered)
  (, (expand_candidate_l1 (cand_l1 $c1))
     (candidate (cand_l1 $c1) 1 (($p1 (var 0) (const $c1))) (((var 0) $ptype)) root)
     (attr_lt $c1 $c2)
     (allowed_body_predicate positive_example $p2 ((+ $ptype) (# attribute)))
     (valid_constant attribute $c2))
  (O (+ (candidate (cand_l2 $c1 $c2) 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2))) (((var 0) $ptype)) (cand_l1 $c1)))
     (+ (candidate_pending_eval (cand_l2 $c1 $c2)))
     (+ (candidate_pool 2 ((Inheritance (var 0) (const $c1)) (Inheritance (var 0) (const $c2)))))))

;; Case 2: Chained on output variable (family parent chain or synthetic regulates)
(exec (warmr 372 ref_l1_to_l2_chain)
  (, (expand_candidate_l1 (cand_l1 $p1 var1))
     (candidate (cand_l1 $p1 var1) 1 (($p1 (var 0) (var 1))) (((var 0) $ktype) ((var 1) $t1)) root)
     (allowed_body_predicate positive_example $p2 ((+ $t1) (- $otype2))))
  (O (+ (candidate (cand_l2_chain $p1 $p2) 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $otype2)) (cand_l1 $p1 var1)))
     (+ (candidate_pending_eval (cand_l2_chain $p1 $p2)))
     (+ (candidate_pool 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)))))))

;; Case 3: Branched on key for unary predicates
(exec (warmr 374 ref_l1_to_l2_unary)
  (, (expand_candidate_l1 (cand_l1 $p1))
     (candidate (cand_l1 $p1) 1 (($p1 (var 0))) (((var 0) $ktype)) root)
     (allowed_body_predicate positive_example $p2 ((+ $ktype)))
     (unary_lt $p1 $p2))
  (O (+ (candidate (cand_l2 $p1 $p2) 2 (($p1 (var 0)) ($p2 (var 0))) (((var 0) $ktype)) (cand_l1 $p1)))
     (+ (candidate_pending_eval (cand_l2 $p1 $p2)))
     (+ (candidate_pool 2 (($p1 (var 0)) ($p2 (var 0)))))))

;; Case 4: Chained on output variable for ternary predicates (e.g. transfer chain)
(exec (warmr 376 ref_l1_to_l2_ternary_chain)
  (, (expand_candidate_l1 (cand_l1 $p1 $c1))
     (candidate (cand_l1 $p1 $c1) 1 (($p1 (var 0) (var 1) (const $c1))) (((var 0) $ktype) ((var 1) $t1)) root)
     (allowed_body_predicate positive_example $p2 ((+ $t1) (- $otype2) (# $ctype2)))
     (valid_constant $ctype2 $c2))
  (O (+ (candidate (cand_l2 (cand_l1 $p1 $c1) $p2 $c2) 2 (($p1 (var 0) (var 1) (const $c1)) ($p2 (var 1) (var 2) (const $c2))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $otype2)) (cand_l1 $p1 $c1)))
     (+ (candidate_pending_eval (cand_l2 (cand_l1 $p1 $c1) $p2 $c2)))
     (+ (candidate_pool 2 (($p1 (var 0) (var 1) (const $c1)) ($p2 (var 1) (var 2) (const $c2)))))))

;; Case 5: Branched on key for 4-ary predicates
(exec (warmr 378 ref_l1_to_l2_4ary_branch)
  (, (expand_candidate_l1 (cand_l1 $p1 $c1 $c2 $c3))
     (candidate (cand_l1 $p1 $c1 $c2 $c3) 1 (($p1 (var 0) (const $c1) (const $c2) (const $c3))) (((var 0) $ktype)) root)
     (allowed_body_predicate positive_example $p2 ((+ $ktype) (# $t1) (# $t2) (# $t3)))
     (valid_constant $t1 $a1)
     (valid_constant $t2 $a2)
     (valid_constant $t3 $a3))
  (O (+ (candidate (cand_l2 (cand_l1 $p1 $c1 $c2 $c3) $p2 $a1 $a2 $a3) 2 (($p1 (var 0) (const $c1) (const $c2) (const $c3)) ($p2 (var 0) (const $a1) (const $a2) (const $a3))) (((var 0) $ktype)) (cand_l1 $p1 $c1 $c2 $c3)))
     (+ (candidate_pending_eval (cand_l2 (cand_l1 $p1 $c1 $c2 $c3) $p2 $a1 $a2 $a3)))
     (+ (candidate_pool 2 (($p1 (var 0) (const $c1) (const $c2) (const $c3)) ($p2 (var 0) (const $a1) (const $a2) (const $a3)))))))

;; -----------------------------------------------------------------------------
;; STAGE 405: Anti-Redundancy & Tautology Elimination
;; -----------------------------------------------------------------------------
;; Rejects candidates with duplicate identical body literals (Q ∧ L ∧ L == Q ∧ L).
(exec (warmr 405 prune_tautological_l2)
  (, (candidate $cid 2 ($lit $lit) $types $parent)
     (candidate_pending_eval $cid))
  (O (+ (prune_branch $cid))
     (+ (candidate_infrequent $cid 0))
     (- (candidate_pending_eval $cid))))

;; -----------------------------------------------------------------------------
;; STAGE 410–440: Level 2 Evaluation and Support Counting
;; -----------------------------------------------------------------------------
;; Case 1: Branched on key (constant literals)
(exec (warmr 410 eval_l2_bfs)
  (, (candidate $qid 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2))) $types $pid)
     (positive_example $k)
     ($p1 $k $c1)
     ($p2 $k $c2))
  (O (+ (key_witness $qid $k))))

;; Case 2: Chained on output variable (parent chain / regulates chain)
(exec (warmr 412 eval_l2_chain_bfs)
  (, (candidate $qid 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1)
     ($p2 $v1 $v2))
  (O (+ (key_witness $qid $k))))

;; Case 3: Branched on key for unary predicates
(exec (warmr 413 eval_l2_unary_bfs)
  (, (candidate $qid 2 (($p1 (var 0)) ($p2 (var 0))) $types $pid)
     (positive_example $k)
     ($p1 $k)
     ($p2 $k))
  (O (+ (key_witness $qid $k))))

;; Case 4: Chained on output variable for ternary predicates
(exec (warmr 414 eval_l2_ternary_chain_bfs)
  (, (candidate $qid 2 (($p1 (var 0) (var 1) (const $c1)) ($p2 (var 1) (var 2) (const $c2))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1 $c1)
     ($p2 $v1 $v2 $c2))
  (O (+ (key_witness $qid $k))))

;; Case 5: Branched on key for 4-ary predicates
(exec (warmr 415 eval_l2_4ary_branch_bfs)
  (, (candidate $qid 2 (($p1 (var 0) (const $c1) (const $c2) (const $c3)) ($p2 (var 0) (const $a1) (const $a2) (const $a3))) $types $pid)
     (positive_example $k)
     ($p1 $k $c1 $c2 $c3)
     ($p2 $k $a1 $a2 $a3))
  (O (+ (key_witness $qid $k))))

(exec (warmr 420 count_l2_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 425 zero_fallback_l2_bfs)
  (, (candidate_pending_eval $qid))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 430 cleanup_l2_bfs)
  (, (candidate_support $qid $cnt)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

;; -----------------------------------------------------------------------------
;; STAGE 440–445: Level 2 Classification & Anti-Monotonic Pruning (64-bit)
;; -----------------------------------------------------------------------------
(exec (warmr 440 compute_l2_freq_status)
  (, (candidate $cid 2 $body $types $pid)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l2 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 441 classify_l2_freq)
  (, (frequent_status_l2 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l2 $cid 1))))

(exec (warmr 442 classify_l2_infreq)
  (, (frequent_status_l2 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l2 $cid 0))))

;; -----------------------------------------------------------------------------
;; STAGE 465: Level 2 Expansion Gate
;; -----------------------------------------------------------------------------
;; Only frequent Level 2 candidates whose length (2) is less than MAX_LENGTH
;; receive an expansion token. Infrequent candidates are strictly PRUNED.
(exec (warmr 465 expand_frequent_l2)
  (, (candidate_frequent (cand_l2 $c1 $c2) $cnt)
     (candidate (cand_l2 $c1 $c2) 2 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 2 $max_l))
  (O (+ (expand_candidate_l2 (cand_l2 $c1 $c2)))))

;; -----------------------------------------------------------------------------
;; STAGE 470: Level 3 Refinement from Frequent Level 2 Candidates
;; -----------------------------------------------------------------------------
;; Adds a third literal to frequent Level 2 candidates in canonical order.
(exec (warmr 470 ref_l2_to_l3_ordered)
  (, (expand_candidate_l2 (cand_l2 $c1 $c2))
     (candidate (cand_l2 $c1 $c2) 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2))) (((var 0) $ptype)) $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 2 $max_l)
     (attr_lt $c2 $c3)
     (allowed_body_predicate positive_example $p3 ((+ $ptype) (# attribute)))
     (valid_constant attribute $c3))
  (O (+ (candidate (cand_l3 $c1 $c2 $c3) 3 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3))) (((var 0) $ptype)) (cand_l2 $c1 $c2)))
     (+ (candidate_pending_eval (cand_l3 $c1 $c2 $c3)))
     (+ (candidate_pool 3 ((Inheritance (var 0) (const $c1)) (Inheritance (var 0) (const $c2)) (Inheritance (var 0) (const $c3)))))))

;; -----------------------------------------------------------------------------
;; STAGE 510–540: Level 3 Evaluation and Support Counting
;; -----------------------------------------------------------------------------
(exec (warmr 510 eval_l3_bfs)
  (, (candidate $qid 3 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3))) $types $pid)
     (positive_example $k)
     ($p1 $k $c1)
     ($p2 $k $c2)
     ($p3 $k $c3))
  (O (+ (key_witness $qid $k))))

(exec (warmr 520 count_l3_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 525 zero_fallback_l3_bfs)
  (, (candidate_pending_eval $qid))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 530 cleanup_l3_bfs)
  (, (candidate_support $qid $cnt)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

;; -----------------------------------------------------------------------------
;; STAGE 540–545: Level 3 Classification & Anti-Monotonic Pruning (64-bit)
;; -----------------------------------------------------------------------------
(exec (warmr 540 compute_l3_freq_status)
  (, (candidate $cid 3 $body $types $pid)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l3 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 541 classify_l3_freq)
  (, (frequent_status_l3 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l3 $cid 1))))

(exec (warmr 542 classify_l3_infreq)
  (, (frequent_status_l3 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l3 $cid 0))))

;; -----------------------------------------------------------------------------
;; STAGE 580: Search Status and Clean Termination
;; -----------------------------------------------------------------------------
(exec (warmr 710 search_completion)
  (, (INPUT MAX_LENGTH $max_l))
  (O (+ (warmr_search_status completed $max_l))))
;; =============================================================================
;; Dynamic Search Loop & Candidate Generation for Depths 3..8
;; =============================================================================

;; -----------------------------------------------------------------------------
;; Level 2 Chain to Level 3 Chain Refinement (Stage 470)
;; -----------------------------------------------------------------------------
(exec (warmr 466 expand_frequent_l2_chain)
  (, (candidate_frequent (cand_l2_chain $p1 $p2) $cnt)
     (candidate (cand_l2_chain $p1 $p2) 2 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 2 $max_l))
  (O (+ (expand_candidate (cand_l2_chain $p1 $p2)))))

(exec (warmr 470 ref_l2_to_l3_chain)
  (, (expand_candidate (cand_l2_chain $p1 $p2))
     (candidate (cand_l2_chain $p1 $p2) 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2)) $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 2 $max_l)
     (allowed_body_predicate positive_example $p3 ((+ $t2) (- $otype3))))
  (O (+ (candidate (cand_l3_chain (cand_l2_chain $p1 $p2) $p3) 3 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $otype3)) (cand_l2_chain $p1 $p2)))
     (+ (candidate_pending_eval (cand_l3_chain (cand_l2_chain $p1 $p2) $p3)))
     (+ (candidate_pool 3 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)))))))

;; -----------------------------------------------------------------------------
;; Level 3 Evaluation & Support for Chains (Stage 510..542)
;; -----------------------------------------------------------------------------
(exec (warmr 510 eval_l3_chain_bfs)
  (, (candidate $qid 3 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1) ($p2 $v1 $v2) ($p3 $v2 $v3))
  (O (+ (key_witness $qid $k))))

;; -----------------------------------------------------------------------------
;; STAGES 565..579: Level 3 Expansion Gate & Level 4 Refinement
;; -----------------------------------------------------------------------------
(exec (warmr 565 expand_frequent_l3_chain)
  (, (candidate_frequent (cand_l3_chain $pid $p3) $cnt)
     (candidate (cand_l3_chain $pid $p3) 3 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 3 $max_l))
  (O (+ (expand_candidate (cand_l3_chain $pid $p3)))))

(exec (warmr 565 expand_frequent_l3_const)
  (, (candidate_frequent (cand_l3 $c1 $c2 $c3) $cnt)
     (candidate (cand_l3 $c1 $c2 $c3) 3 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 3 $max_l))
  (O (+ (expand_candidate (cand_l3 $c1 $c2 $c3)))))

(exec (warmr 566 ref_l3_to_l4_chain)
  (, (expand_candidate (cand_l3_chain $pid $p3))
     (candidate (cand_l3_chain $pid $p3) 3 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3)) $orig)
     (allowed_body_predicate positive_example $p4 ((+ $t3) (- $otype4))))
  (O (+ (candidate (cand_l4_chain (cand_l3_chain $pid $p3) $p4) 4 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $otype4)) (cand_l3_chain $pid $p3)))
     (+ (candidate_pending_eval (cand_l4_chain (cand_l3_chain $pid $p3) $p4)))
     (+ (candidate_pool 4 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)))))))

(exec (warmr 566 ref_l3_to_l4_ordered)
  (, (expand_candidate (cand_l3 $c1 $c2 $c3))
     (candidate (cand_l3 $c1 $c2 $c3) 3 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3))) (((var 0) $ptype)) $orig)
     (attr_lt $c3 $c4)
     (allowed_body_predicate positive_example $p4 ((+ $ptype) (# attribute)))
     (valid_constant attribute $c4))
  (O (+ (candidate (cand_l4 $c1 $c2 $c3 $c4) 4 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4))) (((var 0) $ptype)) (cand_l3 $c1 $c2 $c3)))
     (+ (candidate_pending_eval (cand_l4 $c1 $c2 $c3 $c4)))
     (+ (candidate_pool 4 ((Inheritance (var 0) (const $c1)) (Inheritance (var 0) (const $c2)) (Inheritance (var 0) (const $c3)) (Inheritance (var 0) (const $c4)))))))

;; -----------------------------------------------------------------------------
;; STAGES 570..579: Level 4 Evaluation & Support
;; -----------------------------------------------------------------------------
(exec (warmr 570 eval_l4_bfs)
  (, (candidate $qid 4 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1) ($p2 $v1 $v2) ($p3 $v2 $v3) ($p4 $v3 $v4))
  (O (+ (key_witness $qid $k))))

(exec (warmr 570 eval_l4_const_bfs)
  (, (candidate $qid 4 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4))) $types $pid)
     (positive_example $k)
     ($p1 $k $c1) ($p2 $k $c2) ($p3 $k $c3) ($p4 $k $c4))
  (O (+ (key_witness $qid $k))))

(exec (warmr 571 count_l4_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k)
     (candidate $qid 4 $b $t $p))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 571 zero_fallback_l4_bfs)
  (, (candidate_pending_eval $qid)
     (candidate $qid 4 $b $t $p))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 572 cleanup_l4_bfs)
  (, (candidate_support $qid $cnt)
     (candidate $qid 4 $b $t $p)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

(exec (warmr 573 compute_l4_freq_status)
  (, (candidate $cid 4 $body $types $pid)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l4 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 574 classify_l4_freq)
  (, (frequent_status_l4 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l4 $cid 1))))

(exec (warmr 574 classify_l4_infreq)
  (, (frequent_status_l4 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l4 $cid 0))))

;; -----------------------------------------------------------------------------
;; STAGES 600..619: Level 4 Expansion & Level 5 Refinement + Evaluation
;; -----------------------------------------------------------------------------
(exec (warmr 600 expand_frequent_l4_chain)
  (, (candidate_frequent (cand_l4_chain $pid $p4) $cnt)
     (candidate (cand_l4_chain $pid $p4) 4 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 4 $max_l))
  (O (+ (expand_candidate (cand_l4_chain $pid $p4)))))

(exec (warmr 600 expand_frequent_l4_const)
  (, (candidate_frequent (cand_l4 $c1 $c2 $c3 $c4) $cnt)
     (candidate (cand_l4 $c1 $c2 $c3 $c4) 4 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 4 $max_l))
  (O (+ (expand_candidate (cand_l4 $c1 $c2 $c3 $c4)))))

(exec (warmr 601 ref_l4_to_l5_chain)
  (, (expand_candidate (cand_l4_chain $pid $p4))
     (candidate (cand_l4_chain $pid $p4) 4 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4)) $orig)
     (allowed_body_predicate positive_example $p5 ((+ $t4) (- $otype5))))
  (O (+ (candidate (cand_l5_chain (cand_l4_chain $pid $p4) $p5) 5 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4) ((var 5) $otype5)) (cand_l4_chain $pid $p4)))
     (+ (candidate_pending_eval (cand_l5_chain (cand_l4_chain $pid $p4) $p5)))
     (+ (candidate_pool 5 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)))))))

(exec (warmr 601 ref_l4_to_l5_ordered)
  (, (expand_candidate (cand_l4 $c1 $c2 $c3 $c4))
     (candidate (cand_l4 $c1 $c2 $c3 $c4) 4 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4))) (((var 0) $ptype)) $orig)
     (attr_lt $c4 $c5)
     (allowed_body_predicate positive_example $p5 ((+ $ptype) (# attribute)))
     (valid_constant attribute $c5))
  (O (+ (candidate (cand_l5 $c1 $c2 $c3 $c4 $c5) 5 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4)) ($p5 (var 0) (const $c5))) (((var 0) $ptype)) (cand_l4 $c1 $c2 $c3 $c4)))
     (+ (candidate_pending_eval (cand_l5 $c1 $c2 $c3 $c4 $c5)))
     (+ (candidate_pool 5 ((Inheritance (var 0) (const $c1)) (Inheritance (var 0) (const $c2)) (Inheritance (var 0) (const $c3)) (Inheritance (var 0) (const $c4)) (Inheritance (var 0) (const $c5)))))))

(exec (warmr 605 eval_l5_bfs)
  (, (candidate $qid 5 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1) ($p2 $v1 $v2) ($p3 $v2 $v3) ($p4 $v3 $v4) ($p5 $v4 $v5))
  (O (+ (key_witness $qid $k))))

(exec (warmr 605 eval_l5_const_bfs)
  (, (candidate $qid 5 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4)) ($p5 (var 0) (const $c5))) $types $pid)
     (positive_example $k)
     ($p1 $k $c1) ($p2 $k $c2) ($p3 $k $c3) ($p4 $k $c4) ($p5 $k $c5))
  (O (+ (key_witness $qid $k))))

(exec (warmr 606 count_l5_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k)
     (candidate $qid 5 $b $t $p))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 606 zero_fallback_l5_bfs)
  (, (candidate_pending_eval $qid)
     (candidate $qid 5 $b $t $p))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 607 cleanup_l5_bfs)
  (, (candidate_support $qid $cnt)
     (candidate $qid 5 $b $t $p)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

(exec (warmr 608 compute_l5_freq_status)
  (, (candidate $cid 5 $body $types $pid)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l5 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 609 classify_l5_freq)
  (, (frequent_status_l5 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l5 $cid 1))))

(exec (warmr 609 classify_l5_infreq)
  (, (frequent_status_l5 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l5 $cid 0))))

;; -----------------------------------------------------------------------------
;; STAGES 620..639: Level 5 Expansion & Level 6 Refinement + Evaluation
;; -----------------------------------------------------------------------------
(exec (warmr 620 expand_frequent_l5_chain)
  (, (candidate_frequent (cand_l5_chain $pid $p5) $cnt)
     (candidate (cand_l5_chain $pid $p5) 5 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 5 $max_l))
  (O (+ (expand_candidate (cand_l5_chain $pid $p5)))))

(exec (warmr 621 ref_l5_to_l6_chain)
  (, (expand_candidate (cand_l5_chain $pid $p5))
     (candidate (cand_l5_chain $pid $p5) 5 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4) ((var 5) $t5)) $orig)
     (allowed_body_predicate positive_example $p6 ((+ $t5) (- $otype6))))
  (O (+ (candidate (cand_l6_chain (cand_l5_chain $pid $p5) $p6) 6 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4) ((var 5) $t5) ((var 6) $otype6)) (cand_l5_chain $pid $p5)))
     (+ (candidate_pending_eval (cand_l6_chain (cand_l5_chain $pid $p5) $p6)))
     (+ (candidate_pool 6 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)))))))

(exec (warmr 625 eval_l6_bfs)
  (, (candidate $qid 6 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1) ($p2 $v1 $v2) ($p3 $v2 $v3) ($p4 $v3 $v4) ($p5 $v4 $v5) ($p6 $v5 $v6))
  (O (+ (key_witness $qid $k))))

(exec (warmr 626 count_l6_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k)
     (candidate $qid 6 $b $t $p))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 626 zero_fallback_l6_bfs)
  (, (candidate_pending_eval $qid)
     (candidate $qid 6 $b $t $p))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 627 cleanup_l6_bfs)
  (, (candidate_support $qid $cnt)
     (candidate $qid 6 $b $t $p)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

(exec (warmr 628 compute_l6_freq_status)
  (, (candidate $cid 6 $body $types $pid)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l6 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 629 classify_l6_freq)
  (, (frequent_status_l6 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l6 $cid 1))))

(exec (warmr 629 classify_l6_infreq)
  (, (frequent_status_l6 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l6 $cid 0))))

;; -----------------------------------------------------------------------------
;; STAGES 640..659: Level 6 Expansion & Level 7 Refinement + Evaluation
;; -----------------------------------------------------------------------------
(exec (warmr 640 expand_frequent_l6_chain)
  (, (candidate_frequent (cand_l6_chain $pid $p6) $cnt)
     (candidate (cand_l6_chain $pid $p6) 6 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 6 $max_l))
  (O (+ (expand_candidate (cand_l6_chain $pid $p6)))))

(exec (warmr 641 ref_l6_to_l7_chain)
  (, (expand_candidate (cand_l6_chain $pid $p6))
     (candidate (cand_l6_chain $pid $p6) 6 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4) ((var 5) $t5) ((var 6) $t6)) $orig)
     (allowed_body_predicate positive_example $p7 ((+ $t6) (- $otype7))))
  (O (+ (candidate (cand_l7_chain (cand_l6_chain $pid $p6) $p7) 7 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4) ((var 5) $t5) ((var 6) $t6) ((var 7) $otype7)) (cand_l6_chain $pid $p6)))
     (+ (candidate_pending_eval (cand_l7_chain (cand_l6_chain $pid $p6) $p7)))
     (+ (candidate_pool 7 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7)))))))

(exec (warmr 645 eval_l7_bfs)
  (, (candidate $qid 7 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1) ($p2 $v1 $v2) ($p3 $v2 $v3) ($p4 $v3 $v4) ($p5 $v4 $v5) ($p6 $v5 $v6) ($p7 $v6 $v7))
  (O (+ (key_witness $qid $k))))

(exec (warmr 646 count_l7_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k)
     (candidate $qid 7 $b $t $p))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 646 zero_fallback_l7_bfs)
  (, (candidate_pending_eval $qid)
     (candidate $qid 7 $b $t $p))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 647 cleanup_l7_bfs)
  (, (candidate_support $qid $cnt)
     (candidate $qid 7 $b $t $p)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

(exec (warmr 648 compute_l7_freq_status)
  (, (candidate $cid 7 $body $types $pid)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l7 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 649 classify_l7_freq)
  (, (frequent_status_l7 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l7 $cid 1))))

(exec (warmr 649 classify_l7_infreq)
  (, (frequent_status_l7 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l7 $cid 0))))

;; -----------------------------------------------------------------------------
;; STAGES 660..679: Level 7 Expansion & Level 8 Refinement + Evaluation
;; -----------------------------------------------------------------------------
(exec (warmr 660 expand_frequent_l7_chain)
  (, (candidate_frequent (cand_l7_chain $pid $p7) $cnt)
     (candidate (cand_l7_chain $pid $p7) 7 $body $types $orig)
     (INPUT MAX_LENGTH $max_l)
     (num_lt 7 $max_l))
  (O (+ (expand_candidate (cand_l7_chain $pid $p7)))))

(exec (warmr 661 ref_l7_to_l8_chain)
  (, (expand_candidate (cand_l7_chain $pid $p7))
     (candidate (cand_l7_chain $pid $p7) 7 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4) ((var 5) $t5) ((var 6) $t6) ((var 7) $t7)) $orig)
     (allowed_body_predicate positive_example $p8 ((+ $t7) (- $otype8))))
  (O (+ (candidate (cand_l8_chain (cand_l7_chain $pid $p7) $p8) 8 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7)) ($p8 (var 7) (var 8))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $t2) ((var 3) $t3) ((var 4) $t4) ((var 5) $t5) ((var 6) $t6) ((var 7) $t7) ((var 8) $otype8)) (cand_l7_chain $pid $p7)))
     (+ (candidate_pending_eval (cand_l8_chain (cand_l7_chain $pid $p7) $p8)))
     (+ (candidate_pool 8 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7)) ($p8 (var 7) (var 8)))))))

(exec (warmr 665 eval_l8_bfs)
  (, (candidate $qid 8 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7)) ($p8 (var 7) (var 8))) $types $pid)
     (positive_example $k)
     ($p1 $k $v1) ($p2 $v1 $v2) ($p3 $v2 $v3) ($p4 $v3 $v4) ($p5 $v4 $v5) ($p6 $v5 $v6) ($p7 $v6 $v7) ($p8 $v7 $v8))
  (O (+ (key_witness $qid $k))))

(exec (warmr 666 count_l8_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k)
     (candidate $qid 8 $b $t $p))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 666 zero_fallback_l8_bfs)
  (, (candidate_pending_eval $qid)
     (candidate $qid 8 $b $t $p))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 667 cleanup_l8_bfs)
  (, (candidate_support $qid $cnt)
     (candidate $qid 8 $b $t $p)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

(exec (warmr 668 compute_l8_freq_status)
  (, (candidate $cid 8 $body $types $pid)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l8 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 669 classify_l8_freq)
  (, (frequent_status_l8 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l8 $cid 1))))

(exec (warmr 669 classify_l8_infreq)
  (, (frequent_status_l8 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l8 $cid 0))))


;; -----------------------------------------------------------------------------
;; Relative Support Recording for Levels 2..8
;; -----------------------------------------------------------------------------
(exec (warmr 435 compute_relative_support_l2)
  (, (candidate_support $qid $count)
     (candidate $qid 2 $b $t $p)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))

(exec (warmr 535 compute_relative_support_l3)
  (, (candidate_support $qid $count)
     (candidate $qid 3 $b $t $p)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))

(exec (warmr 575 compute_relative_support_l4)
  (, (candidate_support $qid $count)
     (candidate $qid 4 $b $t $p)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))

(exec (warmr 615 compute_relative_support_l5)
  (, (candidate_support $qid $count)
     (candidate $qid 5 $b $t $p)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))

(exec (warmr 635 compute_relative_support_l6)
  (, (candidate_support $qid $count)
     (candidate $qid 6 $b $t $p)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))

(exec (warmr 655 compute_relative_support_l7)
  (, (candidate_support $qid $count)
     (candidate $qid 7 $b $t $p)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))

(exec (warmr 675 compute_relative_support_l8)
  (, (candidate_support $qid $count)
     (candidate $qid 8 $b $t $p)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))
