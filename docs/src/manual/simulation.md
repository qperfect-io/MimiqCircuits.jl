# Simulating circuits

This page provides information on how MIMIQ simulates quantum circuits.

- [Simulating circuits](#simulating-circuits)
  - [Simulator backends](#simulator-backends)
    - [State Vector](#state-vector)
    - [Matrix-Product States](#matrix-product-states)
  - [Fidelity and Error estimates](#fidelity-and-error-estimates)
  - [Understanding sampling](#understanding-sampling)


## Simulator backends

To execute quantum circuits with MIMIQ you can use different simulator backends, i.e. different numerical methods to apply operations to the state of the qubits. Here we give a short introduction into these methods.

### State Vector

The pure quantum state of a system of `N` qubits can be represented exactly by `2N` complex numbers. The state vector method consists in explicitly storing the full state of the system and evolving it exactly as described by the given quantum algorithm. The method can be considered **exact** up to machine precision errors (due to the finite representation of complex numbers on a computer). Since every added qubit doubles the size of the state, this method is practically impossible to be used on systems > 50 qubits. On a laptop with 8GB of free RAM, only 28-29 qubits can be simulated.

On our current remote service, we can simulate circuits of up to 32 qubits with this method. Premium plans and on-premises solutions are designed to increase this limit. If you are interested, contact us at contact@qperfect.io.

Our state vector simulator is highly optimized for simulation on a single CPU, delivering a significant speedup with respect to publicly available alternatives.

**Performance Tips:**

The efficiency of the state vector simulator can depend on the specific way that the circuit is implemented. Specifically, it depends on how gates are defined by the user. The most important thing is to avoid using [`GateCustom`](@ref) whenever possible, and instead use specific gate implementations. For example, use `GateX()` instead of `GateCustom([0 1; 1 0])`, and use `CU(...)` instead of `GateCustom([1 0 0 0; 0 1 0 0; 0 0 U_{11} U_{12}; 0 0 U_{21} U_{22}])`.


### Matrix-Product States

Matrix-Product States algorithms were originally developed within the field of many-body quantum physics (see [Wikipedia article](https://en.wikipedia.org/wiki/Matrix_product_state) and references therein), and offer an alternative approach to scale up the size of simulations. Instead of tracking the entire state, MPS captures the entanglement structure efficiently. This method excels in scenarios where entanglement is localized, offering computational advantages and reducing memory requirements compared to state vector simulations. The benefits of MPS include its ability to simulate larger quantum systems and efficiently represent states with substantial entanglement. However, challenges arise when dealing with circuits that exhibit extensive long-range entanglement.

Our MPS simulator is optimized for speed of execution and fidelity. For entanglement bound circuits MPS can calculate circuits of even hundreds of qubits exactly. For circuits with too much entanglement MPS calculates approximate solutions and provides a lower bound estimate of the real fidelity of the calculation (see next section).

**Performance Tips:**

The efficiency of the MPS simulation can depend on implementation details.
To optimize performance, you can vary the following parameters that specify the level of approximation and compression (see also [Execution page](remote_execution.md)):

- **Bond dimension** (bonddim): The bond dimension specifies the maximal dimension of the matrices that appear in the MPS representation. Choosing a larger *bonddim* means we can simulate more entanglement, which leads to larger fidelities, at the cost of more memory and typically longer run times. However, when *bonddim* is chosen large enough that the simulation can be run exactly, then it generally runs much faster than lower bond dimensions. The default is 256.

- **Entanglement dimension** (entdim): The entanglement dimension is related to the way gates are applied to the state. In some cases, a large *entdim* can lead to better compression and thus shorter runtimes, at the potential cost of more memory. In others, a lower *entdim* is more favourable. The default is 16.

Moreover, the performance of MPS, especially the bond dimension required, also depends on the specific way that circuits are implemented. Here are some general tips:

- **Qubit ordering:** The most crucial choice that affects MPS performance is the ordering of qubits in the circuit. If we have qubits 1 to N, it matters which qubit of the algorithm has which index. Ideally, the indices should be chosen such that qubits that are strongly entangled during the circuit are close to each other, i.e. small `|i-j|` where `i` and `j` are indices. When a good ordering is chosen, this will translate into lower bond dimensions.

- **Gate ordering:** In nature, the order of transversal gates, or gates that commute with each other, does not play a role. However, for MPS it can change the performance. The reason is that in a simulation we typicall apply gates, even transversal ones, sequentially. During the application of the gates, the entanglement of the intermediate state can depend on the order in which the gates are applied. Thus, experimenting with different gate orderings can lead to better performance, typically because of lower bond dimensions.

You can access the bond dimensions of the state during execution through [BondDim](@ref), see also page on [entanglement](statistical_ops.md). This can be helpful to understand the effect of different optimizations.


## Fidelity and Error estimates

Since we allow for the execution of circuits on MIMIQ with non exact methods (MPS), we return always a **fidelity estimate** for each execution.

Fidelity in this case is defined as the squared modulus of the overlap between the final state obtained by the execution and the ideal one. It is a number between `0` and `1`, where `1` means that the final state is exactly the one we wanted to obtain.

The fidelity will always be `1.0` for exact methods (State Vector), but it can be less than that for non exact methods.

In the case of **MPS** methods, the number returned is an estimate of the actual fidelity of the state. More specifically, it is a **lower bound** for the fidelity, meaning that the actual fidelity will always be larger or equal to the number reported.
For example, if the fidelity is 0.8 it means that the state computed by MPS has at least an 80% overlap with the real solution.


## Understanding sampling

When running a circuit with MIMIQ we compute and return measurement samples, among other quantities (see [Cloud Execution](remote_execution.md) section). Which measurement samples are returned depends on the type of circuit executed. There are three fundamental cases based on the presence of [non-unitary operations](non_unitary_ops.md) such as measurements ([Measure](@ref)...), resets ([Reset](@ref)), if statements ([IfStatement](@ref)), or [noise](noise.md).

**No non-unitary operations**

In this case the circuit is executed only once and the final state is sampled as many times as specified by the  number of samples (`nsamples`) parameter of the execution. The sampled value of all the qubits is returned (in the obvious ordering).

**No mid-circuit measurements and no non-unitary operations**

In this case the circuit is executed only once again, and the final state is sampled as many times as specified by `nsamples`, but only the sampled value of all the classical bits used in the circuit is returned (usually the targets of the measurements at the end of the circuit).

**Mid-circuit measurements or non-unitary operations**

In this case the circuit is executed `nsamples` times, and the final state is sampled only once per run. The sampled value of all the classical bits used in the circuit is returned.




