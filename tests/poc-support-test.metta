;; =============================================================================
;; tests/poc-support-test.metta
;; =============================================================================
;; Milestone 1 Technical Proof-of-Concept Gate
;;
;; Validates the foundational WARMR support-calculation mechanism in MORK:
;;   1. Loading positive key examples and relational facts.
;;   2. Representing candidate queries with variable and constant slots.
;;   3. Executing candidate queries against relational facts.
;;   4. Projecting successful substitutions onto the key variable.
;;   5. Deduplicating key witnesses in the AtomSpace (multiple proofs -> 1 key).
;;   6. Counting distinct key witnesses via the count sink.
;;   7. Handling zero-support candidates safely.
;;   8. Cleaning up temporary witness facts.
;; =============================================================================

;; TEST-AUX src/data-model.metta

;; -----------------------------------------------------------------------------
;; 1. Positive Examples (Key Domain)
;; -----------------------------------------------------------------------------
(positive_example gene_a)
(positive_example gene_b)
(positive_example gene_c)

;; -----------------------------------------------------------------------------
;; 2. Background Knowledge (Relational Facts)
;; -----------------------------------------------------------------------------
;; gene_a has 3 distinct pathways
(pathway gene_a metabolism)
(pathway gene_a energy)
(pathway gene_a signaling)

;; gene_b has 1 pathway
(pathway gene_b metabolism)

;; gene_c has 0 pathways

;; -----------------------------------------------------------------------------
;; 3. Candidate Queries
;; -----------------------------------------------------------------------------
;; Candidate q1: positive_example(A), pathway(A, P)
;; Evaluates over free variable (var 1).
;; gene_a matches 3 times -> projects to 1 distinct key witness.
;; gene_b matches 1 time  -> projects to 1 distinct key witness.
;; gene_c matches 0 times -> 0 witnesses.
;; Total substitutions = 4; Expected distinct key support = 2.
(candidate q1 1 (pathway (var 0) (var 1)))
(candidate_pending_eval q1)

;; Candidate q_zero: positive_example(A), pathway(A, respiration)
;; Evaluates with constant respiration in slot 2.
;; No positive example has pathway respiration.
;; Expected distinct key support = 0.
(candidate q_zero 1 (pathway (var 0) (const respiration)))
(candidate_pending_eval q_zero)

;; -----------------------------------------------------------------------------
;; 4. Expected Results (Verification Invariants)
;; -----------------------------------------------------------------------------
(EXPECTED-RESULT poc-distinct-support (candidate_support q1 2))
(EXPECTED-RESULT poc-zero-support (candidate_support q_zero 0))
