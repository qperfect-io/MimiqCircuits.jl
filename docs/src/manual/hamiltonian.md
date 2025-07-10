# Hamiltonians and Time Evolution

MIMIQ provides tools to define quantum Hamiltonians and simulate their time evolution using
Trotterization methods. This page explains how to construct Hamiltonians, compute their
expectation values, and apply Lie-Trotter, Suzuki-Trotter, and Yoshida decompositions.

This workflow allows you to:

- Build realistic Hamiltonians from Pauli terms
- Simulate time evolution efficiently using Trotter expansions
- Measure physical observables like energy

---

- [Hamiltonians and Time Evolution](#hamiltonians-and-time-evolution)
  - [Hamiltonian](#hamiltonian)
  - [Simulating the Ising Model](#simulating-the-ising-model)
  - [Ising Model](#ising-model)
  - [Building the Hamiltonian](#building-the-hamiltonian)
  - [Simulating Time Evolution](#simulating-time-evolution)
  - [Measuring the Energy](#measuring-the-energy)

---

## Hamiltonian

In quantum computing, Hamiltonians play a central role in algorithms such as the Variational Quantum Eigensolver (VQE),
Quantum Phase Estimation, and the Quantum Approximate Optimization Algorithm (QAOA). They are used to encode the energy landscape of
a physical system, generate dynamics, or define cost functions for optimization.

A typical Hamiltonian is expressed as a sum of weighted Pauli strings:

```math
H = \sum_j c_j \cdot P_j
```

Each term consists of a real coefficient \(c_j\) and a Pauli string \(P_j\), such as `X`, `ZZ`, or `XYZ`,
which acts on a specific subset of qubits.

In quantum circuit frameworks, these Hamiltonians are often represented programmatically by associating each
Pauli string with a set of target qubit indices and a coefficient.

---

## Simulating the Ising Model

A fundamental use case for Hamiltonians in quantum computing is to estimate physical quantities like the **ground state energy** of a system.
This is at the heart of quantum algorithms such as VQE, quantum simulation of materials, and quantum optimization.

Here, we demonstrate how to use MIMIQ to:

- Build the Hamiltonian for the **1D transverse-field Ising model**
- Apply **Trotterized time evolution** (first and second order)
- **Measure the energy** (expectation value of the Hamiltonian)

---

## Ising Model

The **1D transverse-field Ising model** is defined by the Hamiltonian:

```math
H = -J \sum_{j=1}^{N-1} Z_j Z_{j+1} - h \sum_{j=1}^{N} X_j
```

This models a chain of spins with:

- nearest-neighbor interaction (`ZZ` terms),
- and a transverse magnetic field (`X` terms).

---

## Building the Hamiltonian

To construct this model in MIMIQ you can use [`Hamiltonian`](@ref) to easily build your hamiltonian:

```@example
using MimiqCircuits # hide

N = 4            # number of spins / qubits
J = 1.0          # interaction strength
h = 0.5          # field strength

hamiltonian = Hamiltonian()

for j in 1:(N-1)
    push!(hamiltonian, -J, pauli"ZZ", j, j+1)
end

for j in 1:N
    push!(hamiltonian, -h, pauli"X", j)
end

display(hamiltonian)
```

---

## Simulating Time Evolution

Suppose we want to apply \( e^{-iHt} \) to a quantum state.
This is useful for preparing ground states via imaginary-time evolution, or evolving an initial state in real time.

Because `H` has non-commuting terms, we use a **Trotter approximation**.

**First-order Trotterization (Lie) ([`push_lietrotter!`](@ref))**

```@example
using MimiqCircuits # hide

c = Circuit()
push_lietrotter!(c, Tuple(1:N), hamiltonian, 1.0, 1)
decompose(c)
display(c)
```

**Second-order Trotterization (Suzuki) ([`push_suzukitrotter!`](@ref))**

```@example
using MimiqCircuits # hide

c = Circuit()
push_suzukitrotter!(c, Tuple(1:N), hamiltonian, 1.0, 1)
decompose(c)
display(c)
```

---

## Measuring the Energy

Once the circuit has prepared the desired quantum state via time evolution,
we can measure the energy by evaluating the expectation value of the Hamiltonian:

```@example
using MimiqCircuits # hide
c = Circuit() # hide
push_suzukitrotter!(c, Tuple(1:N), hamiltonian, 1.0, 1) # hide

push_expval!(c, hamiltonian, 1:N...)
display(c)
```

The result is stored in the Z-register. You can access it from the simulation result.

---
