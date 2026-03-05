# Circuit DSL

MIMIQ provides a convenient Domain Specific Language (DSL) for defining circuits, blocks, and custom gate declarations. This DSL allows for a more concise and readable syntax compared to the standard `push!` or `insert!` methods.

## Creating Circuits

The [`@circuit`](@ref) macro creates a new [`Circuit`](@ref) and populates it with instructions defined in the block.

### Syntax

```julia
@circuit begin
    @on GateType(args...) q=qubits c=bits z=zvars
    # ...
end
```
or 
```julia
@circuit do 
    @on GateType(args...) q=qubits c=bits z=zvars
    # ...
end
```

The instructions are added using the special macro `@on`.

### Examples

```jldoctests
julia> c = @circuit begin
           @on GateH() q=1
           @on GateCX() q=(1, 2)
       end
2-qubit circuit with 2 instructions:
├── H @ q[1]
└── CX @ q[1], q[2]
```

## Creating Blocks

The [`@block`](@ref) macro works similarly to `@circuit` but returns a [`Block`](@ref) object, which can be useful for defining reusable sub-circuits.

### Example

```jldoctests
julia> b = @block begin
           @on GateX() q=1
           @on GateZ() q=1
       end
Block
```

## Gate Declarations

The [`@gatedecl`](@ref) macro allows you to define new gate types with custom arguments and instructions. This is a powerful feature for creating parametric gates or higher-level abstractions.

### Syntax

```julia
@gatedecl Name(args...) begin
    # ... instructions ...
end
```

### Examples

defining a custom ansatz:

```jldoctests
julia> @gatedecl MyAnsatz(θ) begin
           @on GateX() q=1
           @on GateRX(θ) q=2
           @on GateCX() q=(1, 2)
       end
MyAnsatz

julia> @variables λ
(λ,)

julia> g = MyAnsatz(λ)
MyAnsatz(λ)
```

You can then use this custom gate in a circuit:

```jldoctests
julia> c = Circuit()
julia> push!(c, g, 1, 2)
2-qubit circuit with 1 instructions:
└── MyAnsatz(λ) @ q[1], q[2]
```

## The `@on` Syntax

The `@on` macro is used within the DSL blocks to define instructions. It supports specifying targets for quantum registers (`q`), classical registers (`c`), and Z-registers (`z`).

- usage: `@on Operation(args...) [q=...] [c=...] [z=...]`

The targets can be single integers, tuples, vectors, or ranges.

```julia
@on GateH() q=1             # Single qubit
@on GateCX() q=(1, 2)       # Tuple of qubits
@on GateX() q=1:5           # Range (broadcast)
@on Measure() q=1 c=1       # Qubit and classical bit
```
