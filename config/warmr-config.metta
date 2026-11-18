;; =============================================================================
;; config/warmr-config.metta
;; =============================================================================
;; Global engine configuration and search parameters for the WARMR relational
;; pattern miner.
;; =============================================================================

;; Target positive key predicate (evaluates distinct key bindings over this relation)
(INPUT KEY_PREDICATE positive_example)

;; Minimum absolute support threshold (integer count of distinct positive keys)
(INPUT MIN_SUPPORT 2)

;; Maximum query length (maximum number of relational body literals)
(INPUT MAX_LENGTH 2)

;; Relational connectivity constraint (all body literals must share variables
;; connecting back to the key variable)
(INPUT REQUIRE_CONNECTED true)

;; Dataset identifier for structured result tagging
(INPUT DATASET_ID warmr_dataset)
