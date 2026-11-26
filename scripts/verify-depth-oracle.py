#!/usr/bin/env python3
"""
scripts/verify-depth-oracle.py
=============================================================================
Independent Reference Oracle for WARMR Arbitrary-Depth Relational Search.
Calculates ground-truth candidate structures, distinct-key witnesses, and
support values without calling or relying on the WARMR implementation.
=============================================================================
"""

import sys

def run_oracle():
    # 1. Synthetic Relational Chain Dataset (Nodes n0..n8)
    facts = [
        ("step", "n0", "n1"),
        ("step", "n1", "n2"),
        ("step", "n2", "n3"),
        ("step", "n3", "n4"),
        ("step", "n4", "n5"),
        ("step", "n5", "n6"),
        ("step", "n6", "n7"),
        ("step", "n7", "n8"),
    ]
    
    # 2. Key Domain (6 distinct positive example keys: n0..n5)
    keys = ["n0", "n1", "n2", "n3", "n4", "n5"]
    total_keys = len(keys)
    
    print("================================================================================")
    print("WARMR Relational Pattern Miner - Independent Reference Oracle")
    print("================================================================================")
    print(f"Total Keys (N): {total_keys} -> {keys}")
    print(f"Total Relational Facts: {len(facts)}")
    print("--------------------------------------------------------------------------------")
    
    # Graph representation
    adj = {}
    for pred, src, dst in facts:
        adj.setdefault(src, []).append(dst)
        
    expected_results = {}
    
    for depth in range(1, 9):
        # Query at depth d: step(var 0, var 1) ^ ... ^ step(var d-1, var d)
        # Distinct keys satisfying query:
        witnesses = []
        for k in keys:
            # BFS or DFS to find if any path of length `depth` starts at k
            curr = {k}
            for step_idx in range(depth):
                nxt = set()
                for node in curr:
                    for neighbor in adj.get(node, []):
                        nxt.add(neighbor)
                curr = nxt
            if len(curr) > 0:
                witnesses.append(k)
        
        abs_supp = len(witnesses)
        rel_supp = (abs_supp, total_keys)
        is_freq_min1 = abs_supp >= 1
        is_freq_min5 = abs_supp >= 5
        
        expected_results[depth] = {
            "depth": depth,
            "witnesses": sorted(witnesses),
            "absolute_support": abs_supp,
            "relative_support": f"{abs_supp}/{total_keys}",
            "frequent_min1": is_freq_min1,
            "frequent_min5": is_freq_min5
        }
        
        print(f"Depth {depth}:")
        print(f"  Witnesses ({abs_supp}): {witnesses}")
        print(f"  Absolute Support:    {abs_supp}")
        print(f"  Relative Support:    {abs_supp}/{total_keys}")
        print(f"  Frequent (min_s=1):  {is_freq_min1}")
        print(f"  Frequent (min_s=5):  {is_freq_min5}")
    
    print("--------------------------------------------------------------------------------")
    print("Oracle verification completed successfully.")
    return expected_results

if __name__ == "__main__":
    run_oracle()
