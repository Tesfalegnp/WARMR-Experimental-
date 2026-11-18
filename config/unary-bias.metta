;; =============================================================================
;; config/unary-bias.metta
;; =============================================================================
;; Language-bias configuration for unary relational predicates.
;; =============================================================================

;; Head / Key predicate mode
(modeh positive_example ((+ user)))
(mode_slot positive_example 1 (+ user))

;; Body predicate modes (Unary predicates: arity 1)
(modeb active ((+ user)))
(mode_slot active 1 (+ user))

(modeb verified ((+ user)))
(mode_slot verified 1 (+ user))

(modeb premium ((+ user)))
(mode_slot premium 1 (+ user))

;; Determinations
(determination positive_example active)
(determination positive_example verified)
(determination positive_example premium)

;; Ordering for candidate canonicalization
(unary_lt active verified)
(unary_lt verified premium)
(unary_lt active premium)
