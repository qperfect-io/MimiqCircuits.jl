# Circuits

On this page you can find all the information needed to build a circuit using MIMIQ. Every useful function will be presented below, accompanied by an explanation of their purpose and examples of use.


- [Circuits](#circuits)
  - [What is a circuit and what are instructions](#what-is-a-circuit-and-what-are-instructions)
    - [Circuits \& Instructions in MIMIQ](#circuits--instructions-in-mimiq)
  - [Registers: quantum/classical/Z-register](#registers-quantumclassicalz-register)
  - [Creating a circuit](#creating-a-circuit)
  - [Adding Gates](#adding-gates)
    - [Push](#push)
      - [`Push!` specifics](#push-specifics)
    - [Insert](#insert)
    - [Append](#append)
  - [Visualizing circuits](#visualizing-circuits)
  - [Decompose](#decompose)


## What is a circuit and what are instructions 

A quantum circuit, similar to a classical circuit, represents a sequence of quantum gates applied to qubits, which are the carriers of quantum information. Quantum circuits are essential for designing quantum algorithms. The complexity of a quantum circuit is typically measured by two key metrics: width and depth. Width refers to the number of qubits in the circuit, while depth indicates the maximum number of sequential gates applied to any single qubit.

Here is a representation of a simple GHZ circuit on 4 qubits:
```@example show_ghz
using MimiqCircuits
ghz = Circuit()
push!(ghz, GateH(), 1)
for i in 2:4
  push!(ghz, GateCX(), 1, i)
end
draw(ghz)
```

In this representation, each qubit is depicted by a horizontal line labeled q[x], where x is the qubit’s index. The circuit is read from left to right, with each 'block' or symbol along a line representing an operation applied to that specific qubit.

### Circuits & Instructions in MIMIQ

MIMIQ implements a circuit using the [`Circuit`](@ref) structure, in essence this structure is a wrapper for a vector of [`Instruction`](@ref) to be applied on the qubits in the order of the vector. Since it is a vector a circuit can be manipulated as such, for example you can use for loops to iterate over the different instructions of the circuit, do vector comprehension or access all common vector attributes such as the length.

An [`Instruction`](@ref) is composed of the quantum operation to be applied to the qubits, and the targets on which to apply it. There are many types of quantum operations, as discussed in the [unitary gates](unitary_gates.md), [non-unitary operations](non_unitary_ops.md) and other pages of the manual. The targets can be qubits, as well as boolean or complex number vectors where classical information can be stored.
You will generally not need to interact with the [`Instruction`](@ref) class directly (for exceptions, see [special operations](special_ops.md)), but it is useful to understand how MIMIQ works.

See the following sections to learn how to add operations to your circuit.


## Registers: quantum/classical/Z-register

Before explaining how to build a circuit it is important to make a distinction between the different target registers your operations will be applied to. 

The circuits in MIMIQ are composed of three registers that can be used by the instructions:
- The Quantum Register: Used to store the **qubits** state. Most of the operators in MIMIQ will interact with the quantum register. When printing or drawing a circuit (with the function [`draw`](@ref)) the quantum registers will be denoted as `q[x]` with x being the index of the qubit in the quantum register.
- The classical register: Used to store the **bits** state. Some gates will need to interact with classical bits (ex: [`Measure`](@ref)) and the state of the classical bits is stored in the classical register, which is a vector of booleans. When printing or drawing a circuit the classical register will be denoted by the letter `c`.
- The Z-register: Used to store the result of some specific operations when the expected result is a **complex number** (ex: [`ExpectationValue`](@ref)). The Z-register is basically a vector of complex numbers. When printing or drawing a circuit the Z-Register will be denoted by the letter `z`.

For the three registers operators can be applied on an arbitrary index starting from 1 (as does Julia in general contrary to python). When possible you should always use the minimal index available as going for an arbitrary high index ``N`` will imply that ``N`` qubits will be simulated and might result in a loss of performance and will also make the circuit drawing more complex to understand. 

Here is a circuit interacting with all registers:
```@example circuits
using MimiqCircuits
# create empty circuit
circuit = Circuit()

# add X to the first qubit of the Quantum register
push!(circuit, GateX(), 1)

# compute Expectation value of qubit 1 and store complex number on the first Z-Register
ev = ExpectationValue(GateZ())
push!(circuit, ev, 1, 1)

# Measure the qubit state and store bit into the first classical register
push!(circuit, Measure(), 1, 1)

#drw the circuit
draw(circuit)
```

As you can see in the code above the indexing of the different registers always starts by the quantum register. If your operator interacts with the three registers the index will have to be provided in the following order: 
1. Index of the quantum register.
2. Index of the classical register.
3. Index of the z-register.


Be careful when writing information to the z-register or to the classical register as the information can be easily overwritten if the same index is used multiple times. For example if you measure two different qubits and store both in the same classical bit the results of the sampling will only report the last measurement.

To retrieve information on the number of element of each register you can use the [`numqubits`](@ref), [`numbits`](@ref) and [`numzvars`](@ref).

```@example circuits
numqubits(circuit), numbits(circuit), numzvars(circuit)
```

In the following sections you will learn in details how to build a circuit in MIMIQ.

## Creating a circuit

The first step in executing quantum algorithm on MIMIQ always consists in implementing the corresponding quantum circuit, a sequence of quantum operations (quantum gates, measurements, resets, etc...) that acts on a set of qubits. In MIMIQ we always start by defining an empty circuit

```@example circuits
circuit = Circuit()
```
There is no need to give any arguments. Not even the number of qubits, classical or Z-registers is necessary as it will be directly inferred from the operations added to the circuit.


## Adding Gates

Once a circuit is instantiated operations can be added to it.
To see the list of gates available head to [`OPERATIONS`](@ref), [`GATES`](@ref), `NOISECHANNELS` and [`GENERALIZED`](@ref) or enter the following command in your Julia session:

```
?GATES
```

To know more about the types of operations you can use in a circuit head to the [unitary gates](unitary_gates.md), [non-unitary operations](non_unitary_ops.md), [noise](noise.md), [symbolic operations](symbolic_ops.md) and [special operations](special_ops.md) pages.



### Push

To add gates to circuits in Julia we will mainly be using the [`push!`](@ref) function. The arguments needed by [`push!`](@ref) can vary, but in general it expects the following: 
1. The circuit to add the operation to.
2. The operator to be added. 
3. As many targets as needed by the operator (qubits/bits/zvars).


For instance you can add the gate `X` by simply running the following command
```@example circuits
push!(circuit, GateX(), 1)
```
The text representation ```H @ q[1]``` informs us that there is an instruction which applies the Hadamard gate to the qubit of index 1.


Some gates require multiple target qubits such as the `CX` gate.
Here is how to add such a gate to the circuit:
```@example circuits
circuit = Circuit() # hide
push!(circuit, GateCX(), 1, 2)
```
This will add the gate [`GateCX`](@ref) using the qubit number ```1``` as the control qubit and number ```2``` as the target qubit in the ```circuit```.

#### `Push!` specifics

[`push!`](@ref) is very versatile, it can be used to add multiple operators to multiple targets at once using iterators.

To add one type of gate to multiple qubits use:
```@example circuits
circuit = Circuit() # hide
push!(circuit, GateX(), 1:10)
```
This will add one `X` gate on each qubit from number 1 to 10.

This also works on 2-qubit gates:
```@example circuits
circuit = Circuit() # hide
# Adds 3 CX gates using respectively 1, 2 & 3 as the control qubits and 4 as the target qubit for all 
push!(circuit, GateCX(), 1:3, 4)
# Adds 3 CX gates using respectively 2, 3 & 4 qubits as the target and 1 as the control qubit for all
push!(circuit, GateCX(), 1, 2:4)

# adds 3 CX gates using respectively the couples (1, 4), (2, 5), (3, 6) as the control and target qubits
push!(circuit, GateCX(), 1:3, 4:6)

draw(circuit)
```

Be careful when using vectors for both control and target, if one of the two vectors in longer than the other only the `N` first element of the vector will be accounted for with `N = min(length.(vector1, vector2))`.
See the output of the code below to see the implication in practice:
```@example circuits
circuit = Circuit()
# Adds only 3 CX gates
push!(circuit, GateCX(), 1:3, 4:18)

draw(circuit)
```

You can also use tuples or vectors in the exact same fashion:
```@example circuits
circuit = Circuit() # hide

push!(circuit, GateCX(), (1, 2), (3, 4))
push!(circuit, GateCX(), [1, 3], [2, 4])

draw(circuit)
```

### Insert

You can also insert an operation at a given index in the circuit using the [insert!](@ref) function:

```@example circuits
circuit = Circuit()
push!(circuit, GateX(), 1)
push!(circuit, GateZ(), 1)

# Insert the gate at a specific index
insert!(circuit, 2, GateY(), 1)
circuit
```
This will insert [`GateY`](@ref) applied on qubit ```1``` at the second position in the circuit.

### Append

To append one circuit to another you can use the [append!](@ref) function:

```@example circuits
# Build a first circuit
circuit1 = Circuit()
push!(circuit1, GateX(), 1:3)

# Build a second circuit
circuit2 = Circuit()
push!(circuit2, GateY(), 1:3)

# Append the second circuit to the first one
append!(circuit1, circuit2)
circuit1
```
This will modify `circuit1` by appending all the operations from `circuit2`.

This function is particularly useful for building circuits by combining smaller circuit blocks.

## Visualizing circuits

To visualize a circuit use the [`draw`](@ref) method.
```@example circuits
circuit = Circuit() # hide
push!(circuit, GateX(), 1:5) # hide
draw(circuit)
```

Information such as the [`depth`](@ref) and the width ([`numqubits`](@ref)) can be extracted from the circuit:
```@example circuits
depth(circuit), numqubits(circuit)
```

## Decompose

Most gates can be decomposed into a combination of `U` and `CX` gates, the [`decompose`](@ref) function extracts such decomposition from a given circuit:
```@example circuits
circuit = Circuit()
push!(circuit, GateX(), 1)

# decompose the circuit
decompose(circuit)
```

