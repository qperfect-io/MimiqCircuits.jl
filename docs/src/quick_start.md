# Quick Start

In this tutorial, we will walk you through the fundamental procedures for simulating a quantum circuit using MIMIQ. Throughout the tutorial, we will provide links to detailed documentation and examples that can provide a deeper understanding of each topic.

- [Quick Start](#quick-start)
  - [Install and load MIMIQ](#install-and-load-mimiq)
  - [Connect to remote service](#connect-to-remote-service)
  - [Example: Simulate a GHZ circuit](#example-simulate-a-ghz-circuit)
    - [Construct basic circuit](#construct-basic-circuit)
    - [Measure, add noise, and extract information](#measure-add-noise-and-extract-information)
    - [Execute circuit](#execute-circuit)
      - [OpenQASM and Stim](#openqasm-and-stim)

## Install and load MIMIQ

To install MIMIQ, please [open Julia's interactive session (REPL)](https://docs.julialang.org/en/v1/manual/getting-started/), then press the `]` to start using the package manager mode, then type the following commands.

If it is the first time opening julia update the list of packages

```julia
update
```

Then add QPerfect's registry of Julia packages:

```julia
registry add https://github.com/qperfect-io/QPerfectRegistry.git
```

To install `MimiqCircuits`, to its last **stable** release,

```julia
add MimiqCircuits
```

Check the [installation](manual/installation.md) page for more details.

In order to use MIMIQ, we simply need to load the `MimiqCircuit` Julia module within your workspace like this:

```julia
using MimiqCircuits
```

## Connect to remote service

To execute circuits you have to connect to MIMIQ's remote service, which can be achieved with a single instruction

```julia
conn = connect()
```

```@example quick_start
using MimiqCircuits # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=QPERFECT_CLOUD2) # hide
```

For more details see [`cloud execution page`](manual/remote_execution.md) or see the documentation of [`connect`](@ref). If executed without supplemental arguments, `connect()` will start a local webpage and will try to open it with your default browser. As an alternative, `connect("john.smith@example.com", "jonspassword")` allows to insert directly the username and password of the user.

!!! note
    In order to complete this step you need an active subscription to MIMIQ. To obtain one, please [contact us](https://qperfect.io) or, if your organization already has a subscription, contact the organization account holder.

## Example: Simulate a GHZ circuit

### Construct basic circuit

A circuit is basically a sequence of quantum operations (gates, measurements, etc...) that act on a set of qubits and potentially store information in a classical or "z" register (see [circuit page](manual/circuits.md)). The classical register is a boolean vector to store the results of measurements, and the z register is a complex vector to store the result of mathematical calculations like expectation values.

The MIMIQ interface is similar to other software, but there are some important differences:

- There are no hardcoded quantum registers. Qubits are simply indicated by an integer index starting at 1 (Julia convention). The same for classical and z registers.
- A [`Circuit`](@ref) object doesn't have a fixed number of qubits. The number of qubits in a circuit is taken from looking at the qubits the gates are applied to. It is the maximum integer index used in a circuit. The same for the number of classical bits.

To construct a GHZ circuit, we start by defining an empty [`Circuit`](@ref)

```@example quick_start
using MimiqCircuits # hide
circuit = Circuit()
```

The most important tool to build circuits is the [`push!`](@ref) function. It is used like this: `push!(circuit, quantum_operation, targets...)`. It accepts a circuit, a single quantum operation, and a series of targets, one for every qubit or bit the operation supports.

We apply a [`GateH`](@ref) on the first qubit as

```@example quick_start
push!(circuit, GateH(), 1)
```

The text representation `H @ q[1]` informs us that there is an instruction which applies the Hadamard gate to the qubit with index `1`.
Note that qubits start by default in the state `0`.

Multiple gates can be added at once through the same [`push!`](@ref) syntax using iterables, see [circuit](manual/circuits.md) and [unitary gates](manual/unitary_gates.md) page for more information.
To prepare a 5-qubit GHZ state, we add 9 [`CX`](@ref GateCX) or control-`X` gates between the qubit 1 and all the qubits from 2 to 5.

```@example quick_start
push!(circuit, GateCX(), 1, 2:5)
```

### Measure, add noise, and extract information

We can extract information about the state of the system (without affecting the state) at any point in the circuit, see [statistical operations](manual/statistical_ops.md) page.
For example, we can compute the expectation value of ``| 11 \rangle\langle 11 |`` of qubits 1 and 5, and store it in the first z register as:

```@example quick_start
push!(circuit, ExpectationValue(Projector11()), 1, 5, 1)
```

We can measure the qubits and add other [non-unitary operations](manual/non_unitary_ops.md) at any point in the circuit, for example:

```@example quick_start
push!(circuit, Measure(), 1:5, 1:5)
```

Here, we measure qubits 1 to 5 and store the result in classical register 1 to 5.
In general, the ordering of targets is always like `push!(circ, op, quantum_targets..., classical_targets..., z_targets...)`.

!!! warning
    Classical and z registers can be overwritten. If you do `push!(circuit, Measure(), 1, 1)` followed by `push!(circuit, Measure(), 2, 1)`, the second measurement will overwrite the first one since it will be stored on the same classical register 1. To avoid this in a circuit with many measurements you can, for example, keep track of the index of the last used register.

To simulate imperfect quantum computers we can add noise to the circuit. Noise operations can be added just like any other operations using `push!`. However, noise can also be added after the circuit has been built to all gates of a certain type using [`add_noise!`](@ref). For example:

```@example quick_start
add_noise!(circuit, GateH(), AmplitudeDamping(0.01))
add_noise!(circuit, GateCX(), Depolarizing2(0.1); parallel=true)
add_noise!(circuit, Measure(), PauliX(0.05); before=true, parallel=true)
```

See [symbolic operations](manual/symbolic_ops.md) and [special operations](manual/special_ops.md) pages for other supported operations.

The number of qubits, classical bits, and complex z-values of a circuit can be obtained from:

```@example quick_start
numqubits(circuit), numbits(circuit), numzvars(circuit)
```

A circuit behaves in many ways like a vector (of instructions, i.e. operations + targets). You can get the length as `length(circuit)`, access elements as `circuit[2]`, insert elements with [`insert!`](@ref), append other circuits with [`append!`](@ref) etc. You can also visualize circuits with [`draw`](@ref). See [circuit page](manual/circuits.md) for more information.

### Execute circuit

Executing a circuit on MIMIQ requires three steps:

1. opening a connection to the MIMIQ Remote Services (which we did at the beginning of the tutorial),
2. send a circuit for execution,
3. retrieve the results of the execution.

After a connection has been established, an execution can be sent to the remote services using [`execute`](@ref).

```@example quick_start
job = execute(conn, circuit)
```

This will execute a simulation of the given circuit with default parameters. The default choice of algorithm is `"auto"`.  Generally, there are three available options:

* `"auto"` for the automatically selecting the best algorithm according to circuit size and complexity,
* `"statevector"` for a highly optimized state vector engine, and
* `"mps"` for the large-scale Matrix Product States (MPS) method.

Check out the documentation of the [`execute`](@ref) function for details.

Once the execution has finished, the results can be retrieved via the [`getresults`](@ref) function, which returns a [`QCSResults`](@ref) structure.

```@example quick_start
res = getresult(conn, job)
```

To make a histogram out of the retrieved samples, it suffices to execute

```@example quick_start
histsamples(res)
```

To plot the results (works both with [Plots.jl](https://docs.juliaplots.org/stable/) and [Makie.jl](https://docs.makie.org/stable/)) you can use

```@example quick_start
using Plots
plot(res)
```

Check the [`cloud execution`](manual/remote_execution.md) page for more details on job handling.



#### OpenQASM and Stim

OpenQASM and Stim files, defining quantum algorithms can be executed on MIMIQ in the same way native circuits can, simply use [`execute`](@ref) and provide the path of the file to upload.
See the [import-export](manual/import_export.md) page for more details on how include files are handled.

