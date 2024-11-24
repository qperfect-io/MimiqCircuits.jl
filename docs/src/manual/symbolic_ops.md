# Symbolic Operations

This section provides detailed information on how to use symbolic operations in MIMIQ, including defining symbols, creating symbolic operations, substituting values, and running circuits with symbolic parameters.

- [Symbolic Operations](#symbolic-operations)
  - [When Symbolic Operations Can Be Useful](#when-symbolic-operations-can-be-useful)
  - [Defining Symbols](#defining-symbols)
  - [Defining Symbolic Operations](#defining-symbolic-operations)
  - [Substituting Symbols with Values](#substituting-symbols-with-values)

## When Symbolic Operations Can Be Useful

Symbolic operations are valuable in several quantum computing scenarios:

- **Parameter Optimization**: In algorithms like the **Variational Quantum Eigensolver (VQE)**, parameters need to be optimized iteratively. Using symbolic variables allows you to define a circuit once and update it with new parameter values during the optimization process. However, before executing the circuit, you must substitute the symbolic parameters with concrete values. This approach simplifies managing parameterized circuits.
  
- **Circuit Analysis**: Symbolic operations are useful for analyzing the structure of a quantum circuit. By keeping parameters symbolic, you can explore how different components of the circuit affect the output, such as measurement probabilities or expectation values, without needing to reconstruct the circuit.

<!-- **Parameter Optimization in VQE**:

In the **Variational Quantum Eigensolver (VQE)**, the goal is to find the ground state energy of a Hamiltonian. This involves:

1. Preparing a parameterized quantum state.
2. Measuring the expectation value of the Hamiltonian.
3. Updating the parameters to minimize this expectation value.

- **Step 1**: Use symbolic variables to define the parameterized circuit.
- **Step 2**: Substitute the symbolic variables with specific values during each optimization iteration and execute the circuit.

**Exploring Parameter Sensitivity in Circuit Analysis**:

In circuit analysis, the focus is on understanding how parameter changes affect the circuit's output. For instance, how measurement probabilities or expectation values change as parameters are varied.

- **Step 1**: Use symbolic variables to define the parameterized circuit.
- **Step 2**: Substitute different values for the symbolic parameters and analyze the resulting circuit outputs to see how they are affected.

!!! warning
    Symbolic parameters are useful tools for circuit design and analysis but before executing a circuit on a simulator you must substitute all symbolic parameters with numerical values. -->


## Defining Symbols

MIMIQ leverages the `Symbolics.jl` library to define symbolic variables. These variables act as placeholders for parameters in quantum operations, allowing you to create circuits with adjustable parameters that can be optimized or substituted later.

To define symbols in MIMIQ, you will need to create symbolic variables and then use them as parameters for parametric operations. Here's how to get started:

```@example symbolics
# Import the Symbolics package by importing MimiqCircuits
using MimiqCircuits

# Define symbols
@variables θ φ
if get(ENV, "MIMIQOUTPUTFORMAT", nothing) == "PDF" # hide
    "[θ, φ]" # hide
else # hide
    @variables θ φ # hide
end # hide
```

## Defining Symbolic Operations

Once you have defined symbols, you can use them in your quantum circuit operations. This allows you to create parameterized gates that depend on symbolic variables.

```@example symbolics
using MimiqCircuits #hide
@variables θ φ #hide

# Create a new circuit
c = Circuit()

# Add symbolic rotation gates
push!(c, GateRX(θ), 1)
push!(c, GateRY(φ), 2)
```

In this example, θ and φ are symbolic variables that can be used in operations.

## Substituting Symbols with Values

Before executing a circuit that includes symbolic parameters, you need to replace these symbols with specific numerical values. This is done using a dictionary to map each symbolic variable to its corresponding value. Here is an example of how to do it.

```@example symbolics
using MimiqCircuits #hide
@variables θ φ #hide
c = Circuit() #hide
push!(c, GateRX(θ), 1) #hide
push!(c, GateRY(φ), 2) #hide

# Substitute θ = π/2 and φ = π/4
substitutions = Dict(θ => π/2, φ => π/4)

# Apply the substitutions to the circuit
evaluated_circuit = evaluate(c, substitutions)
```

In this example, [`evaluate`](@ref) is used to create a new circuit where `θ` is replaced by `π/2` and `φ` by `π/4`.
