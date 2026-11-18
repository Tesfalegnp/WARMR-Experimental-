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
;; STAGE 130: Active Domain Constant Registration
;; -----------------------------------------------------------------------------
(exec (warmr 130 register_type_constants)
  (, (type_constant $type $val))
  (O (+ (valid_constant $type $val))))

;; -----------------------------------------------------------------------------
;; STAGE 140: Threshold and Limits Validation
;; -----------------------------------------------------------------------------
(exec (warmr 140 validate_thresholds)
  (, (INPUT MIN_SUPPORT $min_sup)
     (INPUT MAX_LENGTH $max_len))
  (O (+ (configured_limits (min_support $min_sup) (max_length $max_len)))))
