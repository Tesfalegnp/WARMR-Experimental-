;; =============================================================================
;; src/support-calc.metta
;; =============================================================================
;; Purpose:
;;   General support calculation engine for the WARMR relational pattern miner
;;   in MeTTa/MM2 on MORK.
;;
;; Capabilities:
;;   - Evaluates Level 1 (single-literal) relational queries.
;;   - Evaluates Level 2 conjunctive queries (branched and chained).
;;   - Unifies shared variables across literals.
;;   - Projects successful substitutions onto the designated key variable (var 0).
;;   - Deduplicates multiple proofs/substitutions per key individual into
;;     distinct key witnesses using AtomSpace set semantics.
;;   - Counts distinct key witnesses per candidate via MORK's count sink.
;;   - Computes relative support against total positive key domain size.
;;   - Handles zero-support candidates safely via fallback.
;;   - Handles empty positive-example domains safely without division by zero.
;;   - Isolates candidate evaluation during concurrent batch runs.
;;   - Atomically cleans up temporary witness facts, leaving 0 orphan atoms.
;;   - Maintains backward compatibility with Milestone 1 bare queries.
;;
;; Execution Stages (Priority Namespace: warmr 305..349):
;;   305: (count_total_keys)        - Count total positive keys
;;   306: (fallback_empty_domain)   - Empty domain fallback (total = 0)
;;   310: (eval_poc_var)            - PoC backward compatibility (bare var)
;;   311: (eval_poc_const)          - PoC backward compatibility (bare const)
;;   312: (eval_l1_var)             - Level 1 free variable slot
;;   313: (eval_l1_const)           - Level 1 active domain constant slot
;;   314: (eval_l2_var_var)         - Level 2 branched: (var 0, var 1) & (var 0, var 2)
;;   315: (eval_l2_const_var)       - Level 2 branched: (var 0, const C) & (var 0, var 1)
;;   316: (eval_l2_var_const)       - Level 2 branched: (var 0, var 1) & (var 0, const C)
;;   317: (eval_l2_const_const)     - Level 2 branched: (var 0, const C1) & (var 0, const C2)
;;   318: (eval_l2_chain_var)       - Level 2 chained: (var 0, var 1) & (var 1, var 2)
;;   319: (eval_l2_chain_const)     - Level 2 chained: (var 0, var 1) & (var 1, const C)
;;   320: (count_witnesses)         - Distinct key witness counting per candidate
;;   325: (compute_relative_support)- Record exact rational relative support
;;   330: (zero_support_fallback)   - Zero-support candidate fallback
;;   340: (cleanup_witnesses)       - Retract temporary key_witness facts
;; =============================================================================

;; -----------------------------------------------------------------------------
;; STAGE 305: Count Total Positive Keys in the Domain
;; -----------------------------------------------------------------------------
;; Counts the total number of individuals in the key domain (positive_example $k).
;; Consumes key_domain_pending_count once positive examples are counted.
(exec (warmr 305 count_total_keys)
  (, (key_domain_pending_count)
     (positive_example $k))
  (O (count (total_positive_keys $tot) $tot $k)
     (- (key_domain_pending_count))))

;; -----------------------------------------------------------------------------
;; STAGE 306: Empty Key Domain Fallback
;; -----------------------------------------------------------------------------
;; If the database contains 0 positive examples, Stage 305 did not fire.
;; Stage 306 safely sets total_positive_keys to 0, avoiding undefined ratios.
(exec (warmr 306 fallback_empty_domain)
  (, (key_domain_pending_count))
  (O (+ (total_positive_keys 0))
     (- (key_domain_pending_count))))

;; -----------------------------------------------------------------------------
;; STAGE 310–311: Milestone 1 PoC(Proof of Concept) Backward Compatibility
;; -----------------------------------------------------------------------------
;; Matches legacy candidate syntax: (candidate <qid> 1 (<pred> <arg1> <arg2>))
(exec (warmr 310 eval_poc_var)
  (, (candidate $qid 1 ($pred (var 0) (var 1)))
     (positive_example $key)
     ($pred $key $val))
  (O (+ (key_witness $qid $key))))

