;; =============================================================================
;; config/events-4ary-bias.metta
;; =============================================================================
;; Language-bias configuration for 4-ary relational predicates.
;; =============================================================================

;; Head / Key predicate mode
(modeh positive_example ((+ user)))
(mode_slot positive_example 1 (+ user))

;; Body predicate mode (4-Ary predicate: arity 4)
;; audit_log(+user, #action, #device, #status)
(modeb audit_log ((+ user) (# action) (# device) (# status)))
(mode_slot audit_log 1 (+ user))
(mode_slot audit_log 2 (# action))
(mode_slot audit_log 3 (# device))
(mode_slot audit_log 4 (# status))

;; Determination
(determination positive_example audit_log)

;; Active Domain Constants
(type_constant action login)
(type_constant action query)
(type_constant action logout)
(type_constant action transfer)

(type_constant device mobile)
(type_constant device web)

(type_constant status success)
(type_constant status failure)
