;; =============================================================================
;; tests/synthetic-test.metta
;; =============================================================================
;; Milestone 6 Synthetic Gene Pipeline & Multi-Proof Regression Test
;;
;; Verifies:
;;   1. Key-domain total counting (N=3 distinct genes: gene_a, gene_b, gene_c).
;;   2. One-literal support calculation (pathway and regulates).
;;   3. Multi-proof collapsing: gene_a produces 6 distinct substitution proofs
;;      for pathway(A, P) ∧ regulates(A, G), but collapses into exactly 1 witness.
;;   4. Relational chaining: regulates(A, B) ∧ pathway(B, metabolism) connects
;;      via shared intermediate variable (var 1) with exact support = 1.
;;   5. Rational relative support (counts against isolated denominator = 3).
;;   6. Anti-monotonic pruning: zero-support candidates produce prune_branch markers.
;;   7. Structured output formatting via output.metta.
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX src/pruning.metta
;; TEST-AUX src/output.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Dataset Tagging
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 2)
(INPUT MAX_LENGTH 2)
(INPUT DATASET_ID synthetic_genes)
(configured_limits (min_support 2) (max_length 2))

;; -----------------------------------------------------------------------------
;; 2. Isolated Positive Key Domain (N = 3)
;; -----------------------------------------------------------------------------
(positive_example gene_a)
(positive_example gene_b)
(positive_example gene_c)

;; Initialize domain key counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 3. Background Relational Knowledge
;; -----------------------------------------------------------------------------
;; gene_a has 3 pathways; gene_b has 1 pathway; gene_c has 0 pathways
(pathway gene_a metabolism)
(pathway gene_a energy)
(pathway gene_a signaling)
(pathway gene_b metabolism)

;; gene_a regulates 2 genes; gene_b regulates 1 gene
(regulates gene_a gene_x)
(regulates gene_a gene_y)
(regulates gene_b gene_z)

;; gene_x has pathway metabolism (enables 2-literal chain from gene_a)
(pathway gene_x metabolism)

;; -----------------------------------------------------------------------------
;; 4. Evaluated Candidates
;; -----------------------------------------------------------------------------
;; Q1: One-literal variable candidate: pathway(A, P)
(candidate q1 1 ((pathway (var 0) (var 1))) (((var 0) gene) ((var 1) pathway)) root)
(candidate_pending_eval q1)

;; Q2: Two-literal multi-proof conjunction: pathway(A, P) ∧ regulates(A, G)
;; gene_a matches 3 pathways * 2 targets = 6 substitutions -> 1 key witness.
;; gene_b matches 1 pathway * 1 target = 1 substitution -> 1 key witness.
;; Expected distinct key support = 2.
(candidate q2 2
  ((pathway (var 0) (var 1)) (regulates (var 0) (var 2)))
  (((var 0) gene) ((var 1) pathway) ((var 2) gene))
  q1)
(candidate_pending_eval q2)

;; Q_chain: Two-literal chained conjunction: regulates(A, B) ∧ pathway(B, metabolism)
;; gene_a regulates gene_x which has pathway metabolism -> matches gene_a (1 key witness).
;; Expected distinct key support = 1.
(candidate q_chain 2
  ((regulates (var 0) (var 1)) (pathway (var 1) (const metabolism)))
  (((var 0) gene) ((var 1) gene))
  q_reg)
(candidate_pending_eval q_chain)

;; Q_zero: Zero-support candidate: pathway(A, respiration)
(candidate q_zero 1
  ((pathway (var 0) (const respiration)))
  (((var 0) gene))
  root)
(candidate_pending_eval q_zero)

;; -----------------------------------------------------------------------------
;; 5. Expected Result Assertions
;; -----------------------------------------------------------------------------
;; Key domain counting (N=3)
(EXPECTED-RESULT syn-total-keys (total_positive_keys 3))

;; Support calculations
(EXPECTED-RESULT syn-q1-supp (candidate_support q1 2))
(EXPECTED-RESULT syn-q2-supp (candidate_support q2 2))
(EXPECTED-RESULT syn-chain-supp (candidate_support q_chain 1))
(EXPECTED-RESULT syn-zero-supp (candidate_support q_zero 0))

;; Relative support calculations (numerator / denominator)
(EXPECTED-RESULT syn-q1-rel (candidate_relative_support q1 2 3))
(EXPECTED-RESULT syn-q2-rel (candidate_relative_support q2 2 3))
(EXPECTED-RESULT syn-chain-rel (candidate_relative_support q_chain 1 3))
(EXPECTED-RESULT syn-zero-rel (candidate_relative_support q_zero 0 3))

;; Classification & Pruning
(EXPECTED-RESULT syn-q1-freq (candidate_frequent q1 2))
(EXPECTED-RESULT syn-q2-freq (candidate_frequent q2 2))
(EXPECTED-RESULT syn-chain-infreq (candidate_infrequent q_chain 1))
(EXPECTED-RESULT syn-zero-prune (prune_branch q_zero))

;; Structured output records for frequent patterns
(EXPECTED-RESULT syn-out-q1
  (warmr_pattern
    (id q1)
    (length 1)
    (body ((pathway (var 0) (var 1))))
    (absolute_support 2)
    (relative_support 2 3)
    (classification frequent)
    (dataset synthetic_genes)
    (min_support 2)))

(EXPECTED-RESULT syn-out-q2
  (warmr_pattern
    (id q2)
    (length 2)
    (body ((pathway (var 0) (var 1)) (regulates (var 0) (var 2))))
    (absolute_support 2)
    (relative_support 2 3)
    (classification frequent)
    (dataset synthetic_genes)
    (min_support 2)))