(exec (warmr 311 eval_poc_const)
  (, (candidate $qid 1 ($pred (var 0) (const $c)))
     (positive_example $key)
     ($pred $key $c))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 312–313: Level 1 Generalized Candidates (List Representation)
;; -----------------------------------------------------------------------------
;; Matches full candidate syntax:
;;   (candidate <qid> 1 ((<pred> <arg1> <arg2>)) <types> <parent>)
(exec (warmr 312 eval_l1_var)
  (, (candidate $qid 1 (($pred (var 0) (var 1))) $types $parent)
     (positive_example $key)
     ($pred $key $val))
  (O (+ (key_witness $qid $key))))

(exec (warmr 313 eval_l1_const)
  (, (candidate $qid 1 (($pred (var 0) (const $c))) $types $parent)
     (positive_example $key)
     ($pred $key $c))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 314–317: Level 2 Branched Conjunctions
;; -----------------------------------------------------------------------------
;; Both literals share the key variable (var 0) in argument 1.

;; Case 1: Both literals have free variables in argument 2.
(exec (warmr 314 eval_l2_var_var)
  (, (candidate $qid 2 (($p1 (var 0) (var 1)) ($p2 (var 0) (var 2))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $key $v2))
  (O (+ (key_witness $qid $key))))

;; Case 2: Literal 1 has constant, Literal 2 has free variable.
(exec (warmr 315 eval_l2_const_var)
  (, (candidate $qid 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (var 1))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $v1))
  (O (+ (key_witness $qid $key))))

;; Case 3: Literal 1 has free variable, Literal 2 has constant.
(exec (warmr 316 eval_l2_var_const)
  (, (candidate $qid 2 (($p1 (var 0) (var 1)) ($p2 (var 0) (const $c2))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $key $c2))
  (O (+ (key_witness $qid $key))))

;; Case 4: Both literals have constants (e.g. ugly-sodaDrinker benchmark).
(exec (warmr 317 eval_l2_const_const)
  (, (candidate $qid 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $c2))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 317b: Level 3 Branched Conjunctions
;; -----------------------------------------------------------------------------
;; All three literals share the key variable (var 0) in argument 1 and match constants.
(exec (warmr 317 eval_l3_const_const_const)
  (, (candidate $qid 3 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $c2)
     ($p3 $key $c3))
  (O (+ (key_witness $qid $key))))

;; Level 3: 3-hop Relational Chain
(exec (warmr 317 eval_l3_chain_var)
  (, (candidate $qid 3 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $v2)
     ($p3 $v2 $v3))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 318–319: Level 2 Chained Conjunctions
;; -----------------------------------------------------------------------------
;; Literal 1 connects to key (var 0) and introduces variable (var 1).
;; Literal 2 connects to (var 1) in argument 1.

;; Case 1: Literal 2 has free variable in argument 2.
(exec (warmr 318 eval_l2_chain_var)
  (, (candidate $qid 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $v2))
  (O (+ (key_witness $qid $key))))

;; Case 2: Literal 2 has constant in argument 2.
(exec (warmr 319 eval_l2_chain_const)
  (, (candidate $qid 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (const $c2))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $c2))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 319b: Milestone 7 Multi-Arity Relational Evaluators
;; -----------------------------------------------------------------------------
;; 1. Unary Predicate Evaluation (Arity 1)
(exec (warmr 319 eval_l1_unary)
  (, (candidate $qid 1 (($pred (var 0))) $types $parent)
     (positive_example $key)
     ($pred $key))
  (O (+ (key_witness $qid $key))))

;; 2. Ternary Predicate Evaluation (Arity 3)
(exec (warmr 319 eval_l1_ternary_var_const)
  (, (candidate $qid 1 (($pred (var 0) (var 1) (const $c))) $types $parent)
     (positive_example $key)
     ($pred $key $v1 $c))
  (O (+ (key_witness $qid $key))))

(exec (warmr 319 eval_l1_ternary_var_var)
  (, (candidate $qid 1 (($pred (var 0) (var 1) (var 2))) $types $parent)
     (positive_example $key)
     ($pred $key $v1 $v2))
  (O (+ (key_witness $qid $key))))

(exec (warmr 319 eval_l1_ternary_const_const)
  (, (candidate $qid 1 (($pred (var 0) (const $c1) (const $c2))) $types $parent)
     (positive_example $key)
     ($pred $key $c1 $c2))
  (O (+ (key_witness $qid $key))))

;; 3. 4-Ary Predicate Evaluation (Arity 4)
(exec (warmr 319 eval_l1_4ary_const3)
  (, (candidate $qid 1 (($pred (var 0) (const $c1) (const $c2) (const $c3))) $types $parent)
     (positive_example $key)
     ($pred $key $c1 $c2 $c3))
  (O (+ (key_witness $qid $key))))

(exec (warmr 319 eval_l1_4ary_var_const2)
  (, (candidate $qid 1 (($pred (var 0) (var 1) (const $c2) (const $c3))) $types $parent)
     (positive_example $key)
     ($pred $key $v1 $c2 $c3))
  (O (+ (key_witness $qid $key))))

(exec (warmr 319 eval_l1_4ary_var2_const)
  (, (candidate $qid 1 (($pred (var 0) (var 1) (var 2) (const $c))) $types $parent)
     (positive_example $key)
     ($pred $key $v1 $v2 $c))
  (O (+ (key_witness $qid $key))))

;; 4. Multi-Arity Level 2 Conjunctions (Unary + Unary, Chained Unary)
(exec (warmr 319 eval_l2_unary_unary)
  (, (candidate $qid 2 (($p1 (var 0)) ($p2 (var 0))) $types $parent)
     (positive_example $key)
     ($p1 $key)
     ($p2 $key))
  (O (+ (key_witness $qid $key))))

(exec (warmr 319 eval_l2_bin_unary_chain)
  (, (candidate $qid 2 (($p1 (var 0) (var 1)) ($p2 (var 1))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1))
  (O (+ (key_witness $qid $key))))

(exec (warmr 319 eval_l2_ternary_unary_chain)
  (, (candidate $qid 2 (($p1 (var 0) (var 1) (const $c)) ($p2 (var 1))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1 $c)
     ($p2 $v1))
  (O (+ (key_witness $qid $key))))

(exec (warmr 319 eval_l2_ternary_ternary_chain)
  (, (candidate $qid 2 (($p1 (var 0) (var 1) (const $c1)) ($p2 (var 1) (var 2) (const $c2))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1 $c1)
     ($p2 $v1 $v2 $c2))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 319c: Milestone 7 Deep Conjunctions (Lengths 4 and 5)
;; -----------------------------------------------------------------------------
;; Level 4: 4-hop Relational Chain
(exec (warmr 319 eval_l4_chain)
  (, (candidate $qid 4 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $v2)
     ($p3 $v2 $v3)
     ($p4 $v3 $v4))
  (O (+ (key_witness $qid $key))))

;; Level 4: 4-literal Branched Constants
(exec (warmr 319 eval_l4_branched_const)
  (, (candidate $qid 4 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $c2)
     ($p3 $key $c3)
     ($p4 $key $c4))
  (O (+ (key_witness $qid $key))))

;; Level 5: 5-hop Relational Chain
(exec (warmr 319 eval_l5_chain)
  (, (candidate $qid 5 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $v2)
     ($p3 $v2 $v3)
     ($p4 $v3 $v4)
     ($p5 $v4 $v5))
  (O (+ (key_witness $qid $key))))

;; Level 5: 5-literal Branched Constants
(exec (warmr 319 eval_l5_branched_const)
  (, (candidate $qid 5 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4)) ($p5 (var 0) (const $c5))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $c2)
     ($p3 $key $c3)
     ($p4 $key $c4)
     ($p5 $key $c5))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 319d: Deep Conjunctions (Lengths 6, 7, 8)
;; -----------------------------------------------------------------------------
;; Level 6: 6-hop Relational Chain
(exec (warmr 319 eval_l6_chain)
  (, (candidate $qid 6 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $v2)
     ($p3 $v2 $v3)
     ($p4 $v3 $v4)
     ($p5 $v4 $v5)
     ($p6 $v5 $v6))
  (O (+ (key_witness $qid $key))))

;; Level 6: 6-literal Branched Constants
(exec (warmr 319 eval_l6_branched_const)
  (, (candidate $qid 6 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4)) ($p5 (var 0) (const $c5)) ($p6 (var 0) (const $c6))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $c2)
     ($p3 $key $c3)
     ($p4 $key $c4)
     ($p5 $key $c5)
     ($p6 $key $c6))
  (O (+ (key_witness $qid $key))))

;; Level 7: 7-hop Relational Chain
(exec (warmr 319 eval_l7_chain)
  (, (candidate $qid 7 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $v2)
     ($p3 $v2 $v3)
     ($p4 $v3 $v4)
     ($p5 $v4 $v5)
     ($p6 $v5 $v6)
     ($p7 $v6 $v7))
  (O (+ (key_witness $qid $key))))

;; Level 7: 7-literal Branched Constants
(exec (warmr 319 eval_l7_branched_const)
  (, (candidate $qid 7 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4)) ($p5 (var 0) (const $c5)) ($p6 (var 0) (const $c6)) ($p7 (var 0) (const $c7))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $c2)
     ($p3 $key $c3)
     ($p4 $key $c4)
     ($p5 $key $c5)
     ($p6 $key $c6)
     ($p7 $key $c7))
  (O (+ (key_witness $qid $key))))

;; Level 8: 8-hop Relational Chain
(exec (warmr 319 eval_l8_chain)
  (, (candidate $qid 8 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2)) ($p3 (var 2) (var 3)) ($p4 (var 3) (var 4)) ($p5 (var 4) (var 5)) ($p6 (var 5) (var 6)) ($p7 (var 6) (var 7)) ($p8 (var 7) (var 8))) $types $parent)
     (positive_example $key)
     ($p1 $key $v1)
     ($p2 $v1 $v2)
     ($p3 $v2 $v3)
     ($p4 $v3 $v4)
     ($p5 $v4 $v5)
     ($p6 $v5 $v6)
     ($p7 $v6 $v7)
     ($p8 $v7 $v8))
  (O (+ (key_witness $qid $key))))

;; Level 8: 8-literal Branched Constants
(exec (warmr 319 eval_l8_branched_const)
  (, (candidate $qid 8 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3)) ($p4 (var 0) (const $c4)) ($p5 (var 0) (const $c5)) ($p6 (var 0) (const $c6)) ($p7 (var 0) (const $c7)) ($p8 (var 0) (const $c8))) $types $parent)
     (positive_example $key)
     ($p1 $key $c1)
     ($p2 $key $c2)
     ($p3 $key $c3)
     ($p4 $key $c4)
     ($p5 $key $c5)
     ($p6 $key $c6)
     ($p7 $key $c7)
     ($p8 $key $c8))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 320: Distinct Key Witness Counting
