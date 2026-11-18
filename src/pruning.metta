;; =============================================================================
;; src/pruning.metta
;; =============================================================================
;; Purpose:
;;   Support Classification and Anti-Monotonic Pruning Engine for the WARMR
;;   relational pattern miner in MeTTa/MM2 on MORK.
;;
;; Algorithmic Foundations:
;;   Implements the WARMR / Apriori anti-monotonicity principle:
;;     If a candidate pattern Q is infrequent (support(Q) < MIN_SUPPORT),
;;     then no specialization Q' of Q can be frequent (support(Q') <= support(Q)).
;;     Therefore, Q is pruned, and its specializations rho(Q) are never generated
;;     or evaluated.
;;
;; Outputs:
;;   - (candidate_frequent <cid> <support>): Candidate meets or exceeds threshold.
;;   - (candidate_infrequent <cid> <support>): Candidate falls below threshold.
;;   - (prune_branch <cid>): Branch is pruned; no descendants will be expanded.
;;
;; Priority Convention:
;;   Classification & Pruning: warmr 350..369
;; =============================================================================

;; -----------------------------------------------------------------------------
;; Numerical Comparison Facts (Exact Integers 0..25)
;; -----------------------------------------------------------------------------
;; Provides deterministic integer ordering in MORK for support thresholding
;; without external FFI dependencies or division arithmetic.

;; num_gte: A >= B
(num_gte 0 0)
(num_gte 1 0) (num_gte 1 1)
(num_gte 2 0) (num_gte 2 1) (num_gte 2 2)
(num_gte 3 0) (num_gte 3 1) (num_gte 3 2) (num_gte 3 3)
(num_gte 4 0) (num_gte 4 1) (num_gte 4 2) (num_gte 4 3) (num_gte 4 4)
(num_gte 5 0) (num_gte 5 1) (num_gte 5 2) (num_gte 5 3) (num_gte 5 4) (num_gte 5 5)
(num_gte 6 0) (num_gte 6 1) (num_gte 6 2) (num_gte 6 3) (num_gte 6 4) (num_gte 6 5) (num_gte 6 6)
(num_gte 7 0) (num_gte 7 1) (num_gte 7 2) (num_gte 7 3) (num_gte 7 4) (num_gte 7 5) (num_gte 7 6) (num_gte 7 7)
(num_gte 8 0) (num_gte 8 1) (num_gte 8 2) (num_gte 8 3) (num_gte 8 4) (num_gte 8 5) (num_gte 8 6) (num_gte 8 7) (num_gte 8 8)
(num_gte 9 0) (num_gte 9 1) (num_gte 9 2) (num_gte 9 3) (num_gte 9 4) (num_gte 9 5) (num_gte 9 6) (num_gte 9 7) (num_gte 9 8) (num_gte 9 9)
(num_gte 10 0) (num_gte 10 1) (num_gte 10 2) (num_gte 10 3) (num_gte 10 4) (num_gte 10 5) (num_gte 10 6) (num_gte 10 7) (num_gte 10 8) (num_gte 10 9) (num_gte 10 10)
(num_gte 11 0) (num_gte 11 1) (num_gte 11 2) (num_gte 11 3) (num_gte 11 4) (num_gte 11 5) (num_gte 11 6) (num_gte 11 7) (num_gte 11 8) (num_gte 11 9) (num_gte 11 10) (num_gte 11 11)
(num_gte 12 0) (num_gte 12 1) (num_gte 12 2) (num_gte 12 3) (num_gte 12 4) (num_gte 12 5) (num_gte 12 6) (num_gte 12 7) (num_gte 12 8) (num_gte 12 9) (num_gte 12 10) (num_gte 12 11) (num_gte 12 12)
(num_gte 15 0) (num_gte 15 2) (num_gte 15 5) (num_gte 15 10) (num_gte 15 15)
(num_gte 20 0) (num_gte 20 1) (num_gte 20 2) (num_gte 20 3) (num_gte 20 4) (num_gte 20 5) (num_gte 20 10) (num_gte 20 15) (num_gte 20 20)
(num_gte 25 0) (num_gte 25 5) (num_gte 25 10) (num_gte 25 20) (num_gte 25 25)

;; num_lt: A < B
(num_lt 0 1) (num_lt 0 2) (num_lt 0 3) (num_lt 0 4) (num_lt 0 5) (num_lt 0 10) (num_lt 0 20) (num_lt 0 25)
(num_lt 1 2) (num_lt 1 3) (num_lt 1 4) (num_lt 1 5) (num_lt 1 10) (num_lt 1 20) (num_lt 1 25)
(num_lt 2 3) (num_lt 2 4) (num_lt 2 5) (num_lt 2 10) (num_lt 2 20) (num_lt 2 25)
(num_lt 3 4) (num_lt 3 5) (num_lt 3 10) (num_lt 3 20) (num_lt 3 25)
(num_lt 4 5) (num_lt 4 10) (num_lt 4 20) (num_lt 4 25)
(num_lt 5 6) (num_lt 5 10) (num_lt 5 20) (num_lt 5 25)
(num_lt 6 7) (num_lt 6 10) (num_lt 6 20) (num_lt 6 25)
(num_lt 7 8) (num_lt 7 10) (num_lt 7 20) (num_lt 7 25)
(num_lt 8 9) (num_lt 8 10) (num_lt 8 20) (num_lt 8 25)
(num_lt 9 10) (num_lt 9 20) (num_lt 9 25)
(num_lt 10 11) (num_lt 10 15) (num_lt 10 20) (num_lt 10 25)
(num_lt 11 12) (num_lt 11 15) (num_lt 11 20) (num_lt 11 25)
(num_lt 12 15) (num_lt 12 20) (num_lt 12 25)
(num_lt 20 25)

;; -----------------------------------------------------------------------------
;; STAGE 350: Compute Support Threshold Comparison (Pure 64-bit Arithmetic)
;; -----------------------------------------------------------------------------
;; Computes is_freq = (count >= min_s) using native MORK 64-bit comparison.
;; Output is "1" if frequent, "0" if infrequent.
(exec (warmr 350 compute_frequent_status)
  (, (candidate_support $cid $count)
     (INPUT MIN_SUPPORT $min_s))
  (O (pure (frequent_status $cid $is_freq) $is_freq
       (i8_to_string (gte_i64 (i64_from_string $count) (i64_from_string $min_s))))))

;; -----------------------------------------------------------------------------
;; STAGE 351: Classify Frequent Candidates
;; -----------------------------------------------------------------------------
(exec (warmr 351 classify_frequent)
  (, (candidate_support $cid $count)
     (frequent_status $cid 1))
  (O (+ (candidate_frequent $cid $count))
     (- (frequent_status $cid 1))))

;; -----------------------------------------------------------------------------
;; STAGE 352: Classify Infrequent Candidates and Prune Branch
;; -----------------------------------------------------------------------------
(exec (warmr 352 classify_infrequent)
  (, (candidate_support $cid $count)
     (frequent_status $cid 0))
  (O (+ (candidate_infrequent $cid $count))
     (+ (prune_branch $cid))
     (- (frequent_status $cid 0))))

;; -----------------------------------------------------------------------------
;; STAGE 570: Confirm Pruning Enforcement
;; -----------------------------------------------------------------------------
;; Records explicit audit confirmation for each pruned branch across all levels.
(exec (warmr 570 confirm_pruning)
  (, (prune_branch $cid))
  (O (+ (pruning_confirmed $cid))))
