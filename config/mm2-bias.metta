;; =============================================================================
;; config/mm2-bias.metta
;; =============================================================================
;; Declarative language bias configuration for the shared MM2 ugly-sodaDrinker
;; benchmark dataset.
;;
;; Defines:
;;   1. Target / key predicate mode (modeh)
;;   2. Body predicate mode (modeb)
;;   3. Determination
;;   4. Argument slot roles (+ input, # constant)
;;   5. Active constant domain for attribute values
;; =============================================================================

;; Head / Key Predicate: positive_example/1
(modeh positive_example ((+ person)))
(mode_slot positive_example 1 (+ person))

;; Body Predicate: Inheritance/2 (arg 1 is input person, arg 2 is constant attribute)
(modeb Inheritance ((+ person) (# attribute)))
(mode_slot Inheritance 1 (+ person))
(mode_slot Inheritance 2 (# attribute))

;; Determination: Inheritance is a permitted body relation for positive_example
(determination positive_example Inheritance)

;; Active Domain Constants for '#' attribute slot
(type_constant attribute human)
(type_constant attribute man)
(type_constant attribute woman)
(type_constant attribute ugly)
(type_constant attribute sodaDrinker)
