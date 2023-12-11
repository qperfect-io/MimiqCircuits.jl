# Tutorial

In this guide, we will walk you through the fundamental procedures for simulating a quantum circuit using MIMIQ-CIRC product developed by QPerfect. Throughout the tutorial, we will furnish links to detailed documentation and examples that can provide a deeper understanding of each topic.

In order to use MIMIQ-CIRC, we need to first load the `MimiqCircuit` Julia module within your workspace by following this step:

```julia
using MimiqCircuits
```

# Building a Quantum circuit

The first step in executing quantum algorithm on MIMIQ-CIRC always consists in defining one implementation of the algorithm as a quantum circuit, a sequence of quantum operations (quantum gates, measurements, resets, etc...) that act on a set of qubits. In MIMIQ-CIRC we always start by defining an empty circuit

```@example ghz
using MimiqCircuits # hide
circuit = Circuit()
```

In `MimiqCircuits` we do not need to specify the number of qubits of a circuit, or a list of quantum registers to use. Qubits will be allocated up to the maximum used index. Since in Julia indices start counting from one, also qubits indices are allowed values between ``1`` and ``2^{63}-1``.

A circuit is made up of quantum operations. Gates, or unitary operations, are the simplest and most common ones. Lists are provided by the documentation of [`MimiqCircuitsBase.OPERATIONS`](@ref), [`MimiqCircuitsBase.GATES`](@ref) and [`MimiqCircuitsBase.GENERALIZED`](@ref), which can also be simply accessed by

```julia
?GATES
```

To add gates to circuits in Julia we will be using the `puhs!` function, which takes multiple arguments, but usually: the circuit to add the operation to, the operation to be added, and as many target qubits as possible.

In this first simple example [`MimiqCircuitsBase.GateH`], only needs one target

```@example ghz
push!(circuit, GateH(), 1)
```

The text representation `H @ q[1]` informs us that there is an instruction which applies the Hadamard gate to the qubit of index `1`.

Multiple gates can be added at once through the same `push!` syntax. In the following example we add 9 `CX` or control-`X` gates between the qubit 1 and all the qubits from 2 to 10.

```@example ghz
push!(circuit, GateCX(), 1, 2:10)
```

This syntax is not dissimilar to the OpenQASM one, and can be seen as equivalent of

```julia
for i in 2:10
    push!(circuit, GateCX(), 1, i)
end
```

The same is true for adding operations that act also on classical bits

```@example ghz
push!(circuit, Measure(), 1:10, 1:10)
```

which is equivalent to

```julia
for i in 1:10
    push!(circuit, Measure(), i, i)
end
```

The number of quantum bits and classical bits of a circuit is defined by the maximum index used, so in this case 10 for both.

```example ghz
numqubits(circuit), numbits(circuit)
```

With these informations, it is already possible to build any quantum circuit. However, for alternative advanced circuit building utilities see the documentation of [`MimiqCircuitsBase.emplace!`](@ref), and [`MimiqCircuitsBase.Circuit`](@ref).

# Remote execution on MIMIQ-CIRC

In order to execute the implemented circuit on MIMIQ-CIRC three more steps are required:

1. opening a connection to the MIMIQ Remote Services,
2. send a circuit for execution,
3. retrieve the results of the execution.

## Connecting to MIMIQ

In most cases, connecting to MIMIQ can achieved by a single instruction

```julia
conn = connect()
```

```@example ghz
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=QPERFECT_CLOUD2) # hide
```

For more options please see the documentation of [`MimiqLink.connect`](@ref). If executed without supplemental arguments, `connect()` will start a local webpage and will try to open it with your default browser. As an alternative, `connect("john.smith@example.com", "jonspassword")` allows to insert directly the username and password of the user.

!!! note
    In order to complete this step you need an active subscription to MIMIQ-CIRC. To obtain one, please [contact us](https://qperfect.io) or, if your organization already has a subscription, contact the organization account holder.


## Executing a circuit on MIMIQ

Once a connection is established an execution can be sent to the remote services.

```@example ghz
job = execute(conn, circuit)
```

This will execute a simulation of the given circuit with default parameters. The default choice of algorithm is `"auto"`.  Generally, there are three available options:

* `"auto"` for the automatically selecting the best algorithm according to circuit size and complexity,
* `"statevector"` for a highly optimized state vector engine, and
* `"mps"` for a large-scale Matrix Product States (MPS) method.

Check out the documentation of the [`MimiqCircuits.execute`](@ref) function, for details.

### OpenQASM

OpenQASM files, defining quantum algorithms can be executed on MIMIQ in the same way native circuits can, simply use [`MimiqCircuits.executeqasm`](@ref) and provide the path of the file to upload.
See the [OpenQASM](manual/openqasm.md) page for more details on how include files are handled.

## Retrieving execution results

Once the execution has terminated on MIMIQ, the results can be retrieved via the [`MimiqCircuits.getresults`](@ref) function, which returns a [`MimiqCircuitsBase.QCSResults`](@ref) structure.

```@example ghz
res = getresults(conn, job)
```

Name and version of the simulator, samples, and timings can be retrieved from the aggregated results. For example, to make an histogram out of the retrieved samples, it suffices to execute

```@example ghz
histsamples(res)
```

To plot the results (works both with [Plots.jl](https://docs.juliaplots.org/stable/) and [Makie.jl](https://docs.makie.org/stable/))

```@example ghz
using Plots
plot(res)
```

## Retrieving submitted remote jobs

```@example ghz
c, params = getinputs(conn, job)

# showing back the executed circuit, retrieeved from MIMIQ
c
```
