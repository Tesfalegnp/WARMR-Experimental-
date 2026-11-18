;; =============================================================================
;; config/ternary-bias.metta
;; =============================================================================
;; Language-bias configuration for ternary relational predicates.
;; =============================================================================

;; Head / Key predicate mode
(modeh positive_example ((+ account)))
(mode_slot positive_example 1 (+ account))

;; Body predicate mode (Ternary predicate: arity 3)
;; transfer(+account, -account, #bank)
(modeb transfer ((+ account) (- account) (# bank)))
(mode_slot transfer 1 (+ account))
(mode_slot transfer 2 (- account))
(mode_slot transfer 3 (# bank))

;; Determination
(determination positive_example transfer)

;; Active Domain Constants for '#' bank slot
(type_constant bank chase)
(type_constant bank citi)
(type_constant bank wells)
(type_constant bank unknown_bank)
