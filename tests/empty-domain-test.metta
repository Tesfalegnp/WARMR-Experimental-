;; =============================================================================
;; tests/empty-domain-test.metta
;; =============================================================================
;; Validates the behavior of the support calculator when the positive key domain
;; is empty (0 positive examples in the database).
;;
;; Expected Behavior:
;;   1. Stage 306 sets (total_positive_keys 0).
;;   2. Stage 330 fallback sets (candidate_support <qid> 0).
;;   3. Stage 325 records relative support as (candidate_relative_support <qid> 0 0),
;;      representing 0.0 relative support without division by zero.
;; =============================================================================

;; TEST-AUX src/support-calc.metta

;; Notice: Database contains background relational facts but ZERO positive_example facts!
(pathway gene_a metabolism)
(regulates gene_a gene_x)

;; Initialize key domain counting
(key_domain_pending_count)

;; Candidate query:
(candidate q_empty 2
  ((pathway (var 0) (var 1))
   (regulates (var 0) (var 2)))
  (((var 0) gene) ((var 1) pathway) ((var 2) gene))
  q1)
(candidate_pending_eval q_empty)

;; Expected Assertions
(EXPECTED-RESULT exp-empty-total (total_positive_keys 0))
(EXPECTED-RESULT exp-empty-support (candidate_support q_empty 0))
(EXPECTED-RESULT exp-empty-relative (candidate_relative_support q_empty 0 0))
