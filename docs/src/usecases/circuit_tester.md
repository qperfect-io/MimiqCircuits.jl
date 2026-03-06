# Circuit Tester

The Circuit Tester allows you to verify the equivalence of two quantum circuits. It provides a way to check if two circuits implement the same quantum channel, which is crucial for verifying compilations, optimizations, or refactorings.

## Overview

The circuit tester uses the Choi-Jamiolkowski isomorphism to map the channel equivalence problem to a state preparation problem. By applying the first circuit and the inverse of the second circuit to a maximally entangled state (Bell state), the problem reduces to checking if the resulting state is the identity (or close to it).

## Usage Guide

To use the circuit tester, you create a `CircuitTesterExperiment` with the two circuits you want to compare.

### Basic Usage

Here is a simple example comparing two equivalent circuits: one with a CNOT gate, and another that decomposes the CNOT gate.

```julia
using MimiqCircuits

# Circuit 1: Standard CNOT
c1 = Circuit()
push!(c1, GateCX(), 1, 2)

# Circuit 2: Decomposed CNOT using Hadamard and CZ
c2 = Circuit()
push!(c2, GateH(), 2)
push!(c2, GateCZ(), 1, 2)
push!(c2, GateH(), 2)

# Create the experiment
ex = CircuitTesterExperiment(c1, c2)

# Check equivalence
# Submit the experiment for execution
probability = check_equivalence(connect(), ex)

println("Equivalence score: ", probability)
# Output should be 1.0 for equivalent circuits
```

### Verification Methods

The `CircuitTesterExperiment` supports two methods for verification, specified by the `method` keyword argument:

1.  **"samples" (default)**: Measures the final state in the computational basis. The equivalence score is the fraction of samples that are in the all-zero state. This is a probabilistic method suitable for most cases.
2.  **"amplitudes"**: Computes the amplitude of the all-zero state directly. This provides a more precise verification but relies on amplitude simulation capabilities. The equivalence score is the squared magnitude of the amplitude: $|A_{0...0}|^2$.

#### Using the "amplitudes" method

```julia
# Create the experiment using the "amplitudes" method
ex = CircuitTesterExperiment(c1, c2; method="amplitudes")

# Execute and check
probability = check_equivalence(connect(), ex)

println("Equivalence score (amplitudes): ", probability)
```

## API Reference

See [`check_equivalence`](@ref) and [`interpret_results`](@ref).
