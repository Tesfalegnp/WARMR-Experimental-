;; =============================================================================
;; tests/bias-test.metta
;; =============================================================================
;; Milestone 2 Language-Bias Compiler Test Suite
;;
;; Verifies:
;;   1. modeh compilation, key predicate registration, and arity computation.
;;   2. modeb and determination compilation into allowed_body_predicate facts.
;;   3. Body predicate arity computation across arities 1, 2, 3, and 4.
;;   4. Argument mode slot semantics (+ input, - output, # constant).
;;   5. Type constant registration for '#' slots.
;;   6. Search limits and thresholds validation.
;;   7. Error detection: unmapped determinations (determination with no modeb).
;;   8. Error detection: invalid mode symbols (e.g. '?').
;;   9. Error detection: constant slot with empty active domain.
;;   10. Multi-arity predicate mode compilation (unary, binary, ternary, 4-ary).
;; =============================================================================

;; TEST-AUX src/language-bias.metta
;; TEST-AUX config/warmr-config.metta
;; TEST-AUX config/synthetic-bias.metta

;; -----------------------------------------------------------------------------
;; Additional Multi-Arity Fixtures (Unary, Ternary, 4-ary)
;; -----------------------------------------------------------------------------
;; Unary body predicate (arity 1)
(modeb active ((+ gene)))
(mode_slot active 1 (+ gene))
(determination positive_example active)

;; Ternary body predicate (arity 3)
(modeb transfer ((+ gene) (- gene) (# bank)))
(mode_slot transfer 1 (+ gene))
(mode_slot transfer 2 (- gene))
(mode_slot transfer 3 (# bank))
(determination positive_example transfer)
(type_constant bank chase)

;; 4-Ary body predicate (arity 4)
(modeb audit_log ((+ gene) (# action) (# device) (# status)))
(mode_slot audit_log 1 (+ gene))
(mode_slot audit_log 2 (# action))
(mode_slot audit_log 3 (# device))
(mode_slot audit_log 4 (# status))
(determination positive_example audit_log)
(type_constant action login)
(type_constant device web)
(type_constant status success)

;; -----------------------------------------------------------------------------
;; Negative Test Fixtures for Bias Error Detection
;; -----------------------------------------------------------------------------
;; Determination referencing an undeclared predicate with no modeb
(determination positive_example unmapped_pred)

;; Predicate with an illegal mode symbol '?'
(mode_slot invalid_pred 1 (? gene))

;; Predicate with constant slot but missing type_constant definitions
(modeb orphan_pred ((+ gene) (# missing_type)))
(mode_slot orphan_pred 1 (+ gene))
(mode_slot orphan_pred 2 (# missing_type))
(determination positive_example orphan_pred)

;; -----------------------------------------------------------------------------
;; Expected Result Assertions
;; -----------------------------------------------------------------------------
;; 1. Key / Head Mode
(EXPECTED-RESULT bias-key-pred (key_predicate positive_example))
(EXPECTED-RESULT bias-modeh-arity (modeh_arity positive_example 1))

;; 2. Allowed Body Predicates from Determinations & Modeb (Multi-Arity 1, 2, 3, 4)
(EXPECTED-RESULT bias-allowed-active (allowed_body_predicate positive_example active ((+ gene))))
(EXPECTED-RESULT bias-allowed-pathway (allowed_body_predicate positive_example pathway ((+ gene) (# pathway))))
(EXPECTED-RESULT bias-allowed-regulates (allowed_body_predicate positive_example regulates ((+ gene) (- gene))))
(EXPECTED-RESULT bias-allowed-transfer (allowed_body_predicate positive_example transfer ((+ gene) (- gene) (# bank))))
(EXPECTED-RESULT bias-allowed-audit (allowed_body_predicate positive_example audit_log ((+ gene) (# action) (# device) (# status))))

;; 3. Body Predicate Arities across 1, 2, 3, 4
(EXPECTED-RESULT bias-active-arity (predicate_arity active 1))
(EXPECTED-RESULT bias-pathway-arity (predicate_arity pathway 2))
(EXPECTED-RESULT bias-regulates-arity (predicate_arity regulates 2))
(EXPECTED-RESULT bias-transfer-arity (predicate_arity transfer 3))
(EXPECTED-RESULT bias-audit-arity (predicate_arity audit_log 4))

;; 4. Argument Mode Slots (+ input, - output, # constant)
(EXPECTED-RESULT bias-slot-active-in (valid_slot active 1 input gene))
(EXPECTED-RESULT bias-slot-pathway-in (valid_slot pathway 1 input gene))
(EXPECTED-RESULT bias-slot-pathway-const (valid_slot pathway 2 constant pathway))
(EXPECTED-RESULT bias-slot-regulates-in (valid_slot regulates 1 input gene))
(EXPECTED-RESULT bias-slot-regulates-out (valid_slot regulates 2 output gene))
(EXPECTED-RESULT bias-slot-transfer-in (valid_slot transfer 1 input gene))
(EXPECTED-RESULT bias-slot-transfer-out (valid_slot transfer 2 output gene))
(EXPECTED-RESULT bias-slot-transfer-const (valid_slot transfer 3 constant bank))
(EXPECTED-RESULT bias-slot-audit-in (valid_slot audit_log 1 input gene))
(EXPECTED-RESULT bias-slot-audit-action (valid_slot audit_log 2 constant action))
(EXPECTED-RESULT bias-slot-audit-device (valid_slot audit_log 3 constant device))
(EXPECTED-RESULT bias-slot-audit-status (valid_slot audit_log 4 constant status))

;; 5. Active Domain Constants
(EXPECTED-RESULT bias-constant-metab (valid_constant pathway metabolism))
(EXPECTED-RESULT bias-constant-resp (valid_constant pathway respiration))
(EXPECTED-RESULT bias-constant-bank (valid_constant bank chase))
(EXPECTED-RESULT bias-constant-action (valid_constant action login))
(EXPECTED-RESULT bias-constant-device (valid_constant device web))
(EXPECTED-RESULT bias-constant-status (valid_constant status success))

;; 6. Configured Limits
(EXPECTED-RESULT bias-limits (configured_limits (min_support 2) (max_length 2)))

;; 7. Bias Errors
(EXPECTED-RESULT bias-err-unmapped (bias_error unmapped_determination unmapped_pred))
(EXPECTED-RESULT bias-err-invalid-sym (bias_error invalid_mode_symbol invalid_pred 1 ?))
(EXPECTED-RESULT bias-err-empty-domain (bias_error empty_constant_domain orphan_pred 2 missing_type))
