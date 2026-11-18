;; =============================================================================
;; config/family-bias.metta
;; =============================================================================
;; Declarative language bias configuration for the family relational dataset.
;;
;; Defines:
;;   1. Target / key predicate mode (modeh): positive_example(+person)
;;   2. Body predicate mode (modeb): parent(+person, -person)
;;   3. Determination: parent is a permitted body relation for positive_example
;;   4. Argument slot roles: slot 1 is input person (+), slot 2 is output person (-)
;; =============================================================================

;; Head / Key Predicate: positive_example/1
(modeh positive_example ((+ person)))
(mode_slot positive_example 1 (+ person))

;; Body Predicate: parent/2 (arg 1 is input person, arg 2 is output fresh person variable)
(modeb parent ((+ person) (- person)))
(mode_slot parent 1 (+ person))
(mode_slot parent 2 (- person))

;; Determination: parent/2 is a permitted body relation for positive_example
(determination positive_example parent)
