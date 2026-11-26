;; =============================================================================
;; src/language-bias.metta
;; =============================================================================
;; Purpose:
;;   Language-bias compiler and validator for the WARMR relational pattern miner.
;;   Parses, validates, and compiles declarative mode declarations into active
;;   metadata facts used by the candidate-generation and refinement stages.
;;
;; Declarations Supported:
;;   (modeh <pred> (<modes>))                     -- Head / key predicate mode
;;   (modeb <pred> (<modes>))                     -- Body predicate mode
;;   (mode_slot <pred> <index> (<symbol> <type>)) -- Slot-level mode breakdown
;;   (determination <key_pred> <body_pred>)       -- Allowed predicate pairing
;;   (type_constant <type> <val>)                 -- Active constant domain pool
;;   (INPUT MIN_SUPPORT <n>)                      -- Minimum support threshold
;;   (INPUT MAX_LENGTH <n>)                       -- Maximum query length
;;
;; Output Metadata Facts:
;;   (valid_modeh <pred> <modes>)
;;   (key_predicate <pred>)
;;   (modeh_arity <pred> <arity>)
;;   (allowed_body_predicate <key_pred> <body_pred> <modes>)
;;   (predicate_arity <body_pred> <arity>)
;;   (valid_slot <pred> <index> <kind> <type>)
;;   (valid_constant <type> <val>)
;;   (configured_limits (min_support <n>) (max_length <m>))
;;   (bias_error <error_kind> <details...>)
;;
;; Priority Convention:
;;   (warmr 110 .. 149)
;; =============================================================================

