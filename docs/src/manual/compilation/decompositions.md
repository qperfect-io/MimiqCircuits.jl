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

For finer control, `decompose_step` and `decompose_step!` perform only one level of decomposition.

```julia
# Perform just one decomposition step
step_circuit = decompose_step(operation)
```

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
| [`CliffordTBasis`](@ref) | Decomposes to the Clifford+T universal gate set (H, S, T, CX, etc.). |
| [`StimBasis`](@ref) | Targets operations supported by the STIM simulator. |
| [`FlattenedBasis`](@ref) | Flattens all container operations (blocks, calls) while preserving gates. |

```julia
# Example: Decompose to QASM 2.0 gates
qasm_circ = decompose(circuit, basis=QASMBasis())
```

### Rewrite Rules as Bases

You can also pass any [`RewriteRule`](@ref) directly as a basis. This is equivalent to using a [`RuleBasis`](@ref), which applies the rule recursively until it no longer matches any instructions in the circuit.

```julia
# Recursively apply FlattenContainers rule
decompose(circuit, basis=FlattenContainers())
```

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
