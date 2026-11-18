;; =============================================================================
;; tests/mm2-benchmark-test.metta
;; =============================================================================
;; Milestone 3 Shared MM2 Benchmark Support Test Suite (ugly-sodaDrinker)
;;
;; Validates:
;;   1. Exact key domain counting on the MM2 benchmark (isolated denominator = 20).
;;   2. All 5 Level 1 attribute candidates (human, man, woman, ugly, sodaDrinker).
;;   3. All 9 Level 2 pairwise conjunction candidates.
;;   4. Verified ground truth support counts matching the actual dataset facts.
;;   5. Exact rational relative support over the 20 benchmark people.
;;   6. Candidate evaluation isolation during multi-candidate execution.
;;   7. Atomic witness cleanup (0 orphan facts).
;; =============================================================================

;; TEST-AUX src/support-calc.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker-keys.metta

;; Initialize domain key counting
(key_domain_pending_count)

;; -----------------------------------------------------------------------------
;; 1. Level 1 Candidates
;; -----------------------------------------------------------------------------
(candidate mm2_human 1 ((Inheritance (var 0) (const human))) (((var 0) person)) root)
(candidate_pending_eval mm2_human)

(candidate mm2_man 1 ((Inheritance (var 0) (const man))) (((var 0) person)) root)
(candidate_pending_eval mm2_man)

(candidate mm2_woman 1 ((Inheritance (var 0) (const woman))) (((var 0) person)) root)
(candidate_pending_eval mm2_woman)

(candidate mm2_ugly 1 ((Inheritance (var 0) (const ugly))) (((var 0) person)) root)
(candidate_pending_eval mm2_ugly)

(candidate mm2_soda 1 ((Inheritance (var 0) (const sodaDrinker))) (((var 0) person)) root)
(candidate_pending_eval mm2_soda)

;; -----------------------------------------------------------------------------
;; 2. Level 2 Pairwise Conjunction Candidates
;; -----------------------------------------------------------------------------
(candidate mm2_human_man 2
  ((Inheritance (var 0) (const human))
   (Inheritance (var 0) (const man)))
  (((var 0) person))
  mm2_human)
(candidate_pending_eval mm2_human_man)

(candidate mm2_human_woman 2
  ((Inheritance (var 0) (const human))
   (Inheritance (var 0) (const woman)))
  (((var 0) person))
  mm2_human)
(candidate_pending_eval mm2_human_woman)

(candidate mm2_human_ugly 2
  ((Inheritance (var 0) (const human))
   (Inheritance (var 0) (const ugly)))
  (((var 0) person))
  mm2_human)
(candidate_pending_eval mm2_human_ugly)

(candidate mm2_human_soda 2
  ((Inheritance (var 0) (const human))
   (Inheritance (var 0) (const sodaDrinker)))
  (((var 0) person))
  mm2_human)
(candidate_pending_eval mm2_human_soda)

(candidate mm2_man_ugly 2
  ((Inheritance (var 0) (const man))
   (Inheritance (var 0) (const ugly)))
  (((var 0) person))
  mm2_man)
(candidate_pending_eval mm2_man_ugly)

(candidate mm2_man_soda 2
  ((Inheritance (var 0) (const man))
   (Inheritance (var 0) (const sodaDrinker)))
  (((var 0) person))
  mm2_man)
(candidate_pending_eval mm2_man_soda)

(candidate mm2_woman_ugly 2
  ((Inheritance (var 0) (const woman))
   (Inheritance (var 0) (const ugly)))
  (((var 0) person))
  mm2_woman)
(candidate_pending_eval mm2_woman_ugly)

(candidate mm2_woman_soda 2
  ((Inheritance (var 0) (const woman))
   (Inheritance (var 0) (const sodaDrinker)))
  (((var 0) person))
  mm2_woman)
(candidate_pending_eval mm2_woman_soda)

(candidate mm2_ugly_soda 2
  ((Inheritance (var 0) (const ugly))
   (Inheritance (var 0) (const sodaDrinker)))
  (((var 0) person))
  mm2_ugly)
(candidate_pending_eval mm2_ugly_soda)

;; -----------------------------------------------------------------------------
;; 3. Expected Results & Assertions
;; -----------------------------------------------------------------------------

;; Isolated Domain Total: 20 Distinct People
(EXPECTED-RESULT exp-mm2-total-keys (total_positive_keys 20))

;; Absolute Support Counts
(EXPECTED-RESULT exp-mm2-human (candidate_support mm2_human 20))
(EXPECTED-RESULT exp-mm2-man (candidate_support mm2_man 10))
(EXPECTED-RESULT exp-mm2-woman (candidate_support mm2_woman 10))
(EXPECTED-RESULT exp-mm2-ugly (candidate_support mm2_ugly 10))
(EXPECTED-RESULT exp-mm2-soda (candidate_support mm2_soda 10))

(EXPECTED-RESULT exp-mm2-h-m (candidate_support mm2_human_man 10))
(EXPECTED-RESULT exp-mm2-h-w (candidate_support mm2_human_woman 10))
(EXPECTED-RESULT exp-mm2-h-u (candidate_support mm2_human_ugly 10))
(EXPECTED-RESULT exp-mm2-h-s (candidate_support mm2_human_soda 10))
(EXPECTED-RESULT exp-mm2-m-u (candidate_support mm2_man_ugly 5))
(EXPECTED-RESULT exp-mm2-m-s (candidate_support mm2_man_soda 5))
(EXPECTED-RESULT exp-mm2-w-u (candidate_support mm2_woman_ugly 5))
(EXPECTED-RESULT exp-mm2-w-s (candidate_support mm2_woman_soda 5))
(EXPECTED-RESULT exp-mm2-u-s (candidate_support mm2_ugly_soda 5))

;; Relative Support Values (Exact Rational: count / 20)
(EXPECTED-RESULT exp-mm2-human-rel (candidate_relative_support mm2_human 20 20))
(EXPECTED-RESULT exp-mm2-man-rel (candidate_relative_support mm2_man 10 20))
(EXPECTED-RESULT exp-mm2-woman-rel (candidate_relative_support mm2_woman 10 20))
(EXPECTED-RESULT exp-mm2-ugly-rel (candidate_relative_support mm2_ugly 10 20))
(EXPECTED-RESULT exp-mm2-soda-rel (candidate_relative_support mm2_soda 10 20))

(EXPECTED-RESULT exp-mm2-h-m-rel (candidate_relative_support mm2_human_man 10 20))
(EXPECTED-RESULT exp-mm2-h-w-rel (candidate_relative_support mm2_human_woman 10 20))
(EXPECTED-RESULT exp-mm2-h-u-rel (candidate_relative_support mm2_human_ugly 10 20))
(EXPECTED-RESULT exp-mm2-h-s-rel (candidate_relative_support mm2_human_soda 10 20))
(EXPECTED-RESULT exp-mm2-m-u-rel (candidate_relative_support mm2_man_ugly 5 20))
(EXPECTED-RESULT exp-mm2-m-s-rel (candidate_relative_support mm2_man_soda 5 20))
(EXPECTED-RESULT exp-mm2-w-u-rel (candidate_relative_support mm2_woman_ugly 5 20))
(EXPECTED-RESULT exp-mm2-w-s-rel (candidate_relative_support mm2_woman_soda 5 20))
(EXPECTED-RESULT exp-mm2-u-s-rel (candidate_relative_support mm2_ugly_soda 5 20))
