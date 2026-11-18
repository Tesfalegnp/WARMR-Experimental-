;; =============================================================================
;; src/candidate-gen.metta
;; =============================================================================
;; Purpose:
;;   Candidate Refinement Operator rho(Q) and Validation Engine for the WARMR
;;   relational pattern miner in MeTTa/MM2 on MORK.
;;
;; Algorithmic Foundations:
;;   Implements the WARMR specialization operator:
;;     rho(Q) = { Q' | Q' is a valid 1-literal specialization of Q }
;;
;; Language-Bias Mode Semantics:
;;   '+' (Input slot):  Must bind to an existing variable in Q of declared type.
;;   '-' (Output slot): Introduces a fresh variable of declared type.
;;   '#' (Constant slot): Binds to an active domain constant from valid_constant.
;;
;; Enforced Invariants:
;;   1. Predicate Arity: Must match declared predicate_arity.
;;   2. Declared Types: Slots only bind to variables or constants of matching type.
;;   3. Connectivity: Every added literal must share at least one input variable
;;      connecting back to the key variable (var 0).
;;   4. Allowed Body Predicates: Only predicates declared in allowed_body_predicate.
;;   5. Search Limits: Respects configured_limits (max_length).
;;
;; Priority Convention:
;;   Validation: 201..212
;;   Refinement: 215..229
;;   (Canonicalization runs downstream at 230..249)
;; =============================================================================

;; -----------------------------------------------------------------------------
;; STAGE 201–212: Declarative Candidate Validation and Error Detection
;; -----------------------------------------------------------------------------
;; Validates proposed candidates (validate_candidate <id> <len> <body> <types> <parent>)
;; Catches malformed, disconnected, or illegal candidates.

;; 1. Check Allowed Body Predicates
(exec (warmr 201 check_disallowed_pred)
  (, (validate_candidate $cid $len (($pred $a1 $a2)) $types $parent))
  (O (+ (pending_pred_check $cid $pred))))

(exec (warmr 202 confirm_allowed_pred)
  (, (pending_pred_check $cid $pred)
     (allowed_body_predicate positive_example $pred $modes))
  (O (- (pending_pred_check $cid $pred))
     (+ (pred_check_ok $cid $pred))))

(exec (warmr 203 catch_disallowed_pred)
  (, (pending_pred_check $cid $pred))
  (O (- (pending_pred_check $cid $pred))
     (+ (candidate_error disallowed_predicate $cid $pred))))

;; 2. Check Predicate Arity (e.g. arity 3 when arity 2 expected)
(exec (warmr 204 catch_bad_arity_3)
  (, (validate_candidate $cid $len (($pred $a1 $a2 $a3)) $types $parent)
     (predicate_arity $pred 2))
  (O (+ (candidate_error invalid_arity $cid $pred 3 2))))

;; 3. Check Constant Argument Types
(exec (warmr 205 check_constant_type)
  (, (validate_candidate $cid $len (($pred $a1 (const $c))) $types $parent)
     (valid_slot $pred 2 constant $ctype))
  (O (+ (pending_const_check $cid $ctype $c))))

(exec (warmr 206 confirm_valid_constant)
  (, (pending_const_check $cid $ctype $c)
     (valid_constant $ctype $c))
  (O (- (pending_const_check $cid $ctype $c))))

(exec (warmr 207 catch_invalid_constant)
  (, (pending_const_check $cid $ctype $c))
  (O (- (pending_const_check $cid $ctype $c))
     (+ (candidate_error invalid_argument_type $cid $ctype $c))))

;; 4. Check Connectivity (slot 1 must connect to key var 0)
(exec (warmr 208 check_connectivity_l1)
  (, (validate_candidate $cid 1 (($pred (var $v) $a2)) $types $parent))
  (O (+ (check_conn_l1 $cid $v))))

(exec (warmr 209 confirm_connectivity_l1)
  (, (check_conn_l1 $cid 0))
  (O (- (check_conn_l1 $cid 0))))

(exec (warmr 210 catch_disconnected_l1)
  (, (check_conn_l1 $cid $v))
  (O (- (check_conn_l1 $cid $v))
     (+ (candidate_error disconnected_candidate $cid (var $v)))))

;; 5. Confirm Valid Level 1 Candidate
(exec (warmr 211 confirm_valid_l1)
  (, (validate_candidate $cid 1 (($pred (var 0) (const $c))) $types $parent)
     (allowed_body_predicate positive_example $pred $modes)
     (valid_slot $pred 2 constant $ctype)
     (valid_constant $ctype $c))
  (O (+ (valid_candidate $cid))))

