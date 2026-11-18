;; =============================================================================
;; benchmarks/events-4ary.metta
;; =============================================================================
;; Relational Knowledge Base: 4-Ary Audit Logs (User, Action, Device, Status)
;; =============================================================================

;; usr1: multi-proof (2 successful events)
(audit_log usr1 login mobile success)
(audit_log usr1 query web success)

;; usr2: 1 success, 1 failure
(audit_log usr2 login mobile success)
(audit_log usr2 query mobile failure)

;; usr3: 1 success
(audit_log usr3 login web success)

;; usr4: 1 failure
(audit_log usr4 login mobile failure)

;; usr5: 1 success
(audit_log usr5 logout web success)
