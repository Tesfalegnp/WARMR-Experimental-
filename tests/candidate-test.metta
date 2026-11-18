;; =============================================================================
;; tests/candidate-test.metta
;; =============================================================================
;; Milestone 4 Candidate Refinement and Validation Test Suite
;;
;; Verifies:
;;   Part A: Systematic Refinement Generation rho(Q)
;;     1. Valid Level 1 generation from root (const and output var modes).
;;     2. Valid Level 2 generation (branched on var 0, chained on var 1).
;;     3. Mode semantics: '+' (existing var reuse), '-' (fresh var introduction),
;;        '#' (active domain constant matching).
;;     4. Level 1 generation on shared MM2 benchmark (Inheritance + 5 attributes).
;;
;;   Part B: Declarative Candidate Validation and Error Detection
;;     5. Disallowed predicate rejection (foobar).
;;     6. Invalid predicate arity rejection (pathway/3).
;;     7. Invalid argument type rejection (invalid_constant).
;;     8. Disconnected candidate rejection (var 99 not connected to var 0).
;;     9. Valid candidate confirmation (good_l1, good_l2).
;; =============================================================================

;; TEST-AUX src/candidate-gen.metta
;; TEST-AUX src/canonicalize.metta
;; TEST-AUX config/warmr-config.metta

;; -----------------------------------------------------------------------------
;; 1. Language Bias Declarations (Synthetic Gene & MM2 Benchmark)
;; -----------------------------------------------------------------------------

