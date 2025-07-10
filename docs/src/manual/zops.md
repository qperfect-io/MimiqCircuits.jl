# Z-register Operations

Operations on the Z-register allow users to manipulate complex-valued variables inside a quantum circuit. This section covers all the information needed to perform operations on the
complex-valued variables stored in the Z-register.

- [Z-register Operations](#z-register-operations)
  - [What is the Z-register?](#what-is-the-z-register)
  - [What can you do with the Z-register?](#what-can-you-do-with-the-z-register)
    - [Storing information in the Z-register](#storing-information-in-the-z-register)
    - [Manipulating the Z-register](#manipulating-the-z-register)
      - [Example: Ising Hamiltonian expectation value (Energy)](#example-ising-hamiltonian-expectation-value-energy)

---

## What is the Z-register?

In MIMIQ, we save complex-valued variables in the form of a special register,
the Z-register. In practical terms, the Z-register is just a vector of complex
numbers (`ComplexF64` values) that can be manipulated with circuit operations,
similarly to the quantum register (qubits) or the classical register (bits).

When printing or drawing a circuit, the Z-register will be denoted by the
letter `z`.

## What can you do with the Z-register?

There are multiple things the Z-register can be used for. Usually we can divide
operations on the classical register of two types: operations that store
information in the Z-register and operations that manipulate the information
stored in the Z-register.

### Storing information in the Z-register

Operations like [`ExpectationValue`](@ref) and [`Amplitude`](@ref) compute some
value from the quantum state and store it into the z-register. For example, the
`ExpectationValue` operation computes the expectation value of an observable
and stores it in the z-register, while `Amplitude` stores the complex amplitude
of some bitstring, computed from the full quantum state.

### Manipulating the Z-register

Simple arithmetic operations like addition and multiplication can be performed
on the Z-register. For example, you can add two complex numbers stored in the
register with [`Add`](@ref) and multiply them with [`Multiply`](@ref).
These operations store their result in an additional z-register variable.

```@example
using MimiqCircuits

# build a simple GHZ circuit
c = push!(Circuit(), GateH(), 1)
push!(c, GateCX(), 1, 2,)

# compute the expectation value of some operators and store it in the z-register
push!(c, ExpectationValue(pauli"XX"),1,2,1) # 1,2 -> qreg, 1 -> zreg
push!(c, ExpectationValue(pauli"ZZ"),1,2,2) # 1,2 -> qreg, 2 -> zreg

# compute the amplitude of a bitstring and store it in the z-register
push!(c, Amplidute(bs"00"), 3)

# compute sum the expectation values of ZZ and XX and store it a third the
# z-register variable
push!(c, Add(3), 4,1,2) # z[4] += z[1] + z[2]

# other operations
push!(c, Multiply(3), 5,1,2) # z[5] *= z[1] * z[2]
push!(c, Multiply(1, 0.2), 3) # z[3] *= 0.2
push!(c, Pow(-1), 3) # z[3] = z[3]^(-1)

# display the circuit
display(circuit)
```

Operations like `Add` and `Multiply` can be used on an arbitrary number of inputs, for example, `Add(4)` and `Multiply(4)` take as input 4 Z-register variables and output the result on the 1st one.

Both these operations also take an extra argument, a constant value that will be multiplied or added to the result. For example `Add(2, 0.5)` will add 0.5 to the first and second input, and store the result in the first input.

#### Example: Ising Hamiltonian expectation value (Energy)

A more meaningful example is the computation of the expectation value of a one-dimensional Ising model with transverse magnetic field. The Hamiltonian is

```math
H = - J \sum_{j=1}^{N-1} \sigma^z_j \sigma^z_{j+1} - h \sum_{j=1}^N \sigma^x_j
```

where \(\sigma^z_j\) and \(\sigma^x_j\) are the Pauli matrices acting on the \(j\)-th qubit, \(J\) is the coupling constant, and \(h\) is the transverse magnetic field. The expectation value of the Hamiltonian can be computed with the following circuit:

```@example
using MimiqCircuits

# number of spins / qubits
N = 10

# coupling and magnetic field
J = 1.0
h = 0.5

# initialize an empty circuit
c = Circuit()

# complete here with an actual state preparation or circuit
# e.g. time evolution using suzuiki-trotter decomposition of H
# ...

# expectation values for the coupling part
for j in 1:(N-1)
    newz = numzvars(c) + 1
    push!(c, ExpectationValue(pauli"ZZ"), j, j+1, newz)
    push!(c, Multiply(1, -J), newz)
end

# expectation values for the magnetic field part
for j in 1:N
    newz = numzvars(c) + 1
    push!(c, ExpectationValue(GateX()), j, newz)
    push!(c, Multiply(1, -h), newz)
end

# sum all the expectation values to obtain the total energy
# there are in total 2N-1 expectation values to sum
# the 2N-th variable will store the total energy
push!(c, Add(2*N-1), 1:(2*N-1)...)

# display the circuti
display(c)
```
