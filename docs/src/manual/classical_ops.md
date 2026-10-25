# Classical Operations

Classical operations read and write the bits of the classical register. They do
not act on qubits, so they leave the quantum state untouched. Together with
measurements and [`IfStatement`](@ref) they let a circuit compute on measurement
outcomes while it runs, for example to combine syndrome bits before a
correction.

Available classical operations: [`SetBit0`](@ref), [`SetBit1`](@ref),
[`Not`](@ref), [`And`](@ref), [`Or`](@ref), [`Xor`](@ref). All of them are
subtypes of [`AbstractClassical`](@ref).

!!! note
    Classical operations target only classical bits. When adding them to a
    circuit with [`push!`](@ref), every index you give is a bit index.

## Setting and flipping bits

[`SetBit0`](@ref) and [`SetBit1`](@ref) write a fixed value into one bit,
whatever it held before. [`Not`](@ref) flips one bit.

```@example classical
using MimiqCircuits

c = Circuit()

# c[1] = 0 and c[2] = 1, regardless of their previous values
push!(c, SetBit0(), 1)
push!(c, SetBit1(), 2)

# flip c[2] back to 0
push!(c, Not(), 2)
```

## Logic operations

[`And`](@ref), [`Or`](@ref) and [`Xor`](@ref) combine several input bits and
store the result in one destination bit. The **first** bit index is always the
destination, the remaining ones are the inputs.

```@example classical
c = Circuit()

# c[1] = c[2] & c[3]
push!(c, And(), 1, 2, 3)

# c[4] = c[2] | c[3]
push!(c, Or(), 4, 2, 3)

# c[5] = c[2] ⊻ c[3]
push!(c, Xor(), 5, 2, 3)
```

Without arguments these operations act on 3 bits: one destination and two
inputs. To use more inputs, pass the **total** number of bits, destination
included:

```@example classical
# 5 bits in total: c[1] = c[2] & c[3] & c[4] & c[5]
push!(Circuit(), And(5), 1, 2, 3, 4, 5)
```

With more inputs, [`Xor`](@ref) stores their sum modulo 2, that is the parity
of the input bits.

```@example classical
# c[1] = (c[2] + c[3] + c[4]) mod 2
push!(Circuit(), Xor(4), 1, 2, 3, 4)
```

All of these need at least 3 bits; `And(2)` and similar throw an
`ArgumentError`.

## Combining with measurements and conditional operations

Classical operations act on the bits written by measurements, and their results
can be used as the condition of an [`IfStatement`](@ref). The following circuit
measures two qubits of a repetition code, computes in `c[3]` whether the two
outcomes disagree, and applies a correction only in that case.

```@example classical
c = Circuit()

# prepare a state and measure qubits 2 and 3 into c[1] and c[2]
push!(c, GateCX(), 1, 2)
push!(c, GateCX(), 1, 3)
push!(c, Measure(), 2, 1)
push!(c, Measure(), 3, 2)

# c[3] = 1 when the two outcomes differ
push!(c, Xor(), 3, 1, 2)

# apply X on qubit 1 if c[3] == 1
push!(c, IfStatement(GateX(), bs"1"), 1, 3)
```

An [`IfStatement`](@ref) can also wrap a classical operation, which gives
conditional updates of the classical register. Here `c[1]` is flipped only when
`c[2]` is `1`:

```@example classical
push!(Circuit(), IfStatement(Not(), bs"1"), 1, 2)
```

The targets of the body come first (`c[1]`), followed by the condition bits
(`c[2]`). See [Conditional logic](non_unitary_ops.md#Conditional-logic) for more on
[`IfStatement`](@ref) and [`WhileStatement`](@ref).

## Reusing a bit as input and output

An instruction normally refuses to target the same bit twice. Some operations
read and write the same bit and therefore accept repeated bit targets. This is
reported by [`allow_bit_aliasing`](@ref), and by [`allow_zvar_aliasing`](@ref)
for Z-register variables.

[`And`](@ref), [`Or`](@ref) and [`Xor`](@ref) allow it, so a bit can be updated
in place:

```@example classical
# c[1] = c[1] & c[2]
push!(Circuit(), And(), 1, 1, 2)
```

```@example classical
allow_bit_aliasing(And), allow_bit_aliasing(Detector)
```

[`IfStatement`](@ref) and [`WhileStatement`](@ref) allow it as well, so that a
condition bit can also be a target of the body, as in the
[`WhileStatement`](@ref) example of the [non-unitary operations](non_unitary_ops.md#While-statements)
page. On the Z-register, [`Add`](@ref), [`Multiply`](@ref) and [`Pow`](@ref)
allow a variable to be both input and output, see the
[Z-register operations](zops.md) page.

Qubit targets can never repeat, whatever the operation.
