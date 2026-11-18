;; =============================================================================
;; tests/canonicalize-test.metta
;; =============================================================================
;; Milestone 4 Canonicalization Test Suite
;;
;; Verifies:
;;   Case A — Atom-order equivalence (conjunction commutativity):
;;     ((Inheritance (var 0) man) (Inheritance (var 0) ugly))
;;     and
;;     ((Inheritance (var 0) ugly) (Inheritance (var 0) man))
;;     produce identical canonical forms.
;;
;;   Case B — Alpha-renaming equivalence (variable renaming):
;;     ((Inheritance (var 0) man) (Inheritance (var 0) ugly))
;;     and
;;     ((Inheritance (var 5) ugly) (Inheritance (var 5) man))
;;     produce identical canonical forms.
;;
;;   Case C — Preservation of distinct variable relationships:
;;     ((Inheritance (var 0) man) (Inheritance (var 0) ugly))  [shared variable (var 0)]
;;     and
;;     ((Inheritance (var 0) man) (Inheritance (var 1) ugly))  [independent variables (var 0), (var 1)]
;;     must NOT become identical.
;;
;;   Duplicate Candidate Prevention:
;;     Inserting equivalent canonical forms into candidate_pool collapses them
;;     into exactly 1 unique pool entry via AtomSpace set semantics.
;; =============================================================================

;; TEST-AUX src/canonicalize.metta

;; -----------------------------------------------------------------------------
;; 1. Input Test Queries
;; -----------------------------------------------------------------------------

;; Query 1: Baseline order
(canonicalize_query q1 ((Inheritance (var 0) man) (Inheritance (var 0) ugly)))

;; Query 2: Reversed literal order (Case A: atom-order equivalence)
(canonicalize_query q2 ((Inheritance (var 0) ugly) (Inheritance (var 0) man)))

;; Query 3: Renamed variable (var 5) + reversed order (Case B: alpha-renaming equivalence)
(canonicalize_query q3 ((Inheritance (var 5) ugly) (Inheritance (var 5) man)))

;; Query 4: Distinct variable relationship (Case C: independent variables)
(canonicalize_query q4 ((Inheritance (var 0) man) (Inheritance (var 1) ugly)))

;; -----------------------------------------------------------------------------
;; 2. Raw Candidate Pipeline Input (Testing Candidate Pipeline Integration)
;; -----------------------------------------------------------------------------
(raw_candidate c_man_ugly 2
  ((Inheritance (var 0) ugly) (Inheritance (var 0) man))
  (((var 0) person))
  c_man)

(raw_candidate c_ugly_man 2
  ((Inheritance (var 0) man) (Inheritance (var 0) ugly))
  (((var 0) person))
  c_ugly)

;; -----------------------------------------------------------------------------
;; 3. Expected Result Assertions
;; -----------------------------------------------------------------------------

;; Case A & Case B: q1, q2, q3 all produce the identical canonical representation
(EXPECTED-RESULT canon-q1 (canonical_query_result q1 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
(EXPECTED-RESULT canon-q2 (canonical_query_result q2 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
(EXPECTED-RESULT canon-q3 (canonical_query_result q3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))

;; Case C: q4 preserves different variable relationship (distinct from q1)
(EXPECTED-RESULT canon-q4 (canonical_query_result q4 ((Inheritance (var 0) man) (Inheritance (var 1) ugly))))

;; Candidate Pool Deduplication:
;; Canonical forms in candidate_pool must contain exactly 1 entry for the shared form
(EXPECTED-RESULT pool-shared (canonical_pool ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
(EXPECTED-RESULT pool-distinct (canonical_pool ((Inheritance (var 0) man) (Inheritance (var 1) ugly))))

;; Pipeline Canonical Candidate Deduplication
(EXPECTED-RESULT pool-pipe (candidate_pool 2 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
