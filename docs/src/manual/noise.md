# Noisy simulations on MIMIQ

Here we explain how to run noisy simulations that mimic the behavior of real
quantum computers on MIMIQ. In this section you'll find:

- [Noisy simulations on MIMIQ](#noisy-simulations-on-mimiq)
	- [Summary of noise functionality](#summary-of-noise-functionality)
	- [Mathematical background](#mathematical-background)
		- [Kraus operators](#kraus-operators)
		- [Evolution with noise](#evolution-with-noise)
	- [Building noise channels](#building-noise-channels)
	- [How to add noise](#how-to-add-noise)
		- [Adding noise one by one](#adding-noise-one-by-one)
		- [Adding noise to all gates of same type](#adding-noise-to-all-gates-of-same-type)
	- [Running a noisy circuit](#running-a-noisy-circuit)

## Summary of noise functionality

Custom noise channels:

* [`Kraus`](@ref)
* [`MixedUnitary`](@ref)

Specialized noise channels:

* [`Depolarizing`](@ref)
* [`Depolarizing1`](@ref)
* [`Depolarizing2`](@ref)
* [`PauliNoise`](@ref)
* [`PauliX`](@ref)
* [`PauliY`](@ref)
* [`PauliZ`](@ref)
* [`AmplitudeDamping`](@ref)
* [`GeneralizedAmplitudeDamping`](@ref)
* [`PhaseAmplitudeDamping`](@ref)
* [`ThermalNoise`](@ref)
* [`ProjectiveNoise`](@ref)

Note that the [`Reset`](@ref) type operations can also be thought of as noisy operations.
Coherent noise can be added by using any of the supported gates ([MimiqCircuitsBase.GATES](@ref)).

Noise channels come with the following methods:

* [`krausmatrices`](@ref) and [`krausoperators`](@ref)
* [`unitarymatrices`](@ref) and [`unitarygates`](@ref) (only for mixed-unitary)
* [`probabilities`](@ref) (only for mixed-unitary)
* [`ismixedunitary`](@ref)

To add noise channels to a circuit you can use:

* [`push!`](@ref) (like gates)
* [`add_noise`](@ref) or [`add_noise!`](@ref) (add noise to every instance of a gate)

To generate one sample of a circuit with mixed unitaries use:

* [`sample_mixedunitaries`](@ref)

See below for further information. You can also run `?` followed by the given function in the command line (e.g. `?Kraus`), or using `@doc` in Jupyter (e.g. `@doc Kraus`).

## Mathematical background

### Kraus operators

Noise in a quantum circuit refers to any kind of unwanted interaction of the qubits with the environment (or with itself).
Mathematically, this puts us in the framework of _open_ systems and the state of the qubits now needs to be described in terms of a density matrix ``\rho``, which fulfills ``\rho=\rho^\dagger``, ``\mathrm{Tr} \rho = 1``.
A quantum operation such as noise can then be described using the _Kraus_ operator representation as
```math
	\mathcal{E}(\rho) = \sum_k E_k \rho E_k^\dagger.
```
We consider only _completely positive and trace preserving_ (CPTP) operations.
In this case, the Kraus operators ``E_k`` can be any matrix as long as the fulfill the completeness relation ``\sum_k E_k^\dagger E_k = I``. Note that unitary gates ``U`` just correspond to a single Kraus operator, ``E_1=U``.

When all Kraus operators are proportional to a unitary matrix, ``E_k = \alpha_k U_k``, this is called a _mixed-unitary_ quantum operation and can be written as (``p_k = |\alpha_k|^2``)
```math
	\mathcal{E}(\rho) = \sum_k p_k U_k \rho U_k^\dagger.
```
Such operations are easier to implement as we'll see below.

Remarks:
- Unitary gates ``U`` just correspond to a single Kraus operator, ``E_1=U``.
- The number of Kraus operators depends on the noise considered.
- For a given quantum operation $\mathcal{E}$ the Kraus operator representation is not unique. One can change the basis of Kraus operators using a unitary matrix ``U`` as ``\tilde{E}_i = \sum_j U_{ij} E_j``.

We define a _noise channel_ (or _Kraus channel_) as a quantum operation ``\mathcal{E}`` described by a set of Kraus operators as given above.
A common way of modeling noisy quantum computers is by considering each operation ``O`` that happens in the circuit as a noisy quantum operation ``\mathcal{E}_O``.
The full noisy operation can in principle be described using Kraus operators, but usually it is decomposed as ``\tilde{O} = \mathcal{E}_2 \circ O \circ \mathcal{E}_1``, where ``\mathcal{E}_1`` and ``\mathcal{E}_2`` are noise channels.
In the case of gates we usually only consider a noise channel after the gate.
Note that one common assumption in this type of noise modeling is that the noise channels of different gates are independent from each other.

For more details on noise see for example _Nielsen and Chuang, Quantum Computation and Quantum Information, Chapter 8_.

### Evolution with noise

There are two common ways to evolve the state of the system when acting with Kraus channels as defined above:

1. **Density matrix:** If we use a density matrix to describe the qubits, then a Kraus channel can simply be applied by directly performing the matrix multiplications as ``\mathcal{E}(\rho) = \sum_k E_k \rho E_k^\dagger``. The advantage of this approach is that the density matrix contains the full information of the system and we only need to run the circuit once. The disadvantage is that ``\rho`` requires more memory to be stored (``2^{2N}`` as opposed to ``2^N`` for a state vector) so we can simulate fewer qubits.

2. **Quantum trajectories:** This method consists in simulating the evolution of the state vector ``|\psi_\alpha \rangle`` for a set of iterations ``\alpha = 1, \ldots, n``. In each iteration a noise channel is applied by randomly selecting one of the Kraus operators according to some probabilities (see below) and applying that Kraus operator to the state vector. The advantage of this approach is that we need less memory since we work with a state vector. The disadvantage is that we need to run the circuit many times to collect samples (one sample per run).

Currently, MIMIQ only implements the quantum trajectories method.

The basis for quantum trajectories is that a Kraus channel can be rewritten as
```math
	\mathcal{E}(\rho) = \sum_k p_k \tilde{E}_k \rho \tilde{E}_k^\dagger,
```
where ``p_k = \mathrm{Tr}(E_k \rho E_k^\dagger)`` and $\tilde{E}_k = E_k / \sqrt{p_k}$.
The parameters ``p_k`` can be interpreted as probabilities since they fulfill ``0 \leq p_k \leq 1`` and ``\sum_k p_k = 1``.
In this way, the Kraus channel can be viewed as a linear combination of operations with different Kraus operators weighted by the probabilities ``p_k``.
Note that the probabilities ``p_k`` generally depend on the state, so they need to be computed at runtime. The exception is mixed-unitary channels, for which the probabilities are fixed (state-independent), see above.

## Building noise channels

You can create noise channels using one of the many functions available, see [summary](#summary-of-noise-functionality). Most of the noise channels take one or more parameters, and the custom channels require passing the Kraus matrices and/or probabilities. Here are some examples of how to build noise channels:

```@example noise
using MimiqCircuits
p = 0.1    # probability
PauliX(p)
```

```@example noise
p, gamma = 0.1, 0.2    # parameters
GeneralizedAmplitudeDamping(p,gamma)
```

```@example noise
ps = [0.8,0.1,0.1]    # probabilities
paulis = ["II","XX","YY"]    # Pauli strings
PauliNoise(ps,paulis)
```

```@example noise
ps = [0.9, 0.1]    # probabilities
unitaries = [[1 0; 0 1], [1 0; 0 -1]]    # unitary matrices
MixedUnitary(ps, unitaries)
```

```@example noise
kmatrices = [[1 0; 0 sqrt(0.9)], [0 sqrt(0.1); 0 0]]    # Kraus matrices
Kraus(kmatrices)
```

Check the documentation of each noise channel to understand the conditions that each of the parameters needs to fulfill for the noise channel to be valid.

In MIMIQ the most important distinction of noise channels is between _mixed unitary_ and general Kraus channels (see [mathematical section](#mathematical-background) for definitions). You can use [`ismixedunitary`](@ref) to check if a channel is mixed unitary or not like this:

```@example noise
ismixedunitary(PauliX(0.1))
```

```@example noise
ismixedunitary(AmplitudeDamping(0.1))
```

In both cases you can get the Kraus matrices/operators used to define the given channel by using [`krausmatrices`](@ref) or [`krausoperators`](@ref). For example:

```@example noise
krausmatrices(ProjectiveNoise("Z"))
```

In the case of mixed unitary channels, you can separately obtain the list of probabilities and the list of unitary gates/matrices using [`probabilities`](@ref) and [`unitarymatrices`](@ref) 
or [`unitarygates`](@ref), respectively.

```@example noise
unitarymatrices(PauliZ(0.1))
```

```@example noise
unitarygates(Depolarizing1(0.1))
```

```@example noise
probabilities(PauliNoise([0.1,0.9],["II","ZZ"]))
[0.1 0.9] # hide
```

In MIMIQ, noise channels can be added at any point in the circuit in order to make any operation noisy. For noisy gates, one would normally add a noise channel after an ideal gate. To model measurement, preparation and reset errors one can simply add noise channels before and/or after the corresponding operation. More information in the next section.

## How to add noise

### Adding noise one by one

The simplest and most flexible way to add noise to a circuit is by using `push!`(@ref), the same way that we add gates. Here's an example of how to create a noisy 5-qubit GHZ circuit:

```@example noise
c = Circuit()
push!(c, PauliX(0.1), 1:5)    # preparation/reset error since all qubits start in 0

push!(c, GateH(), 1)
push!(c, AmplitudeDamping(0.1), 1)    # 1-qubit noise for GateH

push!(c, GateCX(), 1, 2:5)
push!(c, Depolarizing2(0.1), 1, 2:5)    # 2-qubit noise for GateCX

push!(c, PauliX(0.1), 1:5)    # measurement error. Note it's added before the measurement
push!(c, Measure(), 1:5, 1:5)
```

Note how we added bit-flip error ([`PauliX`](@ref)) at beginning for state preparation/reset errors and right before measuring for measurement errors.

### Adding noise to all gates of same type

Usually, when we add noise to a circuit we want to add the same type of noise to each instance of a given gate. For this purpose, instead of adding noise channels one by one you can use [`add_noise`](@ref) or [`add_noise!`](@ref) (same but in-place). It takes several parameters:

`add_noise(c, g, kraus; before=false, parallel=false)`

This function will add the noise channel specified by `kraus` to every instance of gate `g` in the circuit `c`. The optional parameter `before` (default=`false`) determines whether to add the noise before or after the operation, and the parameter `parallel` (default=`false`) determines whether to add the noise in parallel after/before a block of transversal gates.

Here is how to construct the same example of a noisy GHZ circuit as before but with `add_noise`:

```@example noise
c = Circuit()
push!(c, Reset(), 1:5)
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2:5)
push!(c, Measure(), 1:5, 1:5)

cnoise = add_noise(c, Reset(), PauliX(0.1); parallel=true)
cnoise = add_noise(cnoise, GateH(), AmplitudeDamping(0.1))
cnoise = add_noise(cnoise, GateCX(), Depolarizing2(0.1); parallel=true)
cnoise = add_noise(cnoise, Measure(), PauliX(0.1); before=true, parallel=true)
```

Note that we added a trivial `Reset` operation at the very beginning just to be able to add the state preparation error with the `add_noise` functionality. The qubits already start at 0 anyway.

The `add_noise` function becomes particularly useful in big circuits with lots of repetitions of gates. For further details check the API documentation of [`add_noise`](@ref) and [`add_noise!`](@ref).

## Running a noisy circuit

Circuits with noise can be run with the same [`execute`](@ref) function as used for circuits without noise, see [simulation](simulation.md) and [cloud execution](remote_execution.md) pages.
Recall that currently noisy simulations will be run using [quantum trajectories](#evolution-with-noise).
In this case, when running a circuit with noise for `n` samples the circuit will internally be run once for every sample.
In every run, a different set of random Kraus operators will be selected based on the corresponding probabilities.

When the noise channel is a mixed unitary channel the unitary operators to be applied can be selected before starting to apply operations on the state. We provide the function [`sample_mixedunitaries`](@ref) to generate samples of a circuit with mixed unitary noise as follows:

```@example noise
using Random
rng = MersenneTwister(42)

c = Circuit()
push!(c, Depolarizing1(0.5), 1:5)

# Produce a circuit with either I, X, Y, or Z in place of each depolarizing channel
csampled = sample_mixedunitaries(c; rng=rng, ids=true)
```

This function is internally called when executing a circuit, but can also be used outside of execution.
