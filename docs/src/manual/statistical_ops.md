# Statistical Operations

Statistical operations are simulator specific mathematical operations allowing you to compute properties of the simulated quantum state without making it collapse.
All statistical operations will result in a real or complex number that will be stored in the Z-Register, and can be accessed from the results of the simulation through the `zstates` option, see [circuits](circuits.md) and [cloud execution](remote_execution.md) page.

On this page you will find all statistical operations available on MIMIQ with explanations and examples.

- [Statistical Operations](#statistical-operations)
  - [Expectation value](#expectation-value)
      - [Mathematical definition](#mathematical-definition)
      - [Usage on MIMIQ](#usage-on-mimiq)
  - [Entanglement](#entanglement)
    - [Von Neumann Entropy](#von-neumann-entropy)
      - [Mathematical definition](#mathematical-definition-1)
      - [Usage on MIMIQ](#usage-on-mimiq-1)
    - [Bond Dimension](#bond-dimension)
      - [Mathematical definition](#mathematical-definition-2)
      - [Usage on MIMIQ](#usage-on-mimiq-2)
    - [Schmidt Rank](#schmidt-rank)
      - [Mathematical definition](#mathematical-definition-3)
      - [Usage on MIMIQ](#usage-on-mimiq-3)
  - [Amplitude](#amplitude)


## Expectation value

#### Mathematical definition
An expectation value for a pure state ``| \psi \rangle`` is defined as
```math
\langle O \rangle = \langle \psi | O | \psi \rangle
```
where ``O`` is an operator. With respect to a density matrix ``\rho`` it's given by
```math
\langle O \rangle = \mathrm{Tr}(\rho O).
```

#### Usage on MIMIQ

First we need to define the operator ``O`` of which we will compute the expectation value

```@example statistical_op
using MimiqCircuits # hide
op = SigmaPlus()
```

[`SigmaPlus`](@ref) is only one of the many operators available. Of course, every gate can be used as an operator, for example `op = GateZ()`.
However, MIMIQ also supports many non-unitary operators such as [`SigmaPlus`](@ref), more about this on the [operators](non_unitary_ops.md#operators) page.


To ask MIMIQ to compute the expectation value for a circuit you can create an [`ExpectationValue`](@ref) object and [`push!`](@ref) it to the circuit like this:

```@example statistical_op
circuit = Circuit() # hide
push!(circuit, GateH(), 1)

# Ask to compute the expectation value
ev = ExpectationValue(op)
push!(circuit, ev, 1, 1)
```

As for all statistical operations, the arguments to give to the [`push!`](@ref) function always follow the order of quantum register index first, classical register second (none in this case), and Z-register index last.
In the example above, the first ``1`` is the index for the first qubit of the quantum register and the second ``1`` is the index of the Z-Register.

Notice that the expectation value will be computed with respect to the quantum state of the system at the point in the circuit where the [`ExpectationValue`](@ref) is added.


## Entanglement

MIMIQ supports statistical operations on entanglement for **ordered bipartitions**. For instance, for qubits ``[1...N]`` MIMIQ can compute the entanglement between the bipartitions ``[1...k-1]`` and ``[k...N]``. 

For this reason when you [`push!`](@ref) an entanglement operation to a circuit, you need to give it the qubit index ``k`` that separates the two bipartitions, as well as the Z-register to store the result.

!!! warning
    The following functions can only be used with the MPS backend.

### Von Neumann Entropy

#### Mathematical definition

The entanglement entropy for a bipartition into subsystems A and B is defined for a pure state ``\rho = | \psi \rangle\langle \psi`` | as
```math
  \mathcal{S}(\rho_A) = - \mathrm{Tr}(\rho_A \log_2 \rho_A) 
= - \mathrm{Tr}(\rho_B \log_2 \rho_B)
= \mathcal{S}(\rho_B)
```
where ``\rho_A = \mathrm{Tr}_B(\rho)`` is the reduced density matrix. A product
state has ``\mathcal{S}(\rho_A)=0`` and a maximally entangled state between A
and B gives ``\mathcal{S}(\rho_A)=1``.

We only consider bipartitions where ``A=\{1,\ldots,k-1\}`` and ``B=\{k,\ldots,N\}``,
for some ``k`` and where ``N`` is the total number of qubits.

#### Usage on MIMIQ

The entanglement entropy for a bipartition into subsystems A and B can be obtained using the [`VonNeumannEntropy`](@ref) function.
You do not need to provide any argument to [`VonNeumannEntropy`](@ref). To indicate where to create the separation into two subsystems MIMIQ will use the first qubit index given to the [`push!`](@ref) function, here is an example:

```@example statistical_op
circuit = Circuit() # hide
# Asking to compute the Von Neumann entropy between the two subsystems separated between qubit 2 and 3
push!(circuit, VonNeumannEntropy(), 3, 1)
```

Here we compute the Von neumann entropy between the two subsystems ``[1,2]`` and ``[3...N]`` and write the results into the index ``1`` of the Z-register.

!!! note
    For ``k=1``, A is empty and the Von Neumann entropy will always return 1.


### Bond Dimension

#### Mathematical definition

The bond dimension is only defined for a matrix-product state (MPS), which can be written as (with ``i_1=i_{N+1}=1``)

```math
  |\psi \rangle = \sum_{s_1,s_2,\ldots=1}^2
\sum_{i_2}^{\chi_2} \sum_{i_3}^{\chi_3} \ldots \sum_{i_{N}}^{\chi_{N}}
A^{(s_1)}_{i_1i_2} A^{(s_2)}_{i_2 i_3} A^{(s_3)}_{i_3 i_4} \ldots
A^{(s_N)}_{i_{N}i_{N+1}} | s_1, s_2, s_3, \ldots, s_N \rangle .
```

Here, ``\chi_k`` is the bond dimension, i.e. the dimension of the index ``i_k``. The
first and last bond dimensions are dummies, ``chi_1=chi_{N+1}=1``. A bond dimension
of 1 means there is no entanglement between the two halves of the system.

#### Usage on MIMIQ

To compute the bond dimension between two halves of a system you can use the [`BondDim`](@ref) operator and [`push!`](@ref) to the circuit like any entanglement measure:

```@example statistical_op
circuit = Circuit() # hide
# Asking to compute the BondDim between the second and third qubits
push!(circuit, BondDim(), 3, 1)
```

Here we compute the bond dimension between the two subsystems ``[1,2]`` and ``[3...N]`` and write the results into index ``1`` of the Z-Register.

!!! note
    For ``k=1`` the bond dimension returned will always be 1.

### Schmidt Rank

#### Mathematical definition

A Schmidt decomposition for a bipartition into subsystems A and B is defined
for a pure state as
```math
|\psi\rangle = \sum_{i=1}^{r} s_i |\alpha_i\rangle \otimes |\beta_i\rangle,
```
where ``|\alpha_i\rangle (|\beta_i\rangle)`` are orthonormal states acting on A
(B). The Schmidt rank is the number of terms ``r`` in the sum. A product state
gives ``r=1`` and ``r>1`` signals entanglement.

We only consider bipartitions where ``A=\{1,\ldots,k-1\}`` and ``B=\{k,\ldots,N\}``,
for some ``k`` and where ``N`` is the total number of qubits.

#### Usage on MIMIQ

To compute the Schmidt rank of a bipartition you can use the [`SchmidtRank`](@ref) operator and [`push!`](@ref) like all entanglement measures:

```@example statistical_op
circuit = Circuit() # hide
# Asking to compute the Schmidt rank between the two subsystems separated between qubits 2 and 3
push!(circuit, SchmidtRank(), 3, 1)
```

Here we compute the Schmidt rank between the two subsystems ``[1,2]`` and ``[3...N]`` and write the results into index ``1`` of the Z-Register.

!!! note
    For k=1, A is empty and the Schmidt rank will always
    return 1.



## Amplitude

With MIMIQ you can extract quantum state amplitudes in the computational basis at any point in the circuit using [`Amplitude`](@ref).
You will need to give the [`Amplitude`](@ref) function the [`BitString`](@ref) matching the state for which you want the amplitude.
For more information on [`BitString`](@ref)s check the [special topics](special_topics.md#bitstring) documentation page.

You can add the [`Amplitude`](@ref) object to the circuit exactly like any other gate:
```@example statistical_op
mystery_circuit = Circuit() # hide
push!(mystery_circuit, GateH(), 1:3) # hide

# Define the Amplitude operator
amp = Amplitude(BitString("101"))

# Add the amplitude operator to the circuit and write the result in the first complex number of the Z-Register
push!(mystery_circuit, amp, 1)
```
This will extract the amplitude of the basis state ``\ket{101}``. When adding the amplitude operation you do not need to give it any specific qubit target, the only index needed is for the Z-register to use for storing the result.
