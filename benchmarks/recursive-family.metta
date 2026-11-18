;; =============================================================================
;; benchmarks/recursive-family.metta
;; =============================================================================
;; Relational Knowledge Base: Recursive Multi-Generation Family Tree
;; =============================================================================

;; Extensional base facts: parent(Parent, Child)
(parent abel hana)
(parent hana sami)
(parent sami noah)
(parent hana lidiya)
(parent bereket sara)

;; Intensional Datalog Rules for Transitive Closure: ancestor/2
;; Base rule (Priority 050): parent(X, Y) -> ancestor(X, Y)
(exec (warmr 050 base_ancestor)
  (, (parent $x $y))
  (O (+ (ancestor $x $y))))

;; Recursive rule (Priority 051): parent(X, Z) ∧ ancestor(Z, Y) -> ancestor(X, Y)
(exec (warmr 051 trans_ancestor_hop1)
  (, (parent $x $z)
     (ancestor $z $y))
  (O (+ (ancestor $x $y))
     (+ (exec (warmr 052 trans_ancestor_hop2)
          (, (parent $a $b)
             (ancestor $b $c))
          (O (+ (ancestor $a $c)))))))
