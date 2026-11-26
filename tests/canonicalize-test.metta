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
;;   Case D — Duplicate literal elimination (tautology idempotence):
;;     ((Inheritance (var 0) man) (Inheritance (var 0) man))
;;     normalizes to ((Inheritance (var 0) man)).
;;
;;   Case E — Constant distinction:
;;     ((Inheritance (var 0) man)) and ((Inheritance (var 0) woman))
;;     remain strictly distinct in canonical pools.
;;
;;   Case F — Predicate argument order preservation:
;;     ((parent (var 0) (var 1))) != ((parent (var 1) (var 0)))
;;
;;   Case G — Repeated variable constraint distinction:
;;     ((related (var 0) (var 0))) != ((related (var 0) (var 1)))
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

;; Query 5: Duplicate literal idempotence (Case D)
(canonicalize_query q5_dup ((Inheritance (var 0) man) (Inheritance (var 0) man)))

;; Query 6: Constant distinction (Case E)
(canonicalize_query q6_man ((Inheritance (var 0) man)))
(canonicalize_query q6_woman ((Inheritance (var 0) woman)))

;; Query 7: Predicate argument order preservation (Case F)
(canonicalize_query q7_forward ((parent (var 0) (var 1))))
(canonicalize_query q7_backward ((parent (var 1) (var 0))))

;; Query 8: Repeated variable constraint (Case G: related(X,X) vs related(X,Y))
(canonicalize_query q8_reflexive ((related (var 0) (var 0))))
(canonicalize_query q8_irreflexive ((related (var 0) (var 1))))

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

;; Raw candidate with duplicate literals
(raw_candidate c_dup 2
  ((Inheritance (var 0) man) (Inheritance (var 0) man))
  (((var 0) person))
  root)

;; -----------------------------------------------------------------------------
;; 3. Expected Result Assertions
;; -----------------------------------------------------------------------------

;; Case A & Case B: q1, q2, q3 all produce the identical canonical representation
(EXPECTED-RESULT canon-q1 (canonical_query_result q1 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
(EXPECTED-RESULT canon-q2 (canonical_query_result q2 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
(EXPECTED-RESULT canon-q3 (canonical_query_result q3 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))

;; Case C: q4 preserves different variable relationship (distinct from q1)
(EXPECTED-RESULT canon-q4 (canonical_query_result q4 ((Inheritance (var 0) man) (Inheritance (var 1) ugly))))

;; Case D: q5_dup normalizes to single literal
(EXPECTED-RESULT canon-q5-dup (canonical_query_result q5_dup ((Inheritance (var 0) man))))

;; Case E: Constants remain distinct
(EXPECTED-RESULT canon-q6-man (canonical_query_result q6_man ((Inheritance (var 0) man))))
(EXPECTED-RESULT canon-q6-woman (canonical_query_result q6_woman ((Inheritance (var 0) woman))))

;; Case F: Argument order preserved
(EXPECTED-RESULT canon-q7-fwd (canonical_query_result q7_forward ((parent (var 0) (var 1)))))
(EXPECTED-RESULT canon-q7-bwd (canonical_query_result q7_backward ((parent (var 0) (var 1)))))

;; Case G: Repeated variable equality preserved
(EXPECTED-RESULT canon-q8-refl (canonical_query_result q8_reflexive ((related (var 0) (var 0)))))
(EXPECTED-RESULT canon-q8-irrefl (canonical_query_result q8_irreflexive ((related (var 0) (var 1)))))

;; Candidate Pool Deduplication:
;; Canonical forms in candidate_pool must contain exactly 1 entry for the shared form
(EXPECTED-RESULT pool-shared (canonical_pool ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
(EXPECTED-RESULT pool-distinct (canonical_pool ((Inheritance (var 0) man) (Inheritance (var 1) ugly))))
(EXPECTED-RESULT pool-man (canonical_pool ((Inheritance (var 0) man))))
(EXPECTED-RESULT pool-woman (canonical_pool ((Inheritance (var 0) woman))))
(EXPECTED-RESULT pool-refl (canonical_pool ((related (var 0) (var 0)))))
(EXPECTED-RESULT pool-irrefl (canonical_pool ((related (var 0) (var 1)))))

;; Pipeline Canonical Candidate Deduplication
(EXPECTED-RESULT pool-pipe (candidate_pool 2 ((Inheritance (var 0) man) (Inheritance (var 0) ugly))))
(EXPECTED-RESULT pool-pipe-dup (candidate_pool 1 ((Inheritance (var 0) man))))