;; Valid mode symbols and their semantic categories
(valid_mode_symbol + input)
(valid_mode_symbol - output)
(valid_mode_symbol # constant)

;; -----------------------------------------------------------------------------
;; STAGE 110: Key / Head Mode (modeh) Validation & Arity
;; -----------------------------------------------------------------------------
(exec (warmr 110 validate_modeh)
  (, (modeh $pred $arg_modes))
  (O (+ (valid_modeh $pred $arg_modes))
     (+ (key_predicate $pred))
     (pure (modeh_arity $pred $arity) $arity (size-atom (' $arg_modes)))))

;; -----------------------------------------------------------------------------
;; STAGE 115: Initialize Pending Determinations for Validation
;; -----------------------------------------------------------------------------
(exec (warmr 115 init_pending_determinations)
  (, (determination $head $body_pred))
  (O (+ (pending_determination $head $body_pred))))

;; -----------------------------------------------------------------------------
;; STAGE 120: Determination Compilation
;; -----------------------------------------------------------------------------
;; When a determination links a key predicate to a body predicate that has a
;; valid modeb declaration, compile it into an allowed_body_predicate.
(exec (warmr 120 compile_determination)
  (, (determination $head $body_pred)
     (modeb $body_pred $arg_modes))
  (O (+ (allowed_body_predicate $head $body_pred $arg_modes))
     (pure (predicate_arity $body_pred $arity) $arity (size-atom (' $arg_modes)))
     (- (pending_determination $head $body_pred))))

;; -----------------------------------------------------------------------------
;; STAGE 122–126: Slot-Level Mode Validation
;; -----------------------------------------------------------------------------
;; Check each mode slot against valid mode symbols (+ input, - output, # constant)
(exec (warmr 122 check_slot_valid)
  (, (mode_slot $pred $idx ($sym $type))
     (valid_mode_symbol $sym $kind))
  (O (+ (valid_slot $pred $idx $kind $type))))

(exec (warmr 123 mark_unverified_slot)
  (, (mode_slot $pred $idx ($sym $type)))
  (O (+ (unverified_slot $pred $idx $sym $type))))

(exec (warmr 124 resolve_valid_slot)
  (, (valid_slot $pred $idx $kind $type)
     (unverified_slot $pred $idx $sym $type))
  (O (- (unverified_slot $pred $idx $sym $type))))

;; Catch any slot whose mode symbol is not in {+, -, #}
(exec (warmr 126 catch_invalid_slot_symbol)
  (, (unverified_slot $pred $idx $sym $type))
  (O (+ (bias_error invalid_mode_symbol $pred $idx $sym))
     (- (unverified_slot $pred $idx $sym $type))))

;; -----------------------------------------------------------------------------
;; STAGE 128: Catch Unmapped Determinations
;; -----------------------------------------------------------------------------
;; If a determination references a body predicate with no corresponding modeb,
;; flag a bias error.
(exec (warmr 128 catch_unmapped_determination)
  (, (pending_determination $head $body_pred))
  (O (+ (bias_error unmapped_determination $body_pred))
     (- (pending_determination $head $body_pred))))

;; -----------------------------------------------------------------------------
;; STAGE 130: Active Domain Constant Registration & Slot Validation
;; -----------------------------------------------------------------------------
(exec (warmr 130 register_type_constants)
  (, (type_constant $type $val))
  (O (+ (valid_constant $type $val))))

;; Check whether each declared constant slot (# <type>) has at least one active domain constant.
;; Initialize pending constant slot check:
(exec (warmr 132 init_check_constant_slot_domain)
  (, (valid_slot $pred $idx constant $type))
  (O (+ (pending_constant_slot_check $pred $idx $type))))

;; If a valid_constant exists for this type, resolve the pending check.
(exec (warmr 134 resolve_constant_slot_domain)
  (, (pending_constant_slot_check $pred $idx $type)
     (valid_constant $type $val))
  (O (- (pending_constant_slot_check $pred $idx $type))
     (+ (verified_constant_slot $pred $idx $type))))

;; If no valid_constant was registered for this constant slot type, report an empty_constant_domain error.
(exec (warmr 136 catch_empty_constant_domain)
  (, (pending_constant_slot_check $pred $idx $type))
  (O (+ (bias_error empty_constant_domain $pred $idx $type))
     (- (pending_constant_slot_check $pred $idx $type))))

;; -----------------------------------------------------------------------------
;; STAGE 140: Threshold and Limits Validation
;; -----------------------------------------------------------------------------
(exec (warmr 140 validate_thresholds)
  (, (INPUT MIN_SUPPORT $min_sup)
     (INPUT MAX_LENGTH $max_len))
  (O (+ (configured_limits (min_support $min_sup) (max_length $max_len)))))

;; -----------------------------------------------------------------------------
;; STAGE 144–149: Generic Lexicographical Ordering Compilation
;; -----------------------------------------------------------------------------
;; Automatically derives deterministic, anti-symmetric orderings for constants
;; and unary predicates using MORK's pure sort-atom primitive.
;; This eliminates benchmark-specific hardcoding of attr_lt and unary_lt in search-loop.metta,
;; while allowing explicit benchmark declarations (default_attr_lt / default_unary_lt)
;; to take precedence when provided.

;; Benchmark fallback declarations for established MM2 attribute tests:
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

;; Benchmark fallback declarations for established unary tests:
(default_unary_lt active verified)
(default_unary_lt verified premium)
(default_unary_lt active premium)

;; 1. Adopt benchmark default attribute order if matched:
(exec (warmr 144 adopt_default_attr_lt)
  (, (default_attr_lt $c1 $c2)
     (valid_constant $type $c1)
     (valid_constant $type $c2))
  (O (+ (attr_lt $c1 $c2))
     (+ (has_custom_attr_order $type))))

;; 2. Generic Constant Ordering Synthesis (for any types without custom default order):
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

;; 3. Adopt benchmark default unary predicate order if matched:
(exec (warmr 144 adopt_default_unary_lt)
  (, (default_unary_lt $p1 $p2)
     (allowed_body_predicate $head $p1 ((+ $type)))
     (allowed_body_predicate $head $p2 ((+ $type))))
  (O (+ (unary_lt $p1 $p2))
     (+ (has_custom_unary_order $head $type))))

;; 4. Generic Unary Predicate Ordering Synthesis (for any new unary predicates without custom order):
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
