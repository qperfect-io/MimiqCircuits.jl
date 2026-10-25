# Symbolic Operations

This section provides detailed information on how to use symbolic operations in MIMIQ, including defining symbols, creating symbolic operations, substituting values, and sweeping a circuit over many parameter values.


## When Symbolic Operations Can Be Useful

Symbolic operations are valuable in several quantum computing scenarios:

- **Parameter Optimization**: In algorithms like the **Variational Quantum Eigensolver (VQE)**, parameters need to be optimized iteratively. Using symbolic variables allows you to define a circuit once and update it with new parameter values during the optimization process. However, before executing the circuit, you must substitute the symbolic parameters with concrete values. This approach simplifies managing parameterized circuits.
  
- **Parameter Sweeps**: To see how a result depends on a parameter, you can run the same circuit over a grid of values, see [Parameter Sweeps](#Parameter-Sweeps).

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

## Inspecting Symbolic Circuits

A few functions tell you which parameters a circuit or an operation has, and which of them are still symbolic.

[`listvars`](@ref) returns the symbols that appear in a circuit, an instruction or an operation, each once:

```@example symbolics
c = Circuit()
push!(c, GateRX(θ), 1)
push!(c, GateU(θ, φ, 0), 2)
push!(c, GateH(), 1)

listvars(c)
```

[`issymbolic`](@ref) tells whether any parameter is still symbolic. A circuit must not be symbolic when it is executed.

```@example symbolics
issymbolic(c), issymbolic(GateH())
```

[`numparams`](@ref) and [`parnames`](@ref) give the number and the names of the parameters of an operation, or of an operation type. [`getparam`](@ref) reads one parameter by name.

```@example symbolics
numparams(GateU), parnames(GateU)
```

```@example symbolics
getparam(GateU(θ, φ, 0), :θ)
```

[`evaluate`](@ref) returns a new circuit and leaves the original unchanged. `evaluate!` substitutes the values in place instead, which avoids building a copy of a large circuit. Symbols missing from the dictionary stay symbolic:

```@example symbolics
evaluate!(c, Dict(θ => 0.5))
```

```@example symbolics
listvars(c)
```

## Parameter Sweeps

To run the same symbolic circuit for many parameter values, describe the values with a [`ParameterTable`](@ref) and pair it with the circuit in a [`SweepExperiment`](@ref). In a sweep every point binds the same symbols, so a table stores them once, in a fixed order, with one row of values per point.

### Building a table

There are several ways to build a table:

- `ParameterTable(θ => xs, φ => ys)` takes one column per symbol. All columns have the same length, and point `i` takes the `i`-th value of each.
- [`gridtable`](@ref)`(θ => xs, φ => ys)` takes every combination of the values.
- `ParameterTable([θ, φ], values)` takes the symbols and a matrix with one row per point and one column per symbol.
- `ParameterTable(points)` takes a vector of dictionaries, one per point.

```@example symbolics
using MimiqCircuits #hide
@variables θ φ #hide

# Three points: (0, 0), (π/2, π/4) and (π, π/2).
ParameterTable(θ => [0, π/2, π], φ => [0, π/4, π/2])
```

```@example symbolics
# Every combination of 3 values of θ and 2 values of φ: 6 points.
# The first symbol varies slowest and the last one fastest.
t = gridtable(θ => [0, π/2, π], φ => [0, π/4])
```

`length(t)` is the number of points and `t[i]` is point `i`, as a dictionary ready for [`evaluate`](@ref). `t[2:3]` is the table of the selected points only.

```@example symbolics
t[2]
```

### Composing tables

Tables compose like the grids they describe:

- `a * b` is the Cartesian product: every point of `a` with every point of `b`.
- `hcat(a, b)` pairs the points of two tables of the same length.
- `vcat(a, b)` appends the points of `b` after those of `a`. Both must bind the same symbols.

```@example symbolics
a = ParameterTable(θ => [0.0, 1.0])
b = ParameterTable(φ => [0.0, 0.5])

# The same as gridtable(θ => [0.0, 1.0], φ => [0.0, 0.5]).
a * b
```

```@example symbolics
# Point i of a with point i of b.
hcat(a, b)
```

```@example symbolics
# Add a third value of θ at the end.
vcat(a, ParameterTable(θ => [2.0]))
```

### Sweep experiments

A [`SweepExperiment`](@ref) checks that the table gives values for exactly the free symbols of the circuit, so a missing or misspelled symbol fails when the experiment is built rather than when it runs:

```@example symbolics
c = Circuit()
push!(c, GateRX(θ), 1)
push!(c, GateRZ(φ), 1)
push!(c, Measure(), 1, 1)

ex = SweepExperiment(c, gridtable(θ => [0, π/2, π], φ => [0, π/4]))
```

`ex[i]` is the circuit evaluated at point `i`, and iterating over the experiment gives the evaluated circuits in the order of the table:

```@example symbolics
# The circuit at point 4: θ = π/2, φ = π/4.
ex[4]
```

To run a sweep on the MIMIQ cloud, submit the evaluated circuits in batch mode. [`submit`](@ref) does not take a `SweepExperiment` itself, and batch mode needs an explicit `algorithm`:

```julia
# One circuit per point of the table, in the same order.
job = submit(conn, collect(ex); algorithm="statevector", nsamples=1000)

# One QCSResults per point: results[i] is the result of ex[i].
results = getresults(conn, job)
```

See [Cloud Execution](remote_execution.md) for how to open a connection and work with the results.
