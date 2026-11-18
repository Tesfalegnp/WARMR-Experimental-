;; =============================================================================
;; benchmarks/ternary-transactions.metta
;; =============================================================================
;; Relational Knowledge Base: Ternary Transactions (Sender, Receiver, Bank)
;; =============================================================================

;; Multi-proof for acc1 (2 transfers through chase)
(transfer acc1 acc2 chase)
(transfer acc1 acc3 chase)

;; acc2 transfers through chase
(transfer acc2 acc4 chase)

;; acc3 and acc4 transfer through citi
(transfer acc3 acc5 citi)
(transfer acc4 acc6 citi)

;; acc5 transfers through wells
(transfer acc5 acc6 wells)

;; acc6 has 0 outgoing transfers
