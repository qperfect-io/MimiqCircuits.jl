# Special Operations

MIMIQ offers further possibilities to create circuits, such as new gate declarations, or wrappers for common combinations of gates.

- [Special Operations](#special-operations)
  - [Gate Declaration \& Gate Calls](#gate-declaration--gate-calls)
  - [Composite Gates](#composite-gates)
    - [Pauli String](#pauli-string)
    - [Quantum Fourier Transform](#quantum-fourier-transform)
    - [Phase Gradient](#phase-gradient)
    - [Polynomial Oracle](#polynomial-oracle)
    - [Diffusion](#diffusion)
    - [More about composite gates](#more-about-composite-gates)
  - [Barrier](#barrier)

## Gate Declaration & Gate Calls

Using MIMIQ you can define your own gates with a given name, arguments and instructions.
For examples if you wish to apply an `H` gate followed by an `RX` gate with a specific argument for the rotation you can use [`GateDecl`](@ref) or `@gatedecl` as follows:
```@example special_op
using MimiqCircuits # hide
@gatedecl ansatz(rot) = begin
    # build the equivalent circuit defining the gate
    c = Circuit()
    push!(c, GateH(), 1)
    push!(c, GateRX(rot), 2)

    # return the circuit
    return c
end
```
Here, `ansatz` is the name that will be shown when printing or drawing the circuit and the variable name for the declaration. Then `ansatz(...)` is how we instantiate the gate and `(rot)` defines the gate parameters.

As you can see in the code above, to generate your own gate declaration you will need to instantiate [`Instruction`](@ref)s. Instructions are instantiated using one operation followed by a list of targets needed by the operation. The order of the target follows the usual quantum register -> classical register -> Z-register order. Basically, it works the same way as [`push!`](@ref) except that no circuit is passed as an argument.

After declaration you can add it to your circuit using [`push!`](@ref).
```@example special_op
circuit = Circuit() # hide
push!(circuit, ansatz(pi), 1, 2)
```

!!! note
    A gate declared with [`GateDecl`](@ref) must be unitary.

!!! note
    `ansatz` is an object of type [`GateDecl`](@ref), whereas `ansatz(pi)` is of type [`GateCall`](@ref).

Creating a gate declaration allows you to add easily the same sequence of gates in a very versatile way and manipulate your new gate like you would with any other gate. This means that you can combine it with other gates via [`Control`](@ref), add noise to the whole block in one call, use it as an operator for [`ExpectationValue`](@ref), use it within an [`IfStatement`](@ref) etc. See [unitary gates](unitary_gates.md), [non-unitary operations](non_unitary_ops.md), and [noise](noise.md) pages.

For example, here is how to add noise to the previous gate declaration:
```@example special_op
circuit = Circuit()
my_gate = ansatz(pi)
push!(circuit, my_gate, 1, 2)

## Add noise to the gate declared
add_noise!(circuit, my_gate, Depolarizing2(0.1))

draw(circuit)
```

You can use it in an [`IfStatement`](@ref) as follows:
```julia
IfStatement(my_gate, bs"111")
```

Note that this type of combined operation does not work if we pass a circuit as an argument, instead of a declared gate (more precisely, a [`GateCall`](@ref), see note above).


## Composite Gates

MIMIQ provides a list of composite gates to facilitate the circuit building process.
Here is the full list of generalized gates available on MIMIQ: [`QFT`](@ref), [`PhaseGradient`](@ref), [`PolynomialOracle`](@ref), [`Diffusion`](@ref), [`PauliString`](@ref).

These composite gates are different from the other gates in that the number of targeted qubits is variable and require user input.

### Pauli String

A [`PauliString`](@ref) is an ``N``-qubit tensor product of Pauli operators of the form
```math
P_1 \otimes P_2 \otimes P_3 \otimes \ldots \otimes P_N,
```
where each ``P_i \in \{ I, X, Y, Z \}`` is a single-qubit Pauli operator, including the identity.

To create an operator using [`PauliString`](@ref) we simply pass as argument the Pauli string written as a `String`:
```@example special_op
circuit = Circuit() # hide
push!(circuit, PauliString("IXYZ"), 1, 2, 3, 4)
```

You can give it an arbitrary number of Pauli operators.

### Quantum Fourier Transform

The [Quantum Fourier transform](https://en.wikipedia.org/wiki/Quantum_Fourier_transform) is a circuit used to realize a linear tranformation on qubits and is a building block of many larger circuits such as [Shor's algorithm](https://en.wikipedia.org/wiki/Shor%27s_algorithm) or the [quantum phase estimation](https://en.wikipedia.org/wiki/Quantum_phase_estimation_algorithm). 

The QFT maps an arbitrary quantum state ``\ket{x} = \sum_{j = 0}^{N-1} x_{j}\ket{j}``
to a quantum state ``\sum_{k=0}^{N-1} y_{k}\ket{k}`` according to the formula

```math
\begin{aligned}
y_{k} = \frac{1}{\sqrt{N}} \sum_{j=0}^{N-1} x_{j}w_{N}^{-jk}
\end{aligned}
```
where ``w_N = e^{2\pi i / N}``.

In MIMIQ the [`QFT`](@ref) gate allows you to quickly implement a QFT in your circuit on an arbitrary ``N`` number of qubits.
You can instantiate the QFT gate by giving it the number of qubits you want to use `QFT(N)`
and you can add it like any other gate in the circuit.
```@example special_op
circuit = Circuit() # hide
push!(circuit, QFT(5), 1:5...)
```

This will add a 5 qubits QFT to the first five qubits of your circuit.

### Phase Gradient

A phase gradient gate applies a phase shift to a quantum register of ``N`` qubits, where each computational basis state ``\ket{k}`` experiences a phase proportional to its integer value ``k``:

```math
\begin{aligned}
\operatorname{PhaseGradient} =
\sum_{k=0}^{N-1} \mathrm{e}^{i \frac{2 \pi}{N} k} \ket{k}\bra{k}
\end{aligned}
```

To use it you can simply give it the number of qubit targets and add it to the circuit like the following examples:
```@example special_op
circuit = Circuit() # hide
push!(circuit, PhaseGradient(5), 1:5...)
```
This will add a 5 qubits [`PhaseGradient`](@ref) to the first 5 qubits of the quantum register.

### Polynomial Oracle

!!! warning
    This gate can only be used with the state vector simulator and not with MPS, because of ancillas qubit use.

The [`PolynomialOracle`](@ref) is a quantum oracle for a polynomial function of two registers.
It applies a ``\pi`` phase shift to any basis state which satifies ``a xy + bx + cy + d == 0``, where ``\ket{x}`` and ``\ket{y}`` are the states of the two registers.

Here is how to use the [`PolynomialOracle`](@ref):

```@example special_op
circuit = Circuit() # hide
push!(circuit, PolynomialOracle(5,5,1,2,3,4), 1:10...)
```
The arguments for [`PolynomialOracle`](@ref) follow this order: ``N_x`` (size of ``x`` register), ``N_y`` (size of ``y`` register), ``a``, ``b``, ``c``, ``d``, see definitions above.

### Diffusion

The [`Diffusion`](@ref) operator corresponds to [Grover's diffusion operator](https://en.wikipedia.org/wiki/Grover%27s_algorithm). It implements the unitary transformation.

```math
H^{\otimes n} (1-2\ket{0^n} \bra{0^n}) H^{\otimes n}
```
Here is how to use [`Diffusion`](@ref):
```@example special_op
circuit = Circuit() # hide
push!(circuit, Diffusion(10), 1:10...)
```
Again, you need to give the number of targets and the index of the targets.


### More about composite gates

All composite gates can be decomposed with [`decompose`](@ref) to extract the implementation (except for [`PolynomialOracle`](@ref)).
```@example special_op
decompose(QFT(5))
```

## Barrier

Barrier is a Non-op operation that does not affect the quantum state, but prevents compression or optimization across the execution.
As of now [`Barrier`](@ref) is only useful when combined with the MPS backend.

To add barriers to the circuit you can use the [`Barrier`](@ref) operation:
```@example special_op
circuit = Circuit() # hide 
push!(circuit, GateX(), 1)

# Apply the Barrier on one qubit.
push!(circuit, Barrier(1), 1)

# Add a Gate between barriers
push!(circuit, GateX(), 1)
push!(circuit, GateX(), 1)

# apply individual barriers on multiple qubits
push!(circuit, Barrier(1), 1:3)

#Add gates between barriers
push!(circuit, GateX(), 1:3)

# Apply one general Barrier on multiple qubits (is effectively the same as above)
push!(circuit, Barrier(3), 1, 2, 3)

draw(circuit)
```

In the example above when executing the second and third `X` gates can be compressed as one `ID` operator but the first and fourth `X` gate will not be merged with the others.
