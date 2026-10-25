# Annotations

Annotations attach information to a circuit without changing what it computes.
They do not act on the quantum state or on the classical register, and
simulators skip them. They exist so that a circuit can carry the metadata used
in quantum error correction workflows, most notably the annotations of the
[Stim](https://github.com/quantumlib/Stim) format, and so that a processed
circuit can record where events happened.

Available annotations: [`Detector`](@ref), [`ObservableInclude`](@ref),
[`QubitCoordinates`](@ref), [`ShiftCoordinates`](@ref), [`Tick`](@ref),
[`Lost`](@ref), [`Reloaded`](@ref). All of them are subtypes of
[`AbstractAnnotation`](@ref).

When a Stim file is read by MIMIQ (see [Import & Export](import_export.md#Stim)),
its `DETECTOR`, `OBSERVABLE_INCLUDE`, `QUBIT_COORDS`, `SHIFT_COORDS` and `TICK`
instructions become the annotations of the same name.

## Detectors and observables

A [`Detector`](@ref) marks a set of classical bits whose parity is
deterministic when the circuit runs without noise. A change of that parity
signals an error. The first argument is the number of bits it looks at; the
remaining arguments are optional coordinates, used to place the detector when
visualizing it.

An [`ObservableInclude`](@ref) adds a set of measured bits to a logical
observable. The first argument is again the number of bits, followed by the
index of the observable.

```@example annotations
using MimiqCircuits

c = Circuit()

# a 3-qubit repetition code: qubit 2 checks the parity of qubits 1 and 3
push!(c, GateCX(), 1, 2)
push!(c, GateCX(), 3, 2)
push!(c, Measure(), 2, 1)

# the outcome in c[1] is 0 without noise; this detector sits at coordinates (1, 0)
push!(c, Detector(1, 1, 0), 1)

# measure the data qubit 1 into c[2] and include it in observable 0
push!(c, Measure(), 1, 2)
push!(c, ObservableInclude(1, 0), 2)
```

A detector or observable can look at any number of bits:

```@example annotations
# a detector on the parity of c[1] and c[2], with coordinates (2.0, 0.5)
push!(Circuit(), Detector(2, 2.0, 0.5), 1, 2)
```

## Coordinates and time steps

[`QubitCoordinates`](@ref) assigns a position to a qubit. [`ShiftCoordinates`](@ref)
adds an offset to the coordinates of the annotations that follow it, which is
useful when the same block of operations is repeated in time. [`Tick`](@ref)
separates the circuit into time steps. None of them has targets except
[`QubitCoordinates`](@ref), which targets the qubit it describes.

```@example annotations
c = Circuit()

# place three qubits on a line
push!(c, QubitCoordinates(0, 0), 1)
push!(c, QubitCoordinates(1, 0), 2)
push!(c, QubitCoordinates(2, 0), 3)

# first time step
push!(c, GateCX(), 1, 2)
push!(c, Tick())

# second time step
push!(c, GateCX(), 3, 2)
push!(c, Tick())

# the next annotations are shifted by one unit along the second coordinate
push!(c, ShiftCoordinates(0, 1))
```

The values stored in an annotation are returned by `getnotes`:

```@example annotations
getnotes(Detector(2, 2.0, 0.5))
```

## Loss markers

[`Lost`](@ref) and [`Reloaded`](@ref) record that a qubit was lost or reloaded
at a point of the circuit. They are emitted by [`lower_losses`](@ref) and
[`resolve_losses`](@ref), so a resolved circuit still shows where the losses
landed. They can also be added by hand.

```@example annotations
c = Circuit()
push!(c, GateH(), 1)
push!(c, Lost(), 1)
push!(c, Reloaded(), 1)
```

See [Qubit Loss](loss.md) for how losses are resolved.

## Annotations and decompositions

Decompositions keep annotations as they are: they are terminal operations of
[`CanonicalBasis`](@ref) and [`StimBasis`](@ref), so [`decompose`](@ref) leaves
them in place next to the decomposed gates.

```@example annotations
c = Circuit()
push!(c, GateH(), 1)
push!(c, Tick())
push!(c, Measure(), 1, 1)
push!(c, Detector(1), 1)

decompose(c)
```
