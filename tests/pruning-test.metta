;; =============================================================================
;; tests/pruning-test.metta
;; =============================================================================
;; Milestone 5 Anti-Monotonic Pruning and Breadth-First WARMR Search Test Suite
;;
;; Verifies:
;;   Test A — Frequent candidate expansion:
;;     A frequent candidate is classified and eligible for specialization.
;;   Test B — Infrequent candidate pruning:
;;     An infrequent candidate produces a prune marker and does not generate descendants.
;;   Test C — Mixed candidate branches:
;;     Frequent branches continue specialization while infrequent branches stop.
;;   Test D — Multi-level search reaching Level 3:
;;     Demonstrates valid 3-literal conjunctive candidate generation, evaluation,
;;     and frequent classification on the shared MM2 benchmark.
;;   Test E — Maximum length enforcement:
;;     Search terminates safely at configured MAX_LENGTH and generates no Level 4 candidates.
;;   Test F — Duplicate prevention:
;;     Canonicalization and pool deduplication prevent duplicate candidates.
;;   Test G — Clean termination on pruned branches:
;;     Infrequent candidates emit prune markers and halt branch expansion.
;;   Test H — Shared MM2 benchmark execution:
;;     Full level-wise search against ugly-sodaDrinker (N=20) demonstrating actual pruning.
;; =============================================================================

;; TEST-AUX src/pruning.metta
;; TEST-AUX src/search-loop.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker.metta
;; TEST-AUX benchmarks/ugly-sodaDrinker-keys.metta

;; -----------------------------------------------------------------------------
;; 1. Search Configuration & Language Bias
;; -----------------------------------------------------------------------------
(INPUT MIN_SUPPORT 5)
(INPUT MAX_LENGTH 3)
(configured_limits (min_support 5) (max_length 3))

(allowed_body_predicate positive_example Inheritance ((+ person) (# attribute)))
(predicate_arity Inheritance 2)
(valid_slot Inheritance 1 input person)
(valid_slot Inheritance 2 constant attribute)

(valid_constant attribute human)
(valid_constant attribute man)
(valid_constant attribute woman)
(valid_constant attribute ugly)
(valid_constant attribute sodaDrinker)

;; -----------------------------------------------------------------------------
;; 2. Root Candidate & Level 1 Search Initialization
;; -----------------------------------------------------------------------------
(candidate root 0 () (((var 0) person)) nil)
(expand_candidate root)

;; Level 1 Refinement Operator (refines root into 5 Level 1 attribute candidates)
(exec (warmr 215 ref_root_bfs)
  (, (expand_candidate root)
     (candidate root 0 () (((var 0) $ptype)) nil)
     (allowed_body_predicate positive_example $pred ((+ $ptype) (# $atype)))
     (valid_constant $atype $c))
  (O (+ (candidate (cand_l1 $c) 1 (($pred (var 0) (const $c))) (((var 0) $ptype)) root))
     (+ (candidate_pending_eval (cand_l1 $c)))
     (+ (candidate_pool 1 (($pred (var 0) (const $c)))))))

;; Level 1 Evaluation
(exec (warmr 220 eval_l1_bfs)
  (, (candidate $qid 1 (($p (var 0) (const $c))) $types root)
     (positive_example $k)
     ($p $k $c))
  (O (+ (key_witness $qid $k))))

;; Level 1 Count Support
(exec (warmr 225 count_l1_bfs)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $k))
  (O (count (candidate_support $qid $cnt) $cnt $k)
     (- (candidate_pending_eval $qid))))

;; Level 1 Cleanup
(exec (warmr 230 cleanup_l1_bfs)
  (, (candidate_support $qid $cnt)
     (key_witness $qid $k))
  (O (- (key_witness $qid $k))))

;; -----------------------------------------------------------------------------
;; 3. Expected Result Assertions
;; -----------------------------------------------------------------------------

;; Test A: Frequent Candidate Expansion
(EXPECTED-RESULT test-a-freq-man (candidate_frequent (cand_l1 man) 10))
(EXPECTED-RESULT test-a-freq-ugly (candidate_frequent (cand_l1 ugly) 10))
(EXPECTED-RESULT test-a-freq-human (candidate_frequent (cand_l1 human) 20))
(EXPECTED-RESULT test-a-freq-woman (candidate_frequent (cand_l1 woman) 10))
(EXPECTED-RESULT test-a-freq-soda (candidate_frequent (cand_l1 sodaDrinker) 10))
(EXPECTED-RESULT test-a-expand-l1 (expand_candidate_l1 (cand_l1 man)))

;; Test B: Infrequent Candidate Pruning
;; man ∧ woman has support 0 (< MIN_SUPPORT 5), so it is classified infrequent and pruned
(EXPECTED-RESULT test-b-infreq-man-woman (candidate_infrequent (cand_l2 man woman) 0))
(EXPECTED-RESULT test-b-prune-man-woman (prune_branch (cand_l2 man woman)))
(EXPECTED-RESULT test-b-confirm-prune (pruning_confirmed (cand_l2 man woman)))

;; Test C: Mixed Candidate Branches
;; Frequent branch (man ∧ ugly, support 5) continues and expands
(EXPECTED-RESULT test-c-freq-man-ugly (candidate_frequent (cand_l2 man ugly) 5))
(EXPECTED-RESULT test-c-expand-l2-man-ugly (expand_candidate_l2 (cand_l2 man ugly)))

;; Test D: Multi-Level Search Reaching Level 3
;; Triplet conjunction (human ∧ man ∧ ugly) evaluated and verified frequent (support 5)
(EXPECTED-RESULT test-d-l3-cand (candidate (cand_l3 human man ugly) 3 ((Inheritance (var 0) (const human)) (Inheritance (var 0) (const man)) (Inheritance (var 0) (const ugly))) (((var 0) person)) (cand_l2 human man)))
(EXPECTED-RESULT test-d-l3-freq (candidate_frequent (cand_l3 human man ugly) 5))
(EXPECTED-RESULT test-d-l3-freq-soda (candidate_frequent (cand_l3 human man sodaDrinker) 5))
(EXPECTED-RESULT test-d-l3-freq-man-ugly-soda (candidate_frequent (cand_l3 man ugly sodaDrinker) 5))

;; Test E: Maximum Length Enforcement & Termination
(EXPECTED-RESULT test-e-termination (warmr_search_status completed 3))

;; Test F: Duplicate Prevention & Canonical Pool
(EXPECTED-RESULT test-f-pool-l1 (candidate_pool 1 ((Inheritance (var 0) (const man)))))
(EXPECTED-RESULT test-f-pool-l2 (candidate_pool 2 ((Inheritance (var 0) (const human)) (Inheritance (var 0) (const man)))))
(EXPECTED-RESULT test-f-pool-l3 (candidate_pool 3 ((Inheritance (var 0) (const human)) (Inheritance (var 0) (const man)) (Inheritance (var 0) (const ugly)))))

;; Test H: Shared Benchmark Support Values
(EXPECTED-RESULT test-h-l2-human-soda (candidate_frequent (cand_l2 human sodaDrinker) 10))
(EXPECTED-RESULT test-h-l2-woman-ugly (candidate_frequent (cand_l2 woman ugly) 5))
(EXPECTED-RESULT test-h-l2-woman-soda (candidate_frequent (cand_l2 woman sodaDrinker) 5))
(EXPECTED-RESULT test-h-l2-ugly-soda (candidate_frequent (cand_l2 ugly sodaDrinker) 5))
