;; =============================================================================
;; config/deep-chain-bias.metta
;; =============================================================================
;; Language-bias configuration for deep relational chaining (up to length 5).
;; =============================================================================

;; Head / Key predicate mode
(modeh positive_example ((+ node)))
(mode_slot positive_example 1 (+ node))

;; Body predicate mode (Binary relation: step(+node, -node))
(modeb step ((+ node) (- node)))
(mode_slot step 1 (+ node))
(mode_slot step 2 (- node))

;; Determination
(determination positive_example step)
