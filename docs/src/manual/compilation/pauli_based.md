# Pauli-based Computation

In Pauli-based computation a circuit is expressed with two kinds of operations
only: ``\pi/8`` rotations about multi-qubit Pauli operators, and measurements of
multi-qubit Pauli operators. This is the form used by lattice-surgery
architectures for surface codes, where every logical operation is a Pauli product
measurement.

[`pauli_based_computation`](@ref) performs this rewrite:

```julia
new_circuit = pauli_based_computation(circuit; basis=CliffordTBasis(), magic_states=false)
```

- `basis`: the basis used to decompose the circuit into Clifford+T gates first.
  Measurements, resets and conditional Pauli operators are kept whole, whatever
  the basis.
- `magic_states`: if `true`, each rotation is further replaced by the injection
  of a magic state.

The circuit is decomposed into Clifford+T, then every Clifford gate is moved to
the end of the circuit. On the way, each T gate becomes an [`RPauli`](@ref)
rotation of angle ``\pm\pi/4``, and each measurement of a Pauli product
([`Measure`](@ref), [`MeasureX`](@ref), [`MeasureXX`](@ref),
[`MeasurePauli`](@ref) and the like) becomes a [`MeasurePauli`](@ref). The
Cliffords that end up after the last measurement do not change any outcome, so
they are dropped. The new circuit gives the same measurement statistics as the
original one, but not the same final state.

## Example

Prepare a Bell pair, apply a T gate to qubit 2 and measure both qubits:

```@example pbc
using MimiqCircuits # hide
c = Circuit()
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2)
push!(c, GateT(), 2)
push!(c, Measure(), 1:2, 1:2)

pauli_based_computation(c)
```

The Hadamard and CX gates before the T gate map ``Z_2`` to ``X_1 Z_2``, so the T
gate becomes a ``\pi/8`` rotation about ``X_1 Z_2`` (`RPauli` with angle
``\pi/4``). The same gates turn the measurements of ``Z_1`` and ``Z_2`` into
measurements of ``X_1`` and ``X_1 Z_2``, written to the original bits.

## Conditional operations and resets

An [`IfStatement`](@ref) whose body contains only Pauli operators, directly or
inside a [`PauliString`](@ref), [`Block`](@ref), [`Parallel`](@ref),
[`Repeat`](@ref) or gate call, applies one Pauli product. It becomes one
conditional `PauliString`, and the Clifford gates before it are moved past it as
they are moved past a measurement. A conditional T or T† gate becomes a
conditional `RPauli` rotation.

A reset ([`Reset`](@ref), [`ResetX`](@ref), [`ResetY`](@ref)) measures its qubit
into a new bit, placed after the bits of the circuit, then applies a conditional
Pauli that brings the qubit back to the reset state. The measure-and-reset
operations do the same with the bit they are given.

```@example pbc
c2 = Circuit()
push!(c2, GateH(), 1)
push!(c2, Measure(), 1, 1)
push!(c2, GateH(), 2)
push!(c2, IfStatement(GateZ(), bs"1"), 2, 1)
push!(c2, Reset(), 1)
push!(c2, Measure(), 1:2, 2:3)

pauli_based_computation(c2)
```

The Hadamard gate on qubit 2 turns the conditional ``Z_2`` into a conditional
``X_2``. The reset of qubit 1 measures ``X_1`` into the new bit 4 and applies
``Z_1`` when the outcome is 1.

Other conditional operations are refused with an error. After a conditional
Clifford gate, such as a conditional Hadamard, the Clifford gates to move would
depend on the condition bits, so the later rotations and measurements could not
be computed before the circuit runs.

## Magic-state injection

A ``\pi/8`` rotation can itself be carried out with Pauli product measurements by
consuming a magic state ``T\ket{+}``, prepared with [`PrepareStateT`](@ref). With
`magic_states=true` every rotation is replaced in this way. This uses one extra
ancilla qubit, two extra bits per rotation, and two bits per data qubit for the
Pauli frame:

```@example pbc
pauli_based_computation(c; magic_states=true)
```

Reading the result line by line:

1. [`PrepareStateT`](@ref) puts the ancilla (qubit 3) in the magic state.
2. The first `MeasurePauli` measures the rotation axis ``X_1 Z_2`` together with
   ``Z`` on the ancilla.
3. Depending on that outcome, the ancilla is measured in X or in Y. The two
   [`IfStatement`](@ref) lines implement this choice.
4. The two [`Xor`](@ref) lines record the byproduct described below in the Pauli
   frame.
5. The final measurements are the same as before.

When the second ancilla measurement gives `1`, the rotation comes with an extra
Pauli ``X_1 Z_2`` on the data qubits. It is not corrected with gates. Instead,
the product of all such Paulis is kept in classical bits, the Pauli frame, with
one bit for the X part and one for the Z part of each data qubit. Later outcomes
that the frame would flip are corrected in place with 3-bit `Xor` operations.
Here both final measurements commute with ``X_1 Z_2``, so no correction is
needed.

With magic states a conditional Pauli is not applied either: it multiplies the
frame when its condition holds. A conditional T or T† gate is refused, since a
magic state cannot be injected conditionally.
