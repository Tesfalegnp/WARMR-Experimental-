;; =============================================================================
;; tests/bias-test.metta
;; =============================================================================
;; Milestone 2 Language-Bias Compiler Test Suite
;;
;; Verifies:
;;   1. modeh compilation, key predicate registration, and arity computation.
;;   2. modeb and determination compilation into allowed_body_predicate facts.
;;   3. Body predicate arity computation.
;;   4. Argument mode slot semantics (+ input, - output, # constant).
;;   5. Type constant registration for '#' slots.
;;   6. Search limits and thresholds validation.
;;   7. Error detection: unmapped determinations (determination with no modeb).
;;   8. Error detection: invalid mode symbols (e.g. '?').
;; =============================================================================

;; TEST-AUX src/language-bias.metta
;; TEST-AUX config/warmr-config.metta
;; TEST-AUX config/synthetic-bias.metta

;; -----------------------------------------------------------------------------
;; Negative Test Fixtures for Bias Error Detection
;; -----------------------------------------------------------------------------
;; Determination referencing an undeclared predicate with no modeb
(determination positive_example unmapped_pred)

;; Predicate with an illegal mode symbol '?'
(mode_slot invalid_pred 1 (? gene))

;; -----------------------------------------------------------------------------
;; Expected Result Assertions
;; -----------------------------------------------------------------------------
;; 1. Key / Head Mode
(EXPECTED-RESULT bias-key-pred (key_predicate positive_example))
(EXPECTED-RESULT bias-modeh-arity (modeh_arity positive_example 1))

;; 2. Allowed Body Predicates from Determinations & Modeb
(EXPECTED-RESULT bias-allowed-pathway (allowed_body_predicate positive_example pathway ((+ gene) (# pathway))))
(EXPECTED-RESULT bias-allowed-regulates (allowed_body_predicate positive_example regulates ((+ gene) (- gene))))

;; 3. Body Predicate Arities
(EXPECTED-RESULT bias-pathway-arity (predicate_arity pathway 2))
(EXPECTED-RESULT bias-regulates-arity (predicate_arity regulates 2))

;; 4. Argument Mode Slots (+ input, - output, # constant)
(EXPECTED-RESULT bias-slot-pathway-in (valid_slot pathway 1 input gene))
(EXPECTED-RESULT bias-slot-pathway-const (valid_slot pathway 2 constant pathway))
(EXPECTED-RESULT bias-slot-regulates-in (valid_slot regulates 1 input gene))
(EXPECTED-RESULT bias-slot-regulates-out (valid_slot regulates 2 output gene))

;; 5. Active Domain Constants
(EXPECTED-RESULT bias-constant-metab (valid_constant pathway metabolism))
(EXPECTED-RESULT bias-constant-resp (valid_constant pathway respiration))

;; 6. Configured Limits
(EXPECTED-RESULT bias-limits (configured_limits (min_support 2) (max_length 2)))

;; 7. Bias Errors
(EXPECTED-RESULT bias-err-unmapped (bias_error unmapped_determination unmapped_pred))
(EXPECTED-RESULT bias-err-invalid-sym (bias_error invalid_mode_symbol invalid_pred 1 ?))
