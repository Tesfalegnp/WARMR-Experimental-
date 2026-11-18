;; =============================================================================
;; src/warmr.metta
;; =============================================================================
;; Purpose:
;;   Top-Level WARMR Relational Pattern Miner Pipeline Coordinator.
;;
;; Algorithmic Foundations:
;;   Orchestrates the complete WARMR relational pattern discovery lifecycle
;;   under MeTTa/MM2 on MORK:
;;     Stage 1: Initialization & Key Domain Identification
;;     Stage 2: Language-Bias Loading & Mode Compilation
;;     Stage 3: Root Candidate Q0 Initialization
;;     Stage 4: Level 1 Candidate Generation (Refinement rho(Q0))
;;     Stage 5: Canonicalization & Pool Deduplication
;;     Stage 6: Support Calculation & Distinct Key Witness Projection
;;     Stage 7: Frequent / Infrequent Classification
;;     Stage 8: Anti-Monotonic Pruning
;;     Stage 9: Level 2 / Level 3 BFS Search Progression (via search-loop.metta)
;;     Stage 10: Maximum Length & Empty Level Termination
;;     Stage 11: Structured Output Record Emission (via output.metta)
;;     Stage 12: Temporary State Cleanup
;;
;; Priority Conventions:
;;   100..105: Pipeline Initialization & Key Counting Trigger
;;   215..219: Level 1 Candidate Generation rho(Q0)
;;   220..224: Level 1 Query Evaluation
;;   225..234: Level 1 Support Counting & Witness Cleanup
;;   235..239: Level 1 Classification & Anti-Monotonic Pruning
;;   305..349: General Support Calculation Engine
;;   365..499: Level 2 BFS Expansion & Evaluation (search-loop.metta)
;;   500..549: Level 3 BFS Expansion & Evaluation (search-loop.metta)
;;   560..569: Structured Result Output (output.metta)
;;   570..599: Pruning Confirmation & Termination Status
;; =============================================================================

;; -----------------------------------------------------------------------------
;; STAGE 150: Pipeline Initialization
;; -----------------------------------------------------------------------------
;; When key predicate mode is compiled at Stage 110, automatically trigger key
;; domain counting and initialize the root candidate Q0.
(exec (warmr 150 init_warmr_pipeline)
  (, (valid_modeh $kpred ((+ $ktype))))
  (O (+ (key_domain_pending_count))
     (+ (candidate root 0 () (((var 0) $ktype)) nil))
     (+ (expand_candidate root))))

;; -----------------------------------------------------------------------------
;; STAGE 215–216: Level 1 Refinement Operator rho(Q0)
;; -----------------------------------------------------------------------------
;; Mode 1A: Body literal with constant slot (# ctype)
(exec (warmr 215 ref_root_const_bfs)
  (, (expand_candidate root)
     (candidate root 0 () (((var 0) $ptype)) nil)
     (allowed_body_predicate positive_example $pred ((+ $ptype) (# $atype)))
     (valid_constant $atype $c))
  (O (+ (candidate (cand_l1 $c) 1 (($pred (var 0) (const $c))) (((var 0) $ptype)) root))
     (+ (candidate_pending_eval (cand_l1 $c)))
     (+ (candidate_pool 1 (($pred (var 0) (const $c)))))))

;; Mode 1B: Body literal with output variable slot (- otype)
(exec (warmr 216 ref_root_var_bfs)
  (, (expand_candidate root)
     (candidate root 0 () (((var 0) $ktype)) nil)
     (allowed_body_predicate positive_example $pred ((+ $ktype) (- $otype))))
  (O (+ (candidate (cand_l1 $pred var1) 1 (($pred (var 0) (var 1))) (((var 0) $ktype) ((var 1) $otype)) root))
     (+ (candidate_pending_eval (cand_l1 $pred var1)))
     (+ (candidate_pool 1 (($pred (var 0) (var 1)))))))

;; Mode 1C: Body literal with unary predicate (+ ktype)
(exec (warmr 217 ref_root_unary_bfs)
  (, (expand_candidate root)
     (candidate root 0 () (((var 0) $ktype)) nil)
     (allowed_body_predicate positive_example $pred ((+ $ktype))))
  (O (+ (candidate (cand_l1 $pred) 1 (($pred (var 0))) (((var 0) $ktype)) root))
     (+ (candidate_pending_eval (cand_l1 $pred)))
     (+ (candidate_pool 1 (($pred (var 0)))))))

;; -----------------------------------------------------------------------------
;; STAGE 220–222: Level 1 Evaluation
;; -----------------------------------------------------------------------------
;; Case 1: Constant slot
(exec (warmr 220 eval_l1_const_bfs)
  (, (candidate $qid 1 (($p (var 0) (const $c))) $types root)
     (positive_example $k)
     ($p $k $c))
  (O (+ (key_witness $qid $k))))

;; Case 2: Output variable slot
(exec (warmr 221 eval_l1_var_bfs)
  (, (candidate $qid 1 (($p (var 0) (var 1))) $types root)
     (positive_example $k)
     ($p $k $v))
  (O (+ (key_witness $qid $k))))

;; Case 3: Unary predicate
(exec (warmr 222 eval_l1_unary_bfs)
  (, (candidate $qid 1 (($p (var 0))) $types root)
     (positive_example $k)
     ($p $k))
  (O (+ (key_witness $qid $k))))

;; -----------------------------------------------------------------------------
;; STAGE 225–230: Level 1 Support Counting & Witness Cleanup
;; -----------------------------------------------------------------------------
(exec (warmr 225 count_l1_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

(exec (warmr 226 zero_fallback_l1_bfs)
  (, (candidate_pending_eval $qid))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

(exec (warmr 230 cleanup_l1_bfs)
  (, (candidate_support $qid $cnt)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

;; -----------------------------------------------------------------------------
;; STAGE 235–236: Level 1 Support Classification & Anti-Monotonic Pruning (64-bit)
;; -----------------------------------------------------------------------------
(exec (warmr 235 compute_l1_freq_status)
  (, (candidate $cid 1 $body $types root)
     (candidate_support $cid $cnt)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status_l1 $cid $is_f) $is_f
       (i8_to_string (gte_i64 (i64_from_string $cnt) (i64_from_string $min_s))))))

(exec (warmr 236 classify_l1_freq)
  (, (frequent_status_l1 $cid 1)
     (candidate_support $cid $cnt))
  (O (+ (candidate_frequent $cid $cnt))
     (- (frequent_status_l1 $cid 1))))

(exec (warmr 236 classify_l1_infreq)
  (, (frequent_status_l1 $cid 0)
     (candidate_support $cid $cnt))
  (O (+ (candidate_infrequent $cid $cnt))
     (+ (prune_branch $cid))
     (- (frequent_status_l1 $cid 0))))