;; Synthetic Gene Bias
(allowed_body_predicate positive_example pathway ((+ gene) (# pathway)))
(allowed_body_predicate positive_example regulates ((+ gene) (- gene)))
(predicate_arity pathway 2)
(predicate_arity regulates 2)
(valid_slot pathway 1 input gene)
(valid_slot pathway 2 constant pathway)
(valid_slot regulates 1 input gene)
(valid_slot regulates 2 output gene)

(valid_constant pathway metabolism)
(valid_constant pathway respiration)

;; Shared MM2 Benchmark Bias
(allowed_body_predicate positive_example Inheritance ((+ person) (# attribute)))
(predicate_arity Inheritance 2)
(valid_slot Inheritance 1 input person)
(valid_slot Inheritance 2 constant attribute)

(valid_constant attribute human)
(valid_constant attribute man)
(valid_constant attribute woman)
(valid_constant attribute ugly)
(valid_constant attribute sodaDrinker)

(configured_limits (min_support 2) (max_length 2))

;; -----------------------------------------------------------------------------
;; 2. Part A: Refinement Operator Inputs
;; -----------------------------------------------------------------------------

;; Root candidate for gene domain
(candidate root_gene 0 () (((var 0) gene)) nil)
(expand_candidate root_gene)

;; Active Level 1 candidate for gene domain (regulates introduces var 1)
(candidate c_reg 1
  ((regulates (var 0) (var 1)))
  (((var 0) gene) ((var 1) gene))
  root_gene)
(expand_candidate c_reg)

;; Root candidate for MM2 person domain
(candidate root_person 0 () (((var 0) person)) nil)
(expand_candidate root_person)

;; Active Level 1 candidates for MM2 domain (testing Level 2 pairwise expansion)
(candidate c_human 1
  ((Inheritance (var 0) (const human)))
  (((var 0) person))
  root_person)
(expand_candidate c_human)

;; -----------------------------------------------------------------------------
;; 3. Part B: Negative Test Candidates for Validation & Error Detection
;; -----------------------------------------------------------------------------

;; A. Disallowed Predicate (foobar not in allowed_body_predicate)
(validate_candidate bad_pred 1
  ((foobar (var 0) (var 1)))
  (((var 0) gene) ((var 1) gene))
  root_gene)

;; B. Invalid Predicate Arity (pathway with 3 arguments instead of 2)
(validate_candidate bad_arity 1
  ((pathway (var 0) (const metabolism) extra_arg))
  (((var 0) gene))
  root_gene)

;; C. Invalid Argument Type (constant not in valid_constant pool)
(validate_candidate bad_type 1
  ((pathway (var 0) (const invalid_constant)))
  (((var 0) gene))
  root_gene)

;; D. Disconnected Candidate (slot 1 is var 99, disconnected from key var 0)
(validate_candidate bad_conn 1
  ((pathway (var 99) (const metabolism)))
  (((var 99) gene))
  root_gene)

;; E. Valid Level 1 Candidate
(validate_candidate good_l1 1
  ((pathway (var 0) (const metabolism)))
  (((var 0) gene))
  root_gene)

;; F. Valid Level 2 Candidate
(validate_candidate good_l2 2
  ((pathway (var 0) (const metabolism))
   (regulates (var 0) (var 1)))
  (((var 0) gene) ((var 1) gene))
  good_l1)

;; -----------------------------------------------------------------------------
;; 4. Expected Results & Assertions
;; -----------------------------------------------------------------------------

;; Part A1: Synthetic Gene Level 1 Refinements Generated
(EXPECTED-RESULT gen-l1-metab (canonical_candidate (cand_l1 pathway metabolism) 1 ((pathway (var 0) (const metabolism))) (((var 0) gene)) root_gene))
(EXPECTED-RESULT gen-l1-resp (canonical_candidate (cand_l1 pathway respiration) 1 ((pathway (var 0) (const respiration))) (((var 0) gene)) root_gene))
(EXPECTED-RESULT gen-l1-reg (canonical_candidate (cand_l1 regulates var1) 1 ((regulates (var 0) (var 1))) (((var 0) gene) ((var 1) gene)) root_gene))

;; Part A2: Synthetic Gene Level 2 Refinements Generated
;; Branched on (var 0)
(EXPECTED-RESULT gen-l2-branch-metab (canonical_candidate (cand_l2 c_reg pathway metabolism) 2 ((pathway (var 0) (const metabolism)) (regulates (var 0) (var 1))) (((var 0) gene) ((var 1) gene)) c_reg))
;; Chained on (var 1)
(EXPECTED-RESULT gen-l2-chain-metab (canonical_candidate (cand_l2 c_reg pathway metabolism) 2 ((pathway (var 0) (const metabolism)) (regulates (var 1) (var 0))) (((var 0) gene) ((var 1) gene)) c_reg))
(EXPECTED-RESULT gen-l2-chain-outvar (canonical_candidate (cand_l2 c_reg regulates var2) 2 ((regulates (var 0) (var 1)) (regulates (var 1) (var 2))) (((var 0) gene) ((var 1) gene) ((var 2) gene)) c_reg))

;; Part A3: MM2 Benchmark Level 1 Refinements Generated (Inheritance + 5 attributes)
(EXPECTED-RESULT gen-mm2-human (canonical_candidate (cand_l1 Inheritance human) 1 ((Inheritance (var 0) (const human))) (((var 0) person)) root_person))
(EXPECTED-RESULT gen-mm2-man (canonical_candidate (cand_l1 Inheritance man) 1 ((Inheritance (var 0) (const man))) (((var 0) person)) root_person))
(EXPECTED-RESULT gen-mm2-woman (canonical_candidate (cand_l1 Inheritance woman) 1 ((Inheritance (var 0) (const woman))) (((var 0) person)) root_person))
(EXPECTED-RESULT gen-mm2-ugly (canonical_candidate (cand_l1 Inheritance ugly) 1 ((Inheritance (var 0) (const ugly))) (((var 0) person)) root_person))
(EXPECTED-RESULT gen-mm2-soda (canonical_candidate (cand_l1 Inheritance sodaDrinker) 1 ((Inheritance (var 0) (const sodaDrinker))) (((var 0) person)) root_person))

;; Part B: Validation Error Detection Assertions
(EXPECTED-RESULT err-pred (candidate_error disallowed_predicate bad_pred foobar))
(EXPECTED-RESULT err-arity (candidate_error invalid_arity bad_arity pathway 3 2))
(EXPECTED-RESULT err-type (candidate_error invalid_argument_type bad_type pathway invalid_constant))
(EXPECTED-RESULT err-conn (candidate_error disconnected_candidate bad_conn (var 99)))
(EXPECTED-RESULT ok-l1 (valid_candidate good_l1))
(EXPECTED-RESULT ok-l2 (valid_candidate good_l2))
