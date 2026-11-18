;; =============================================================================
;; benchmarks/deep-chain.metta
;; =============================================================================
;; Relational Knowledge Base: Deep Relational Chain (5 Hops)
;; Supports testing clause conjunction lengths up to k = 5.
;; =============================================================================

;; Primary chain from n0 through n5
(step n0 n1)
(step n1 n2)
(step n2 n3)
(step n3 n4)
(step n4 n5)

;; Alternate path from n0 creating multi-proof for n0 at length 5
(step n0 n1_alt)
(step n1_alt n2)
