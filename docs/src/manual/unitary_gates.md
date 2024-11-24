# Unitary Gates

Unitary gates are fundamental components of quantum circuits. Here we explain how to work with unitary gates in MIMIQ.


- [Unitary Gates](#unitary-gates)
  - [Mathematical background](#mathematical-background)
    - [State vector and probability](#state-vector-and-probability)
    - [Unitary transformation](#unitary-transformation)
  - [Unitary gates in MIMIQ.](#unitary-gates-in-mimiq)
    - [Single-qubit gates](#single-qubit-gates)
    - [Single-qubit parametric gates](#single-qubit-parametric-gates)
    - [Two qubit gates](#two-qubit-gates)
    - [Two-qubit parametric gates](#two-qubit-parametric-gates)
    - [Multi-qubit gates](#multi-qubit-gates)
    - [Generalized gates](#generalized-gates)
  - [Custom Gates](#custom-gates)
  - [Composition: Control, Power, Inverse, Parallel](#composition-control-power-inverse-parallel)
    - [Control](#control)
    - [Power](#power)
    - [Inverse](#inverse)
    - [Parallel](#parallel)
  - [Extract information of unitary gates](#extract-information-of-unitary-gates)
    - [Matrix](#matrix)
    - [Number of targets](#number-of-targets)


## Mathematical background

### State vector and probability

In quantum mechanics, every transformation applied to a quantum state must be unitary (in a closed system). To understand why, we can expand the quantum state as  
```math
\begin{aligned}
\ket{\psi} = \sum_{i=1}^{k} c_{i} \ket{\psi_{i}}
\end{aligned}
```  
where ``\ket{\psi_i}`` are orthonormal basis states.
For this state, the following condition must hold true:  
```math
\begin{aligned}
\sum_{i=1}^{k} |c_i|² = 1 
\end{aligned}
```
Since ``|c_i|^2`` corresponds to the probability of measuring state ``\ket{\psi_i}``, this condition simply says that the probabilities must add up to one. Unitary gates preserve this normalization condition, see below.


### Unitary transformation

An alternative way to compute the probability is through the inner product. Given two states in Hilbert space, ``\ket{\alpha}`` and ``\ket{\psi}``, the squared inner product ``|\braket{\alpha|\psi}|^2`` reflects the probability of measuring the system in state ``\ket{\alpha}``. 
Thus, the normalization condition can be written as``|\braket{\psi|\psi}|^2 = 1``. In other words, the length of the state vector in complex space must be one.

When evolving the state ``\ket{\psi}`` using an operator U, the normalization condition becomes (omitting the square):  
```math
\begin{aligned}
\bra{\psi} U^\dagger U \ket{\psi} = 1
\end{aligned}
```
To fulfill this, the operator U must satisfy the condition:  
```math
\begin{aligned}
U^\dagger U = I
\end{aligned}
```
An operator that fulfills this requirement is called a unitary operator and its matrix representation is unitary too.


## Unitary gates in MIMIQ.

MIMIQ offers a large number of gates to build quantum circuits. For an overview, type the following line in your Julia session:
```
?GATES
```

Similarly, to get more information about a specific gate, you can type the following command in your Julia session using the gate of your choice:
```
?GateID
```

There are different categories of gates depending on the number of targets, parameters etc. We discuss how to implement them in the following.

### Single-qubit gates

List of single-qubit gates: [`GateID`](@ref), [`GateX`](@ref), [`GateY`](@ref), [`GateZ`](@ref), [`GateH`](@ref), [`GateS`](@ref), [`GateSDG`](@ref), [`GateT`](@ref), [`GateTDG`](@ref), [`GateSX`](@ref), [`GateSXDG`](@ref). [`GateSY`](@ref), [`GateSYDG`](@ref).

For single-qubit gates you don't need to give any argument to the gate constructor (ex: `GateX()`).
You only need to give the index of the target qubit when adding it to your circuit with the [`push!`](@ref) function.
```@example unitary
using MimiqCircuits # hide
circuit = Circuit() # hide
push!(circuit, GateX(), 1)
```

### Single-qubit parametric gates

List of single-qubit parametric gates:  [`GateU`](@ref), [`GateP`](@ref), [`GateRX`](@ref), [`GateRY`](@ref), [`GateRZ`](@ref), [`GateR`](@ref), [`GateU1`](@ref), [`GateU2`](@ref), [`GateU3`](@ref), [`Delay`](@ref).

For single-qubit parametric gates you need to give the expected number of parameters to the gate constructor (ex: ```GateU(0.5, 0.5, 0.5)``` or ```GateU1(0.5)```), if you are unsure of the expected number of parameters type ```?``` before the name of the gate in your Julia session (ex: ```?GateU```).
As for any single qubit gates you can add it to your circuit by using the [`push!`](@ref) function and give the index of the target qubit.

```@example unitary
circuit = Circuit() #  hide
push!(circuit, GateRX(pi/2), 1)
```


### Two qubit gates

List of two qubits gates: [`GateCX`](@ref), [`GateCY`](@ref), [`GateCZ`](@ref), [`GateCH`](@ref), [`GateSWAP`](@ref), [`GateISWAP`](@ref), [`GateCS`](@ref), [`GateCSDG`](@ref), [`GateCSX`](@ref), [`GateCSXDG`](@ref), [`GateECR`](@ref), [`GateDCX`](@ref).

Two-qubit gates can be instantiated without any arguments just like single-qubit gates (ex: `GateCX()`).
You will need to give the index of both qubits to the [`push!`](@ref) function to add it to the circuit.
To understand the ordering of the targets check the documentation of each particular gate. For controlled gates we use the convention that the first register corresponds to the control and the second to the target.

```@example unitary
circuit = Circuit() # hide
push!(circuit, GateCH(), 1, 2)
```


### Two-qubit parametric gates
List of two qubits parametric gates : [`GateCP`](@ref), [`GateCU`](@ref), [`GateCRX`](@ref), [`GateCRY`](@ref), [`GateCRZ`](@ref), [`GateRXX`](@ref), [`GateRYY`](@ref), [`GateRZZ`](@ref),
[`GateRZX`](@ref), [`GateXXplusYY`](@ref), [`GateXXminusYY`](@ref).

Two-qubit parametric gates are instantiated exactly like single-qubit parametric gates. You will need to give the expected number of parameters of the gate to its constructor (ex: `GateCU(pi, pi, pi)`).
You can then add it to the circuit just like a two-qubit gate by giving the index of the target qubits to the [`push!`](@ref) function. Again, check each gate's documentation to understand the qubit ordering; for controlled gates the first qubit corresponds to the control qubit, the second to the target.

```@example unitary
circuit = Circuit() # hide
push!(circuit, GateRXX(pi/2), 1, 2)
```

### Multi-qubit gates

List of multi-qubit gates: [`GateCCX`](@ref), [`GateC3X`](@ref), [`GateCCP`](@ref), [`GateCSWAP`](@ref).

For the multi-qubit controlled gates you will need to give the index of each qubit to the [`push!`](@ref) function. As usual, first the control qubits, then the targets; check the specific documentation of each gate.

```@example unitary
circuit = Circuit() # hide
push!(circuit, GateC3X(), 1, 2, 3, 4)
```


### Generalized gates

Some common gate combinations are available as generalized gates: [`PauliString`](@ref), [`QFT`](@ref), [`PhaseGradient`](@ref), [`Diffusion`](@ref), [`PolynomialOracle`](@ref).

Generalized gates can be applied to a variable number of qubits.
It is highly recommended to check their docstrings to understand their usage `?QFT`.

Here is an example of use:
```@example unitary
circuit = Circuit() # hide
push!(circuit, PhaseGradient(10), 1:10...)
```
These gates target a variable number of gates, so you have to specify in the constructor how many target qubits will be used, and give to the [`push!`](@ref) function one index per target qubit.

More about generalized gates on [special operations](special_ops.md).

## Custom Gates

If you need to use a specific unitary gate that is not provided by MIMIQ, you can use [GateCustom](@ref) to create your own unitary gate.

!!! note 
    Only **one** qubit or **two** qubits gates can be created using MIMIQ's [`GateCustom`](@ref).

!!! note
    Avoid using [`GateCustom`](@ref) if you can define the same gate using a pre-defined gate from MIMIQ's library, as it could impact negatively peformance.

To create a custom unitary gate you first have to define the matrix of your gate in Julia:
```@example unitary
# define the matrix for a 2 qubits gate
custom_matrix = [exp(im*pi/3) 0 0 0; 0 exp(im*pi/5) 0 0; 0 0 exp(im*pi/7) 0; 0 0 0 exp(im*pi/11)]
```
Then you can create your unitary gate and use it like any other gate using [`push!`](@ref)

```@example unitary
circuit = Circuit() # hide
# creates the custom gate
custom_gate = GateCustom(custom_matrix)
# Add the gate to the circuit 
push!(circuit, custom_gate, 1, 2)
```

## Composition: Control, Power, Inverse, Parallel

Gates in MIMIQ can be combined to create more complex gates using [`Control`](@ref), [`Power`](@ref), [`Inverse`](@ref), [`Parallel`](@ref).

### Control

A controlled version of every gate can be built using the [`control`](@ref) function.  
For example, `CX` can be built with the following instruction:
```@example unitary
CX = control(1, GateX())
```
The first argument indicates the number of control qubits and is completely up to the user.
For example a CCCCCX can be built with the following instruction:
```@example unitary
CCCCCX = control(5, GateX())
```

!!! details
    A wrapper for [`GateCX`](@ref) is already provided by MIMIQ. Whenever possible, it is recommended to use the gates already provided by the framework instead of creating your own composite gate to prevent performances loss.

Be careful when adding the new control gate to your circuit. When using the [`push!`](@ref) function, the first expected indices should be the control qubits specified in [`Control`](@ref) and the last indices the target qubits of the gate, for instance:
```@example unitary
circuit = Circuit() # hide
# here the first 5 indices are the control qubit and the last index is the target qubit of X.
push!(circuit, CCCCCX, 1, 2, 3, 4, 5, 6)
```  

### Power

To raise the power of a gate you can use the [`power`](@ref) function.
For example, ``\sqrt{\mathrm{GateS}} = \mathrm{GateT}``, therefore, the following instruction can be used to generate the GateS:
```@example unitary
power(GateS(), 1//2)
```
!!! details 
    The power method will attempt to realize simplifications whenever it can, for example asking for the square of [`GateX`](@ref) will directly give you [`GateID`](@ref).

### Inverse

To get the inverse of an operator you can use the [`inverse`](@ref) method.
Remember that the inverse of a unitary matrix is the same as the adjoint (conjugate transpose), so this is a simple way to get the adjoint of a gate.
For example here is how to get the inverse of a [`GateH`](@ref)
```@example unitary
inv_H = inverse(GateH())
```

### Parallel

To create a composite gate applying a specific gate to multiple qubits at once you can use the [`parallel`](@ref) method.
```@example unitary
circuit = Circuit() # hide
X_gate_4 = parallel(4, GateX())

push!(circuit, X_gate_4, 1, 2, 3, 4)

draw(circuit)
```

To check the number of repetition of your custom parallel gate you can use the [`numrepeats`](@ref) method:
```@example unitary
numrepeats(X_gate_4)
```


Be careful when using a multi-qubit gate with [`parallel`](@ref) as the index of the targeted qubits in [`push!`](@ref) can become confusing.
for example see below the parallel applicatoin of a `CX` gate:
```@example unitary
circuit = Circuit() # hide
double_CX = Parallel(2, GateCX())
push!(circuit, double_CX, 1, 2, 3, 4)
draw(circuit)
```
Here the index 1 and 2 correspond to the control and target of the first `CX` gate and 3 and 4 correspond to the second `CX` gate.



## Extract information of unitary gates

MIMIQ priovides a few methods to extract information about the unitary gates.

### Matrix

To get the matrix of a unitary gate you can use the [`matrix`](@ref):
```@example unitary
matrix(GateCX())
```

### Number of targets

Another way to know how many qubits, bits or z-variables are targeted by one unitary gate you can use [`numqubits`](@ref), [`numbits`](@ref) and [`numzvars`](@ref), respectively.

```@example unitary
numqubits(GateCX()), numbits(GateCX()), numzvars(GateCX())
```

```@example unitary
numqubits(Measure()), numbits(Measure()), numzvars(Measure())
```

```@example unitary
numqubits(Amplitude(bs"01")), numbits(Amplitude(bs"01")), numzvars(Amplitude(bs"01"))
```

See [non-unitary operations](non_unitary_ops.md) and [statistical operations](statistical_ops.md) pages for more information on [`Measure`](@ref) and [`Amplitude`](@ref).

