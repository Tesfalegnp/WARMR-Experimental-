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
;; Canonical Attribute Ordering for MM2 Benchmark (human < man < woman < ugly < sodaDrinker)
;; -----------------------------------------------------------------------------
;; Prevents duplicate permutation generation (e.g. man ∧ ugly vs ugly ∧ man)
;; and reflexive conjunctions (e.g. man ∧ man).
(attr_lt human man)
(attr_lt human woman)
(attr_lt human ugly)
(attr_lt human sodaDrinker)
(attr_lt man woman)
(attr_lt man ugly)
(attr_lt man sodaDrinker)
(attr_lt woman ugly)
(attr_lt woman sodaDrinker)
(attr_lt ugly sodaDrinker)

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
(exec (warmr 580 search_completion)
  (, (INPUT MAX_LENGTH $max_l))
  (O (+ (warmr_search_status completed $max_l))))
