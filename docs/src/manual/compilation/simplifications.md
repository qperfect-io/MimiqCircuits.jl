# Circuit Simplifications

MIMIQ provides several tools to optimize and transform quantum circuits before execution. These tools help reduce circuit depth, remove unnecessary operations, and eliminate SWAP gates.

## Cleaning Circuits

### Remove Unused

The [`remove_unused`](@ref) function cleans up a circuit by removing unused qubits, classical bits, and Z-variables. This is useful when constructing circuits programmatically where some resources might be allocated but never used.

```julia
new_circuit, qubit_map, bit_map, zvar_map = remove_unused(circuit)
```

**Example:**

```julia
c = Circuit()
push!(c, GateH(), 1)      # Qubit 1 is used
push!(c, GateCX(), 1, 3)  # Qubit 3 is used. Qubit 2 is unused.

new_c, qmap, bmap, zmap = remove_unused(c)
# new_c will have re-indexed qubits: 1->1, 3->2
```

### Remove SWAPs

The [`remove_swaps`](@ref) function is a powerful optimization that eliminates all `SWAP` gates from a circuit. Instead of executing physical swaps, it tracks the permutation of logical qubits and re-maps subsequent operations to the correct physical qubits.

```julia
new_circuit, final_permutation = remove_swaps(circuit; recursive=false)
```

**Example:**

```julia
c = Circuit()
push!(c, GateH(), 1)
push!(c, GateSWAP(), 1, 2)
push!(c, GateCX(), 2, 3) # "Logical" qubit 2 is now at physical 1

new_c, perm = remove_swaps(c)
# new_c:
# H @ q[1]
# CX @ q[1], q[3]  <-- Note: Target is physical 1 (was logial 2 pre-swap)
```
