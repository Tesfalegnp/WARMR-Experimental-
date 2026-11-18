;; =============================================================================
;; benchmarks/synthetic-genes.metta
;; =============================================================================
;; Synthetic Relational Knowledge Base: Gene Pathways and Regulation Networks
;; Used for multi-proof collapsing and relational chaining validation.
;; =============================================================================

;; Pathway memberships
(pathway gene_a metabolism)
(pathway gene_a energy)
(pathway gene_a signaling)
(pathway gene_b metabolism)
(pathway gene_x metabolism)

;; Gene regulation
(regulates gene_a gene_x)
(regulates gene_a gene_y)
(regulates gene_b gene_z)
