# Custom Decompositions

MIMIQ allows you to define your own decomposition logic by creating custom [`DecompositionBasis`](@ref) and [`RewriteRule`](@ref) types. This is useful for targeting specific hardware gate sets, implementing novel compilation strategies, or enforcing constraints.

## Implementing a Custom Basis

To define a new decomposition target, you need to:

1.  Define a struct subtype of [`DecompositionBasis`](@ref).
2.  Implement [`isterminal(basis, op)`](@ref) to specify allowed operations.
3.  Implement [`decompose!(builder, basis, op, ...)`](@ref) to handle unsupported operations.

### Example: The "HTCX" Basis

Let's implement a basis that only allows Hadamard (`H`), T (`T`), and CNOT (`CX`) gates. All other gates (like `S` or `Z`) must be decomposed.

```julia
using MimiqCircuitsBase

# 1. Define the basis type
struct HTCXBasis <: DecompositionBasis end

# 2. Define terminal (allowed) operations
isterminal(::HTCXBasis, ::GateH) = true
isterminal(::HTCXBasis, ::GateT) = true
isterminal(::HTCXBasis, ::GateCX) = true
isterminal(::HTCXBasis, ::Measure) = true
# Default for others is false

# 3. Define decomposition logic
function MimiqCircuitsBase.decompose!(builder, basis::HTCXBasis, op::Operation, qt, ct, zt)
    # Strategy: Use existing rewrite rules or define custom logic
    
    # Try the CanonicalRewrite first (handles many standard decompositions)
    if matches(CanonicalRewrite(), op)
        return decompose_step!(builder, CanonicalRewrite(), op, qt, ct, zt)
    end
    
    # Custom decomposition for S gate: S = T * T
    if op isa GateS
        push!(builder, Instruction(GateT(), qt...))
        push!(builder, Instruction(GateT(), qt...))
        return builder
    end

    # Custom decomposition for Z gate: Z = S^2 = T^4
    if op isa GateZ
        for _ in 1:4
            push!(builder, Instruction(GateT(), qt...))
        end
        return builder
    end

    throw(DecompositionError("Operation $(opname(op)) not supported in HTCXBasis."))
end
```

Now you can use this basis:

```julia
circuit = Circuit()
push!(circuit, GateS(), 1) # Not supported directly

# Decompose to H, T, CX
new_circuit = decompose(circuit, basis=HTCXBasis())
# Result: 2 T gates
```

## Implementing Custom Rewrite Rules

If you have a reusable decomposition logic (e.g., "how to decompose a Toffoli gate"), you can package it as a [`RewriteRule`](@ref). Rules are modular and can be shared across multiple bases.

To create a rule:
1.  Define a struct subtype of [`RewriteRule`](@ref).
2.  Implement [`matches(rule, op)`](@ref).
3.  Implement [`decompose_step!(builder, rule, op, ...)`](@ref).

### Example: Decomposing Swap to 3 CNOTs

```julia
struct MySwapToCNOT <: RewriteRule end

# Match SWAP gates
MimiqCircuitsBase.matches(::MySwapToCNOT, ::GateSWAP) = true
MimiqCircuitsBase.matches(::MySwapToCNOT, ::Operation) = false

function MimiqCircuitsBase.decompose_step!(builder, ::MySwapToCNOT, op::GateSWAP, qt, ct, zt)
    q1, q2 = qt
    # SWAP = CX(1,2) CX(2,1) CX(1,2)
    push!(builder, GateCX(), q1, q2)
    push!(builder, GateCX(), q2, q1)
    push!(builder, GateCX(), q1, q2)
    return builder
end
```

You can then use this rule inside any basis or directly with [`decompose_step`](@ref).

```julia
# Use the rule directly
decomposed_swap = decompose_step(GateSWAP(), rule=MySwapToCNOT())
```