;; 6. Confirm Valid Level 2 Candidate
(exec (warmr 212 confirm_valid_l2)
  (, (validate_candidate $cid 2 (($p1 (var 0) (const $c)) ($p2 (var 0) (var 1))) $types $parent)
     (allowed_body_predicate positive_example $p1 $m1)
     (allowed_body_predicate positive_example $p2 $m2))
  (O (+ (valid_candidate $cid))))

;; 7. Confirm Valid Level 3 Candidate
(exec (warmr 213 confirm_valid_l3)
  (, (validate_candidate $cid 3 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3))) $types $parent)
     (allowed_body_predicate positive_example $p1 $m1)
     (allowed_body_predicate positive_example $p2 $m2)
     (allowed_body_predicate positive_example $p3 $m3))
  (O (+ (valid_candidate $cid))))

;; -----------------------------------------------------------------------------
;; STAGE 215–219: Level 1 Refinement Operator rho(root)
;; -----------------------------------------------------------------------------
;; Specializes the root query (length 0) into Level 1 candidates (length 1).

;; Refinement 1A: Slot 1 is input (+ ktype), Slot 2 is constant (# ctype)
(exec (warmr 215 ref_root_const)
  (, (expand_candidate root_gene)
     (candidate root_gene 0 () (((var 0) $ktype)) nil)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $pred ((+ $ktype) (# $ctype)))
     (valid_constant $ctype $c))
  (O (+ (raw_candidate (cand_l1 $pred $c) 1 (($pred (var 0) (const $c))) (((var 0) $ktype)) root_gene))))

(exec (warmr 215 ref_root_person_const)
  (, (expand_candidate root_person)
     (candidate root_person 0 () (((var 0) $ptype)) nil)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $pred ((+ $ptype) (# $atype)))
     (valid_constant $atype $c))
  (O (+ (raw_candidate (cand_l1 $pred $c) 1 (($pred (var 0) (const $c))) (((var 0) $ptype)) root_person))))

;; Refinement 1B: Slot 1 is input (+ ktype), Slot 2 is output fresh variable (- otype)
(exec (warmr 216 ref_root_out_var)
  (, (expand_candidate root_gene)
     (candidate root_gene 0 () (((var 0) $ktype)) nil)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $pred ((+ $ktype) (- $otype))))
  (O (+ (raw_candidate (cand_l1 $pred var1) 1 (($pred (var 0) (var 1))) (((var 0) $ktype) ((var 1) $otype)) root_gene))))

;; -----------------------------------------------------------------------------
;; STAGE 217–219: Multi-Arity Level 1 Refinement Operator rho(root)
;; -----------------------------------------------------------------------------
;; Refinement 1C: Unary predicate (+ ktype)
(exec (warmr 217 ref_root_unary)
  (, (expand_candidate $root)
     (candidate $root 0 () (((var 0) $ktype)) nil)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $pred ((+ $ktype))))
  (O (+ (raw_candidate (cand_l1 $pred) 1 (($pred (var 0))) (((var 0) $ktype)) $root))))

;; Refinement 1D: Ternary predicate (+ ktype, - otype, # ctype)
(exec (warmr 218 ref_root_ternary_var_const)
  (, (expand_candidate $root)
     (candidate $root 0 () (((var 0) $ktype)) nil)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $pred ((+ $ktype) (- $otype) (# $ctype)))
     (valid_constant $ctype $c))
  (O (+ (raw_candidate (cand_l1 $pred $c) 1 (($pred (var 0) (var 1) (const $c))) (((var 0) $ktype) ((var 1) $otype)) $root))))

;; Refinement 1E: 4-Ary predicate (+ ktype, # c1, # c2, # c3)
(exec (warmr 219 ref_root_4ary_const3)
  (, (expand_candidate $root)
     (candidate $root 0 () (((var 0) $ktype)) nil)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $pred ((+ $ktype) (# $t1) (# $t2) (# $t3)))
     (valid_constant $t1 $c1)
     (valid_constant $t2 $c2)
     (valid_constant $t3 $c3))
  (O (+ (raw_candidate (cand_l1 $pred $c1 $c2 $c3) 1 (($pred (var 0) (const $c1) (const $c2) (const $c3))) (((var 0) $ktype)) $root))))

;; -----------------------------------------------------------------------------
;; STAGE 220–229: Level 2 Refinement Operator rho(Q1)
;; -----------------------------------------------------------------------------
;; Specializes an active Level 1 candidate into Level 2 candidates.

;; Refinement 2A: Branched on (var 0) with constant (# ctype)
;; Parent has constant in slot 2
(exec (warmr 220 ref_l1_const_to_l2_branch_const)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (const $c1))) (((var 0) $ptype)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $ptype) (# $atype2)))
     (valid_constant $atype2 $c2))
  (O (+ (raw_candidate (cand_l2 $pid $p2 $c2) 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2))) (((var 0) $ptype)) $pid))))

;; Parent has variable in slot 2
(exec (warmr 221 ref_l1_var_to_l2_branch_const)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (var 1))) (((var 0) $ptype) ((var 1) $t1)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $ptype) (# $atype2)))
     (valid_constant $atype2 $c2))
  (O (+ (raw_candidate (cand_l2 $pid $p2 $c2) 2 (($p1 (var 0) (var 1)) ($p2 (var 0) (const $c2))) (((var 0) $ptype) ((var 1) $t1)) $pid))))

;; Refinement 2B: Branched on (var 0) with fresh output variable (- otype)
;; Parent has constant: fresh var is (var 1)
(exec (warmr 222 ref_l1_const_to_l2_branch_outvar)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (const $c1))) (((var 0) $ptype)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $ptype) (- $otype2))))
  (O (+ (raw_candidate (cand_l2 $pid $p2 var1) 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (var 1))) (((var 0) $ptype) ((var 1) $otype2)) $pid))))

