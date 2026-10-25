# Circuit Simplifications

MIMIQ provides several tools to optimize and transform quantum circuits before execution. These tools help reduce the number of gates, remove unused resources, and eliminate SWAP gates.

All of them work on a [`Circuit`](@ref) in your Julia session and return a new circuit. They are not options of [`submit`](@ref) or `execute`: to run a simplified circuit on the MIMIQ cloud, simplify it locally and submit the result.

## Simplify

[`simplify`](@ref) reduces the number of gates of a circuit without changing what it computes. The result has the same unitary as the original, global phase included, and the same measurements, resets and other non-unitary operations in the same order. Nothing is approximated.

```@example simplify
using MimiqCircuits

c = Circuit()
push!(c, GateH(), 1)
push!(c, GateH(), 1)          # H H is the identity
push!(c, GateCX(), 1, 2)
push!(c, GateRZ(0.2), 1)      # RZ on the control commutes with CX...
push!(c, GateCX(), 1, 2)      # ...so the two CX gates cancel
push!(c, GateRZ(0.3), 1)      # and the two RZ gates merge into RZ(0.5)
push!(c, GateT(), 2)
push!(c, GateT(), 2)          # T T is S

simplify(c)
```

`simplify` runs a list of passes in order, and repeats the whole list until a round no longer lowers the number of two-qubit gates or, failing that, the total number of instructions. Each pass is also a function you can call on its own:

| Pass | What it does |
|:-----|:-------------|
| [`remove_identities`](@ref) | Removes gates whose matrix is exactly the identity, such as `GateID` or `GateRZ(0)`. |
| [`cancel_inverses`](@ref) | Removes pairs of gates that multiply to the identity, such as `CX CX` or `S SDG`, also across gates that the second one commutes with. |
| [`merge_rotations`](@ref) | Adds up the angles of rotations of the same kind on the same qubits, `RZ(a) RZ(b)` into `RZ(a + b)`, and merges single-qubit gates of one rotation family, so `T T` becomes `S`. |
| [`resynthesize_2q`](@ref) | Rewrites each two-qubit block with the fewest `GateCX` it needs, from zero to three. |
| [`resynthesize_1q`](@ref) | Replaces each run of single-qubit gates on a qubit with one `GateU`, or removes it when it is the identity. |
| [`resynthesize_linear`](@ref) | Rewrites each block of `GateX`, `GateCX` and `GateSWAP`, of any width, from the linear map it computes. |

The default list, [`DEFAULT_SIMPLIFY_PASSES`](@ref), holds the first five, in the order of the table.

### Choosing the passes

The two resynthesis passes work on matrices, so they may replace named gates such as `GateH` or `GateS` with a `GateU`:

```@example simplify
c = Circuit()
push!(c, GateH(), 1)
push!(c, GateS(), 1)
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2)

# H S H becomes a single U gate.
simplify(c)
```

To keep the gates you wrote and only remove the redundant ones, pass the first three passes:

```@example simplify
# No resynthesis: gates are only removed, cancelled or merged.
simplify(c; passes=(remove_identities, cancel_inverses, merge_rotations))
```

Gates with symbolic parameters are only touched by `remove_identities`, `cancel_inverses` and `merge_rotations`, which add up symbolic angles:

```@example simplify
@variables θ

c = Circuit()
push!(c, GateRX(θ), 1)
push!(c, GateRX(2θ), 1)       # merged with the previous one into RX(3θ)

simplify(c)
```

[`resynthesize_linear`](@ref) is not in the default list. It pays off on circuits with large CX networks, such as arithmetic or error-correction encoders, and costs extra rounds for little on other circuits. Add it to the passes when your circuit has such networks:

```@example simplify
# A ladder of CX gates, applied twice. No pair of CX gates is next to its
# inverse, so the default passes cannot remove any of them.
c = Circuit()
for _ in 1:2, q in 1:3
    push!(c, GateCX(), q, q + 1)
end

simplify(c)
```

```@example simplify
# Together, the six CX gates compute a linear map of the qubits that two
# CX gates implement. `resynthesize_linear` finds it.
simplify(c; passes=(remove_identities, cancel_inverses, merge_rotations,
                    resynthesize_linear, resynthesize_2q, resynthesize_1q))
```

`passes` accepts any function that takes a `Circuit` and returns a `Circuit`, so you can mix your own rewrites with the built-in ones. The guarantee that the unitary is kept then holds only if your rewrites keep it too.

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
# CX @ q[1], q[3]  <-- Note: Target is physical 1 (was logical 2 pre-swap)
```
