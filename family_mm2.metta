; Family relationships.
(parent abel hana)
(parent hana sami)
(parent hana lidiya)
(parent bereket sara)
(parent sara noah)

; Join two parent relationships to derive complete substitutions and keys.
(exec (freq f001 to_drive_three_chain_relational_pattern)
  (, (parent $ancestor $middle)
     (parent $middle $descendant))
  (O 
     (+ (complete_substitution ($ancestor $middle $descendant)))
       (+ (ancestor_key $ancestor))))

; Count distinct complete substitutions and ancestor keys.
(exec (freq f002 count_complete_substitutions)
   (, (complete_substitution $match))
   (O (count (complete_substitution_count $count) $count $match)))

(exec (freq f003 count_distinct_ancestor_keys)
   (, (ancestor_key $ancestor))
   (O (count (distinct_ancestor_key_count $count) $count $ancestor)))


   
;;;;;Cleanup facts from results.
(exec (freq f004 Cleanup_Facts_from_Results)
   (, (parent $X $Y))
   (O (- (parent $X $Y))))