;; Parent has variable: fresh var is (var 2)
(exec (warmr 223 ref_l1_var_to_l2_branch_outvar)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (var 1))) (((var 0) $ptype) ((var 1) $t1)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $ptype) (- $otype2))))
  (O (+ (raw_candidate (cand_l2 $pid $p2 var2) 2 (($p1 (var 0) (var 1)) ($p2 (var 0) (var 2))) (((var 0) $ptype) ((var 1) $t1) ((var 2) $otype2)) $pid))))

;; Refinement 2C: Chained on (var 1) from parent output variable
;; Parent has output variable (var 1) matching slot 1 input type
(exec (warmr 224 ref_l1_to_l2_chain_const)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (var 1))) (((var 0) $ktype) ((var 1) $t1)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $t1) (# $atype2)))
     (valid_constant $atype2 $c2))
  (O (+ (raw_candidate (cand_l2 $pid $p2 $c2) 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (const $c2))) (((var 0) $ktype) ((var 1) $t1)) $pid))))

(exec (warmr 225 ref_l1_to_l2_chain_outvar)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (var 1))) (((var 0) $ktype) ((var 1) $t1)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $t1) (- $otype2))))
  (O (+ (raw_candidate (cand_l2 $pid $p2 var2) 2 (($p1 (var 0) (var 1)) ($p2 (var 1) (var 2))) (((var 0) $ktype) ((var 1) $t1) ((var 2) $otype2)) $pid))))

;; Refinement 2D: Unary + Unary (branched on var 0)
(exec (warmr 225 ref_l1_unary_to_l2_unary)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0))) (((var 0) $ktype)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $ktype))))
  (O (+ (raw_candidate (cand_l2 $pid $p2) 2 (($p1 (var 0)) ($p2 (var 0))) (((var 0) $ktype)) $pid))))

;; Refinement 2E: Binary + Unary chain (chains on var 1)
(exec (warmr 225 ref_l1_bin_to_l2_unary_chain)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (var 1))) (((var 0) $ktype) ((var 1) $t1)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $t1))))
  (O (+ (raw_candidate (cand_l2 $pid $p2) 2 (($p1 (var 0) (var 1)) ($p2 (var 1))) (((var 0) $ktype) ((var 1) $t1)) $pid))))

;; Refinement 2F: Ternary + Unary chain (chains on var 1)
(exec (warmr 225 ref_l1_ternary_to_l2_unary_chain)
  (, (expand_candidate $pid)
     (candidate $pid 1 (($p1 (var 0) (var 1) (const $c))) (((var 0) $ktype) ((var 1) $t1)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p2 ((+ $t1))))
  (O (+ (raw_candidate (cand_l2 $pid $p2) 2 (($p1 (var 0) (var 1) (const $c)) ($p2 (var 1))) (((var 0) $ktype) ((var 1) $t1)) $pid))))

;; -----------------------------------------------------------------------------
;; STAGE 226–229: Level 3 Refinement Operator rho(Q2)
;; -----------------------------------------------------------------------------
;; Specializes an active Level 2 candidate into Level 3 candidates.

;; Refinement 3A: Branched on (var 0) with constant (# ctype)
;; Parent has 2 constants on (var 0)
(exec (warmr 226 ref_l2_const_to_l3_branch_const)
  (, (expand_candidate $pid)
     (candidate $pid 2 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2))) (((var 0) $ptype)) $orig)
     (configured_limits (min_support $min_s) (max_length $max_l))
     (allowed_body_predicate positive_example $p3 ((+ $ptype) (# $atype3)))
     (valid_constant $atype3 $c3))
  (O (+ (raw_candidate (cand_l3 $pid $p3 $c3) 3 (($p1 (var 0) (const $c1)) ($p2 (var 0) (const $c2)) ($p3 (var 0) (const $c3))) (((var 0) $ptype)) $pid))))

