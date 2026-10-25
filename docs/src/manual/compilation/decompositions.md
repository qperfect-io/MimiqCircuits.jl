# Decompositions

MIMIQ provides a flexible, rule-based framework for decomposing quantum operations into simpler instruction sets. This is essential for transpilation to hardware constraints, converting circuits between different standards (e.g., OpenQASM, Clifford+T), and optimizing circuits.

## Core Functions

The primary entry points are [`decompose`](@ref) and [`decompose!`](@ref).

### Decompose

`decompose` creates a new circuit where all operations are terminal in the target basis.

```julia
# Decompose to the default canonical basis (basic primitive gates)
new_circuit = decompose(circuit)

# Decompose a specific operation into a circuit of primitives
sub_circuit = decompose(GateSWAP())
```

### In-place Decomposition

`decompose!` appends decomposed instructions to an existing circuit or collection.

```julia
# Decompose source and append to target circuit
decompose!(target_circuit, source_circuit)

# Decompose operation and append to target circuit
decompose!(target_circuit, GateH())
```

### Single-step Decomposition

[`decompose_step`](@ref) applies one rewrite rule once, without recursing into
the result. See [Step-wise decomposition](@ref) below.

## Decomposition Bases

Decomposition behavior is defined by a [`DecompositionBasis`](@ref). A basis determines:
1.  **Terminal Operations**: Which instructions are allowed (supported limits).
2.  **Decomposition Logic**: How to transform unsupported operations into supported sequences.

You can specify a basis when calling `decompose`:

```julia
# Decompose to a specific basis
decompose(circuit, basis=CliffordTBasis())
```

### Built-in Bases

MIMIQ includes several built-in decomposition bases:

| Basis | Description |
| :--- | :--- |
| [`CanonicalBasis`](@ref) | (Default) Decomposes to a standard set of primitive gates (U, CX, Measure, etc.). |
| [`QASMBasis`](@ref) | Targets the OpenQASM 2.0 gate library (`qelib1.inc`). |
| [`CliffordTBasis`](@ref) | Decomposes to the Clifford+T universal gate set: the operations of `StimBasis` plus T and T†. |
| [`StimBasis`](@ref) | Targets the operations of the Stim stabilizer simulator (version 1.16): Clifford gates, Pauli-basis and Pauli-product measurements, Pauli noise, and Paulis conditioned on one measured bit. |
| [`FlattenedBasis`](@ref) | Flattens all container operations (blocks, calls) while preserving gates. |

```julia
# Example: Decompose to QASM 2.0 gates
qasm_circ = decompose(circuit, basis=QASMBasis())
```

### Clifford+T and gridsynth

[`CliffordTBasis`](@ref) rewrites a circuit into Clifford and T gates. Rotations
by multiples of ``\pi/4`` are decomposed exactly. Other rotations are
approximated by [`GridSynthRewrite`](@ref), which implements the Ross-Selinger
gridsynth algorithm, by default to an operator-norm error of ``10^{-10}`` each.
The `rotations` keyword selects a different tolerance or rule:

```@example decompositions
using MimiqCircuits # hide
c = push!(Circuit(), GateRZ(0.123), 1)

# approximate the rotation to 1e-10 with Clifford+T gates
fine = decompose(c; basis=CliffordTBasis())

# a looser tolerance gives a shorter circuit
shorter = decompose(c; basis=CliffordTBasis(rotations=GridSynthRewrite(epsilon=1e-4)))

length(shorter), length(fine)
```

`CliffordTBasis(sk_depth=3)` uses the Solovay-Kitaev algorithm at recursion depth
3 instead, as earlier versions did by default.

The terminal operations of `CliffordTBasis` are those of [`StimBasis`](@ref)
plus `GateT` and `GateTDG`, classical operations, and any conditional of its
terminal operations. Measurements and resets in every Pauli basis, Pauli noise
and Pauli rotations by ``\pm\pi/2`` are therefore kept as they are, not
expanded into elementary gates.

### Conditional operations