;; -----------------------------------------------------------------------------
;; Counts unique (key_witness $qid $key) facts stored in the AtomSpace.
;; Consumes candidate_pending_eval to record evaluation success.
(exec (warmr 320 count_witnesses)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $key))
  (O (count (candidate_support $qid $count) $count $key)
     (- (candidate_pending_eval $qid))))

;; -----------------------------------------------------------------------------
;; STAGE 330: Zero-Support Candidate Fallback
;; -----------------------------------------------------------------------------
;; If a candidate produces 0 key witnesses, Stage 320 did not fire, leaving
;; candidate_pending_eval intact. Stage 330 catches this and safely asserts support 0.
(exec (warmr 330 zero_support_fallback)
  (, (candidate_pending_eval $qid))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

;; -----------------------------------------------------------------------------
;; STAGE 335: Relative Support Recording
;; -----------------------------------------------------------------------------
;; Records exact relative support as a rational pair (count / total_keys).
;; Runs after Stage 330 so zero-support candidates also receive relative support.
;; If total_positive_keys is 0, records (candidate_relative_support $qid 0 0),
;; representing 0.0 relative support without undefined arithmetic.
(exec (warmr 335 compute_relative_support)
  (, (candidate_support $qid $count)
     (total_positive_keys $tot))
  (O (+ (candidate_relative_support $qid $count $tot))))

;; -----------------------------------------------------------------------------
;; STAGE 340: Cleanup Temporary Key Witnesses
;; -----------------------------------------------------------------------------
;; Retracts all temporary key_witness facts once candidate_support is produced,
;; guaranteeing a clean AtomSpace for downstream pipeline stages.
(exec (warmr 340 cleanup_witnesses)
  (, (candidate_support $qid $count)
     (key_witness $qid $key))
  (O (- (key_witness $qid $key))))
