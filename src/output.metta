;; =============================================================================
;; src/output.metta
;; =============================================================================
;; Purpose:
;;   Structured Output Formatter for Frequent Relational Patterns in WARMR.
;;
;; Algorithmic Role:
;;   Transforms internal execution state into standardized, publication-ready
;;   frequent pattern records suitable for audit, export, and downstream
;;   comparison with Pattern Miner MM2.
;;
;; Output Schema:
;;   (warmr_pattern
;;     (id <cid>)
;;     (length <len>)
;;     (body <canonical_body>)
;;     (absolute_support <count>)
;;     (relative_support <count> <total_keys>)
;;     (classification frequent)
;;     (dataset <dataset_id>)
;;     (min_support <min_s>))
;;
;; Invariants:
;;   1. Formats ONLY verified frequent candidates (candidate_frequent <cid> <count>).
;;   2. Preserves canonical query body without loss of literal or variable structure.
;;   3. Preserves exact integer absolute support and rational relative support.
;;   4. AtomSpace set semantics guarantees no duplicate output records.
;;   5. Keeps temporary evaluation facts cleanly separated from published results.
;;
;; Priority:
;;   warmr 560 (Runs after support classification across all search levels)
;; =============================================================================

;; -----------------------------------------------------------------------------
;; STAGE 560: Emit Standardized Frequent Pattern Record
;; -----------------------------------------------------------------------------
(exec (warmr 560 emit_warmr_pattern)
  (, (candidate_frequent $cid $count)
     (candidate $cid $len $body $types $parent)
     (total_positive_keys $tot)
     (INPUT MIN_SUPPORT $min_s)
     (INPUT DATASET_ID $did))
  (O (+ (warmr_pattern
          (id $cid)
          (length $len)
          (body $body)
          (absolute_support $count)
          (relative_support $count $tot)
          (classification frequent)
          (dataset $did)
          (min_support $min_s)))))