[`CliffordTBasis`](@ref), [`FlattenedBasis`](@ref) and [`RuleBasis`](@ref)
decompose the operation inside an [`IfStatement`](@ref) with their own rules and
put each resulting instruction under the same condition, so a classically
controlled rotation decomposes like an unconditioned one. [`StimBasis`](@ref)
keeps a `GateX`, `GateY` or `GateZ` conditioned on one bit being 1, which is
Stim's feedback `CX rec[-k] q`. It rewrites the same gate conditioned on 0 as
the gate followed by that conditional, and throws a `DecompositionError` for any
other conditional operation.

## Rewrite Rules

A basis is built from rewrite rules. A [`RewriteRule`](@ref MimiqCircuitsBase.RewriteRule)
describes one transformation: [`matches`](@ref)`(rule, operation)` says whether
the rule applies to an operation, and the rule replaces a matching operation
with a short sequence of other operations. A rule does not know which gates are
allowed at the end, so it is applied once at a time, and a basis decides when to
stop.

The rules below are the ones the built-in bases use. They can also be used on
their own.

| Rule | Matches | Produces |
| :--- | :--- | :--- |
| [`CanonicalRewrite`](@ref) | most operations | one level of the standard decomposition, down to `GateU` and `GateCX` |
| [`FlattenContainers`](@ref) | `GateCall`, `Block` and their inverses | the instructions they contain |
| [`SpecialAngleRewrite`](@ref) | `GateRX`, `GateRY`, `GateRZ` by a multiple of ``\pi/4`` | exact Clifford+T gates |
| [`ToZRotationRewrite`](@ref) | `GateRX`, `GateRY` | `GateRZ` between Clifford gates |
| [`ZYZRewrite`](@ref) | `GateU` other than the identity, `GateRX` | `GateRZ` and `GateRY` rotations |
| [`ToffoliToCliffordTRewrite`](@ref) | `GateCCX` | `GateH`, `GateCX`, `GateT` and `GateTDG` |
| [`GridSynthRewrite`](@ref) | `GateRZ` with a numeric angle | approximate Clifford+T sequence (gridsynth) |
| [`SolovayKitaevRewrite`](@ref) | `GateRX`, `GateRY`, `GateRZ`, `GateU` with numeric parameters | approximate Clifford+T sequence (Solovay-Kitaev) |

### Applying a rule directly

Pass a rule to [`decompose_step`](@ref) to see what it does to one operation:

```@example decompositions
# RX(θ) = H · RZ(θ) · H
decompose_step(GateRX(0.3); rule=ToZRotationRewrite())
```

```@example decompositions
# RY needs an extra S† ... S around the Hadamards
decompose_step(GateRY(0.3); rule=ToZRotationRewrite())
```

[`SpecialAngleRewrite`](@ref) only matches angles that have an exact Clifford+T
form. With `only_cliffords=true` it matches multiples of ``\pi/2`` only, so the
result contains no T gate:

```@example decompositions
# RZ(π/4) is T up to a global phase
decompose_step(GateRZ(π / 4); rule=SpecialAngleRewrite())
```

```@example decompositions
# a generic angle, and T when only Clifford gates are allowed, are not matched
matches(SpecialAngleRewrite(), GateRZ(0.123)),
matches(SpecialAngleRewrite(only_cliffords=true), GateRZ(π / 4))
```

[`ZYZRewrite`](@ref) writes a single-qubit `GateU` as Euler rotations, leaving
out the rotations by zero:

```@example decompositions
# U(θ, ϕ, λ) becomes RZ(λ), RY(θ), RZ(ϕ) in time order
decompose_step(GateU(0.1, 0.2, 0.3); rule=ZYZRewrite())
```

[`ToffoliToCliffordTRewrite`](@ref) gives the standard decomposition of the
Toffoli gate with seven T or T† gates and six CX gates:

```@example decompositions
decompose_step(GateCCX(); rule=ToffoliToCliffordTRewrite())
```

[`SolovayKitaevRewrite`](@ref) approximates an arbitrary single-qubit rotation.
The first argument is the recursion depth: each level makes the approximation
more precise and the sequence longer. The first use builds a table of short
gate sequences (an ``\varepsilon``-net) and caches it; `net_max_points` limits
its size, which trades precision for the time it takes to build:

