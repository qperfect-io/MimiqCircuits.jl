# Non-unitary Operations

Contrary to [unitary gates](unitary_gates.md), non-unitary operations based on measurements make the quantum state collapse. Find in the following sections all the non-unitary operations supported by MIMIQ.

- [Non-unitary Operations](#non-unitary-operations)
  - [Measure](#measure)
    - [Mathematical definition](#mathematical-definition)
    - [How to use measurements](#how-to-use-measurements)
  - [Reset](#reset)
  - [Measure-Reset](#measure-reset)
  - [Conditional logic](#conditional-logic)
    - [If statements](#if-statements)
  - [Operators](#operators)
    - [Mathematical definition](#mathematical-definition-1)
    - [Operators available in MIMIQ](#operators-available-in-mimiq)
    - [How to use operators](#how-to-use-operators)

!!! note
    As a rule of thumb all non-unitary operations can be added to the circuit using the function [`push!`](@ref) by giving the index of the targets in the following order: quantum register index -> classical register index. 

!!! note
    Noise can also be interpreted as a non-unitary operations but will not be treated here, check the [noise](noise.md) documentation page to learn more about it.

!!! note
    Once a non-unitary operation is added to your circuit the speed of execution might be reduced. This is because in this case the circuit needs to be re-run for every sample since the final quantum state might be different each time. This is always true except for [`Measure`](@ref) operations placed at the very end of a circuit.
    To learn more about this head to the [simulation](simulation.md#understanding-sampling) page.

!!! note
    Some features of unitary gates are not available for non-unitary operations, for instance, [matrix](@ref), [inverse](@ref), [power](@ref), [control](@ref), [parallel](@ref).

## Measure

### Mathematical definition

Measurements are defined by a basis of projection operators ``P_k``, one for each different possible outcome ``k``. The probability ``p_k`` of measuring outcome ``k`` is given by the expectation value of ``P_k``, that is
```math
p_k = \bra{\psi} P_k \ket{\psi}.
```
If the outcome ``k`` is observed, the system is left in the state
```math
\frac{P_k\ket{\psi}}{\sqrt{p_k}} .
```
It is common to measure in the Z basis (``P_0=\ket{0}\bra{0}`` and ``P_1=\ket{1}\bra{1}``), but measurements in other bases are possible too.

### How to use measurements

Available measurement operations: [`Measure`](@ref), [`MeasureX`](@ref), [`MeasureY`](@ref), [`MeasureZ`](@ref), [`MeasureXX`](@ref), [`MeasureYY`](@ref), [`MeasureZZ`](@ref).

With MIMIQ you can measure the qubits at any point in the circuit (not only at the end of the circuit) using one of the measurement operations ([`Measure`](@ref)...). You can add it to the circuit like gates using [`push!`](@ref), but you will need to precise both the index for the quantum register (qubit to measure) and classical register (where to store the result):

```@example non_unitary
using MimiqCircuits # hide 
circuit = Circuit() # hide
push!(circuit, Measure(), 1, 1)
```

This will add a [Measure](@ref) on the first qubit of the quantum register to the `circuit` and write the result on the first bit of the classical register. Recall that the targets are always ordered as quantum register -> classical register -> z register. To learn more about registers head to the [circuit](circuits.md#registers-quantumclassicalz-register) page.  

You can also use iterators to Measure multiple qubits at once, as for gates:

```@example non_unitary
push!(Circuit(), Measure(), 1:10, 1:10)
```

!!! note
    In the absence of any non-unitary operations in the circuit, MIMIQ will sample (and, therefore, measure) all the qubits at the end of the circuit by default, see [simulation](simulation.md) page.

## Reset

Available reset operations: [`Reset`](@ref), [`ResetX`](@ref), [`ResetY`](@ref), [`ResetZ`](@ref).

A reset operation consists in measuring the qubits in some basis and then applying an operation conditioned on the measurement outcome to leave the qubits in some pre-defined state. For example, [Reset](@ref) leaves all qubits in ``\ket{0}`` (by measuring in ``Z`` and flipping the state if the outcome is `1`).

Here is an example of how to add a reset operation to a circuit:

```@example non_unitary
circuit = Circuit() # hide 
push!(circuit, Reset(), 1) 
```

Importantly, even though a reset operation technically measures the qubits, the information is not stored in the classical register, so we only need to specify the qubit register. If you want to store the result, see the [measure-reset](#measure-reset) section.

Note that a reset operation can be technically seen as noise and is described by the same mathematical machinery, see [noise](noise.md) page. For this reason, some of the functionality provided by MIMIQ for noise is also available for resets. Here is one example:
```@example non_unitary
krausoperators(Reset())
``` 

## Measure-Reset

Available measure-reset operations: [`MeasureReset`](@ref), [`MeasureResetX`](@ref), [`MeasureResetY`](@ref), [`MeasureResetZ`](@ref).

A measure-reset operation is the same as a reset operation except that we store the result of the measurement, see [measure](#measure) and [reset](#reset) sections. Because of that, we need to specify both quantum and classical registers when adding it to a circuit:

```@example non_unitary
circuit = Circuit() # hide 
push!(circuit, MeasureReset(), 1, 1)
```


## Conditional logic

### If statements

An *if* statement consists in applying an operation conditional on the value of some classical register. In that sense, it resembles a classical *if* statement.

In MIMIQ you can implement it using [`IfStatement`](@ref), which requires two arguments: an operation to apply and a [`BitString`](@ref) as the condition (see [bitstrings](special_topics.md#bitstring) page for more information):

```@example non_unitary
IfStatement(GateX(), BitString("111"))
```

!!! note
    At the moment, MIMIQ only allows to pass unitary gates as arguments to an if statement (which makes if statements unitary for now).

To add an [`IfStatement`](@ref) to a circuit use the [`push!`](@ref) function. The first (quantum) indices will determine the qubits to apply the gate to, whereas the last (classical) indices will be used to compare against the condition given. For example:

```@example non_unitary
circuit  = Circuit() # hide
# Apply a GateX on qubit 1 if the qubits 2 and 4 are in the state 1 and qubit 3 in the state 0. 
push!(circuit, IfStatement(GateX(), bs"101"), 1, 2, 3, 4)
```

Here, an `X` gate will be applied to qubit 1, if classical registers 2 and 4 are `1`, and classical register 3 is `0`. Of course, if the gate targets more than 1 qubit, then all qubit indices will be specified before the classical registers, as usual (see [circuit](circuits.md) page).

## Operators

### Mathematical definition

Operators refer to any linear operation on a state. An operator does not need to be unitary, as is the case of a gate. This means that any ``2^N \times 2^N`` matrix can in principle represent an operator on ``N`` qubits.

!!! note
    Do not confuse *operator* with *operation*. In MIMIQ, the word operation is used as the supertype for all transformations of a quantum state (gates, measurements, statistical operations...), whereas an operator is a sort of generalized gate, a linear tranformation.


### Operators available in MIMIQ

Custom operators: [`Operator`](@ref)

Special operators: [`DiagonalOp`](@ref), [`SigmaPlus`](@ref), [`SigmaMinus`](@ref), [`Projector0`](@ref), [`ProjectorZ0`](@ref), [`Projector1`](@ref), [`ProjectorZ1`](@ref), [`ProjectorX0`](@ref), [`ProjectorX1`](@ref), [`ProjectorY0`](@ref), [`ProjectorY1`](@ref), [`Projector00`](@ref), [`Projector01`](@ref), [`Projector10`](@ref), [`Projector11`](@ref)

Methods available: [`matrix`](@ref).


### How to use operators

Operators cannot be applied to a state directly (it cannot be added to a circuit using [push!](@ref)), because that would correspond to an unphysical transformation. However, they can be used within other operations such as [`ExpectationValue`](@ref) or to create custom noise models with [`Kraus`](@ref), see [noise](noise.md) and [statistical operations](statistical_ops.md) pages.

Operators can be used to compute expectation values as follows (see also [`ExpectationValue`](@ref)):

```@example operators
using MimiqCircuits
op = SigmaPlus()
ev = ExpectationValue(op)
```

```@example operators
push!(Circuit(), ev, 1,1)
```

Similarly, operators can also be used to define non-mixed unitary Kraus channels (see also [`Kraus`](@ref)).
For example, we can define the amplitude damping channel as follows:

```@example operators
gamma = 0.1
k1 = DiagonalOp(1, sqrt(1-gamma))    # Kraus operator 1
k2 = SigmaMinus(sqrt(gamma))    # Kraus operator 2
kraus = Kraus([k1,k2])
```

This is equivalent to

```@example operators
gamma = 0.1
ampdamp = AmplitudeDamping(gamma)
krausoperators(ampdamp)
```

!!! note
    Whenever possible, using specialized operators, such as `DiagonalOp` and `SigmaMinus`, as opposed to custom operators, such as `Operator`, is generally better for performance.


