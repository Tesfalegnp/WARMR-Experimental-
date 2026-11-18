;; =============================================================================
;; config/synthetic-bias.metta
;; =============================================================================
;; Declarative language bias for the synthetic gene benchmark dataset
;; (Section 8 of project specification).
;;
;; Defines:
;;   1. Target / key predicate mode (modeh)
;;   2. Allowed body predicate modes (modeb)
;;   3. Determinations (allowed body predicates for key predicate)
;;   4. Argument slot roles (+ input, - output, # constant)
;;   5. Active constant domains for '#' slots
;; =============================================================================

;; -----------------------------------------------------------------------------
;; 1. Key / Head Mode Declaration
;; -----------------------------------------------------------------------------
;; positive_example/1 with one input argument of type gene
(modeh positive_example ((+ gene)))
(mode_slot positive_example 1 (+ gene))

;; -----------------------------------------------------------------------------
;; 2. Body Mode Declarations
;; -----------------------------------------------------------------------------
;; pathway/2: argument 1 is input (+ gene), argument 2 is constant (# pathway)
(modeb pathway ((+ gene) (# pathway)))
(mode_slot pathway 1 (+ gene))
(mode_slot pathway 2 (# pathway))

;; regulates/2: argument 1 is input (+ gene), argument 2 is output (- gene)
(modeb regulates ((+ gene) (- gene)))
(mode_slot regulates 1 (+ gene))
(mode_slot regulates 2 (- gene))

;; -----------------------------------------------------------------------------
;; 3. Determinations
;; -----------------------------------------------------------------------------
;; Declares that pathway/2 and regulates/2 are permitted body predicates for
;; positive_example/1 queries.
(determination positive_example pathway)
(determination positive_example regulates)

;; -----------------------------------------------------------------------------
;; 4. Active Domain Constants for '#' Slots
;; -----------------------------------------------------------------------------
;; Constant pool for type 'pathway'
(type_constant pathway metabolism)
(type_constant pathway respiration)