```@example decompositions
sk = SolovayKitaevRewrite(2; net_max_points=2000)
approx = decompose_step(GateRZ(0.123); rule=sk)

# the sequence uses only Clifford+T gates
length(approx), unique(opname.(getoperation.(approx)))
```

[`ToZRotationRewrite`](@ref), [`ToffoliToCliffordTRewrite`](@ref) and the
`GateRX` rule of [`ZYZRewrite`](@ref) are exact. [`SpecialAngleRewrite`](@ref)
and the `GateU` rule of [`ZYZRewrite`](@ref) are exact up to a global phase, and
the approximate rules up to their tolerance and a global phase.

Applying a rule to an operation it does not match throws a `DecompositionError`.
Check with [`matches`](@ref) first, or apply it to a whole circuit, as shown in
[Step-wise decomposition](@ref).

### Rules as bases

A rule used as a basis is applied again and again, to the output too, until no
instruction matches it any more. [`RuleBasis`](@ref) does that; passing the rule
itself as `basis` is the same:

```@example decompositions
c = Circuit()
push!(c, GateRX(0.3), 1)
push!(c, GateRY(π / 2), 2)
push!(c, GateCCX(), 1, 2, 3)

# only RX and RY match; the Toffoli is left as it is
decompose(c; basis=ToZRotationRewrite())
```

```@example decompositions
# RY(π/2) is rewritten exactly; RX(0.3) and the Toffoli do not match
decompose(c; basis=RuleBasis(SpecialAngleRewrite()))
```

This is useful to apply one specific transformation and leave the rest of the
circuit untouched. To combine several rules into a basis with a fixed target gate
set, write a custom basis as described in
[Custom Decompositions](custom_decompositions.md).

## Step-wise decomposition

[`decompose`](@ref) repeats decomposition steps until every operation is
terminal in the basis. [`decompose_step`](@ref) performs a single step, which
helps to see how an operation is broken down level by level. It takes an
operation, an instruction or a circuit, and a `rule` keyword that defaults to
[`CanonicalRewrite`](@ref):

```@example decompositions
# one level: the Toffoli becomes H, CX, T and T† gates
step1 = decompose_step(GateCCX())
```

```@example decompositions
# the next level writes H, T and T† as GateU
step2 = decompose_step(step1)
```

On a circuit, `decompose_step` rewrites each instruction the rule matches and
copies the others unchanged, so it can target one kind of operation:

```@example decompositions
# expand only the Toffoli gates, keep the rotations as they are
decompose_step(c; rule=ToffoliToCliffordTRewrite())
```

[`decompose_step!`](@ref) does the same, but appends the result to a circuit
you already have instead of returning a new one. An operation is applied to the
first qubits and bits:

```@example decompositions
acc = Circuit()

# append one Clifford+T step of a Toffoli, then the three CX of a SWAP,
# to the same circuit
decompose_step!(acc, GateCCX(); rule=ToffoliToCliffordTRewrite())
decompose_step!(acc, GateSWAP())
acc
```

A rule implements the low-level method
[`decompose_step!`](@ref)`(builder, rule, op, qtargets, ctargets, ztargets)`,
which appends the decomposition of `op` acting on the given targets to
`builder`. See [Custom Decompositions](custom_decompositions.md) to write one.

## Decomposition Iterators

For large circuits, you can iterate over decomposed instructions lazily without creating an intermediate circuit using [`eachdecomposed`](@ref).

```julia
for inst in eachdecomposed(large_circuit, basis=QASMBasis())
    # Process instructions one by one
    println(inst)
end
```

## Wrapping Decompositions

By default, `decompose` flattens the circuit. If you want to preserve the hierarchy by wrapping decomposed sequences into `GateDecl` or `Block` operations, use `wrap=true`.

```julia
# Preserves structure, wrapping decompositions in custom gate definitions
structured_circ = decompose(circuit, wrap=true)
```
