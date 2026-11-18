;; =============================================================================
;; src/data-model.metta
;; =============================================================================
;; Purpose:
;;   Core data model and foundational execution rules for WARMR in MeTTa/MM2.
;;   Defines the canonical fact representations, priority conventions, and the
;;   staged distinct-key witness evaluation and counting pipeline.
;;
;; Priority Convention:
;;   All rewrite rules use the fixed 3-field priority tuple:
;;     (exec (warmr <stage> <label>) <sources> <sinks>)
;;   where <stage> is a 3-digit zero-padded decimal string:
;;     310..319: Query matching and key witness emission
;;     320..329: Distinct key witness counting
;;     330..339: Zero-support candidate fallback
;;     340..349: Temporary witness cleanup
;;
;; Supported Candidate Shapes (Milestone 1 PoC):
;;   Level 1 candidate with variable in argument 2:
;;     (candidate <qid> 1 (<pred> (var 0) (var 1)))
;;   Level 1 candidate with constant in argument 2:
;;     (candidate <qid> 1 (<pred> (var 0) (const <constant>)))
;;
;; Key Semantics:
;;   (var 0) is permanently rooted in the key predicate (positive_example <key>).
;;   Multiple satisfying substitutions for the same key individual collapse into
;;   a single (key_witness <qid> <key>) atom in MORK's AtomSpace.
;; =============================================================================

;; -----------------------------------------------------------------------------
;; STAGE 310: Query Evaluation — Variable Slot Matching
;; -----------------------------------------------------------------------------
;; For each positive example key that satisfies the query body with a free variable
;; in slot 2, project onto the key variable and emit a key witness.
(exec (warmr 310 eval_l1_var)
  (, (candidate $qid 1 ($pred (var 0) (var 1)))
     (positive_example $key)
     ($pred $key $val))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 311: Query Evaluation — Constant Slot Matching
;; -----------------------------------------------------------------------------
;; For each positive example key that satisfies the query body with an active
;; domain constant in slot 2, project onto the key variable and emit a key witness.
(exec (warmr 311 eval_l1_const)
  (, (candidate $qid 1 ($pred (var 0) (const $c)))
     (positive_example $key)
     ($pred $key $c))
  (O (+ (key_witness $qid $key))))

;; -----------------------------------------------------------------------------
;; STAGE 320: Distinct Key Witness Counting
;; -----------------------------------------------------------------------------
;; Counts the unique (key_witness $qid $key) facts stored in the AtomSpace.
;; Consumes (candidate_pending_eval $qid) to record that evaluation succeeded.
(exec (warmr 320 count_witnesses)
  (, (candidate_pending_eval $qid)
     (key_witness $qid $key))
  (O (count (candidate_support $qid $count) $count $key)
     (- (candidate_pending_eval $qid))))

;; -----------------------------------------------------------------------------
;; STAGE 330: Zero-Support Candidate Fallback
;; -----------------------------------------------------------------------------
;; If a candidate query has zero matching keys in the database, no key_witness
;; facts were asserted. Stage 320 did not fire, leaving candidate_pending_eval
;; active. Stage 330 catches this case and safely asserts support = 0.
(exec (warmr 330 zero_support_fallback)
  (, (candidate_pending_eval $qid))
  (O (+ (candidate_support $qid 0))
     (- (candidate_pending_eval $qid))))

;; -----------------------------------------------------------------------------
;; STAGE 340: Cleanup Temporary Witnesses
;; -----------------------------------------------------------------------------
;; Removes all temporary key_witness facts once candidate_support is produced,
;; maintaining a clean AtomSpace for downstream pipeline stages.
(exec (warmr 340 cleanup_witnesses)
  (, (candidate_support $qid $count)
     (key_witness $qid $key))
  (O (- (key_witness $qid $key))))
