; Family relationship facts.
!(add-atom &self (parent abel hana))
!(add-atom &self (parent hana sami))
!(add-atom &self (parent hana lidiya))
!(add-atom &self (parent bereket sara))
!(add-atom &self (parent sara noah))

; Collect every two-edge parent chain as (ancestor parent descendant).
!(collapse
  (match &self
    (parent $ancestor $middle)
    (match &self
      (parent $middle $descendant)
      ($ancestor $middle $descendant))))

; Count complete substitutions.
!(let $matches
  (collapse
    (match &self
      (parent $ancestor $middle)
      (match &self
        (parent $middle $descendant)
        ($ancestor $middle $descendant))))
  (size-atom $matches))

; Collect distinct ancestor bindings and count them.
!(let $keys
  (collapse
    (match &self
      (parent $ancestor $middle)
      (match &self
        (parent $middle $descendant)
        $ancestor)))
  (collapse (unique (superpose $keys))))

!(let $keys
  (collapse
    (match &self
      (parent $ancestor $middle)
      (match &self
        (parent $middle $descendant)
        $ancestor)))
  (let $distinct-keys
    (collapse (unique (superpose $keys)))
    (size-atom $distinct-keys)))