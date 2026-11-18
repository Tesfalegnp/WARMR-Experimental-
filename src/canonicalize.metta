;; =============================================================================
;; src/canonicalize.metta
;; =============================================================================
;; Purpose:
;;   Candidate Canonicalization and Equivalence Normalization for the WARMR
;;   relational pattern miner in MeTTa/MM2 on MORK.
;;
;; Normalization Operations:
;;   1. Atom Ordering Normalization:
;;      Sorts relational body literals lexicographically by functor and arguments
;;      using MORK's verified sort-atom pure function.
;;   2. Alpha-Renaming / Variable Normalization:
;;      Normalizes variable identifiers sequentially starting from (var 0)
;;      based on order of first occurrence from left to right using MORK's
;;      verified indices_to_vars and vars_to_indices pure functions.
;;   3. Duplicate Elimination:
;;      Inserts canonical candidates into candidate_pool. Identical canonical
;;      forms collapse into exactly 1 atom via AtomSpace set semantics (PathMap).
;;
;; Supported Equivalences:
;;   - Atom-order equivalence (conjunction commutativity):
;;     ((L1) (L2)) == ((L2) (L1))
;;   - Alpha-renaming equivalence (variable renaming):
;;     ((pred (var 5) const)) == ((pred (var 0) const))
;;   - Distinct variable relationship preservation:
;;     ((pred (var 0) const) (pred (var 0) const2)) != ((pred (var 0) const) (pred (var 1) const2))
;;
;; Priority Convention:
;;   (warmr 230..249) — Runs strictly AFTER Candidate Generation (warmr 210..229)
;; =============================================================================

;; -----------------------------------------------------------------------------
;; STAGE 230–233: Pipeline Canonicalization for Raw Candidates
;; -----------------------------------------------------------------------------
;; Operates on (raw_candidate <id> <len> <body> <types> <parent>)
;; Emits (canonical_candidate <id> <len> <canon_body> <types> <parent>)
;; and (candidate_pool <len> <canon_body>).

;; Step 1: Lexicographical sorting of relational literals
(exec (warmr 230 sort_candidate_literals)
  (, (raw_candidate $id $len $body $types $parent))
  (O (pure (sorted_candidate $id $len $sorted $types $parent) $sorted (sort-atom (' $body)))
     (- (raw_candidate $id $len $body $types $parent))))

;; Step 2: Convert indexed variables (var i) to MORK variable tags
(exec (warmr 231 candidate_to_vars)
  (, (sorted_candidate $id $len $sorted $types $parent))
  (O (pure (vars_candidate $id $len $as_vars $types $parent) $as_vars (indices_to_vars (' $sorted)))
     (- (sorted_candidate $id $len $sorted $types $parent))))

;; Step 3: Re-index variables sequentially by first occurrence (alpha-normalization)
(exec (warmr 232 candidate_to_indices)
  (, (vars_candidate $id $len $as_vars $types $parent))
  (O (pure (canonical_candidate $id $len $canon $types $parent) $canon (vars_to_indices (' $as_vars)))
     (- (vars_candidate $id $len $as_vars $types $parent))))

;; Step 4: Populate candidate pool with unique canonical forms
(exec (warmr 233 pool_canonical_candidate)
  (, (canonical_candidate $id $len $canon $types $parent))
  (O (+ (candidate_pool $len $canon))))

;; -----------------------------------------------------------------------------
;; STAGE 235–238: Standalone Query Canonicalization
;; -----------------------------------------------------------------------------
;; Operates on (canonicalize_query <qid> <body>)
;; Emits (canonical_query_result <qid> <canon_body>) and (canonical_pool <canon_body>).

;; Step 1: Sort atoms
(exec (warmr 235 canon_query_sort)
  (, (canonicalize_query $qid $body))
  (O (pure (sorted_query $qid $sorted) $sorted (sort-atom (' $body)))
     (- (canonicalize_query $qid $body))))

;; Step 2: Convert to vars
(exec (warmr 236 canon_query_vars)
  (, (sorted_query $qid $sorted))
  (O (pure (vars_query $qid $as_vars) $as_vars (indices_to_vars (' $sorted)))
     (- (sorted_query $qid $sorted))))

;; Step 3: Normalize indices
(exec (warmr 237 canon_query_indices)
  (, (vars_query $qid $as_vars))
  (O (pure (canonical_query_result $qid $canon) $canon (vars_to_indices (' $as_vars)))
     (- (vars_query $qid $as_vars))))

;; Step 4: Populate query pool with unique canonical forms
(exec (warmr 238 pool_canonical_query)
  (, (canonical_query_result $qid $canon))
  (O (+ (canonical_pool $canon))))
