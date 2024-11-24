# Overview

This manual introduces all concepts and syntax necessary to use MIMIQ to its fullest capabilities.

MIMIQ is a [quantum circuit](https://en.wikipedia.org/wiki/Quantum_circuit) simulator framework.
It allows to numerically calculate the effect of applying quantum operations on quantum objects like qubits.
[Mathematically](https://en.wikipedia.org/wiki/Quantum_computing), this is a linear algebra problem where a complex vector representing the quantum state of qubits
is sequentially updated through multiplication with matrices that represent operations.

The manual starts by introducing the central object of this framework: the [`Circuit`](@ref) (see [circuit page](circuits.md)).
A [`Circuit`](@ref) is essentially a vector of [`Instruction`](@ref)s to be applied to the qubits.
An [`Instruction`](@ref) contains information about the quantum operation to be applied and the desired targets of the operation.
We call the targets *registers* and there are three types:

- **Quantum** registers represent the qubits (``|0\rangle`` or ``|1\rangle``).
  They are indexed from 1 to ``N`` and their state representation depends on the [simulator backend](simulation.md) chosen. 
- **Classical** registers represent boolean information (0 or 1) that can be used to store the result of measuring the state of the qubits.
  They are represented by a vector of `Bool`s.
- **Z** registers represent complex number information that can be used to store the result of mathematical calculations on the quantum state such as expectation values.
  They are represented by a vector of `Complex` numbers.

MIMIQ supports many different types of quantum operations to apply to these registers. Some of these operations correspond to physical operations one could perform
on a real quantum computer, whereas other operations are mathematical operations only possible in a simulation framework.
The manual introduces the following types of operations:

- [Unitary Gates](unitary_gates.md) correspond to transformations of the quantum state that preserve the norm (i.e. unitary matrices), and are usually the basis of quantum algorithms.
- [Non-unitary Operations](non_unitary_ops.md) encompass both measurement and reset operations that project the quantum state and are physically implementable,
  as well as more general operators, i.e. linear transformations, which are only mathematical tools. We include also conditional logic (*if* statements) in this category.
- [Noise](noise.md) is a type of non-unitary operation describing the effect of the environment on the qubits. We discuss it separately because it has its own intricacies (Kraus operators).
- [Statistical Operations](statistical_ops.md) correspond to all mathematical operations that are only possible inside the simulation framework (e.g. expectation values, entanglement measures...),
  which however do not change the quantum state of the qubits.
- [Special Operations](special_ops.md) such as more complex composite gates (e.g. QFT, oracles...) or custom gate declarations.

Until here, all these tools allow the user to define a circuit.
In order to simulate the circuit MIMIQ offers two backends: a State Vector (SV) simulator, and a Matrix-Product States (MPS) simulator. These are introduced in the [simulation page](simulation.md).
The SV simulator allows to run calculations exactly for small systems up to 32 qubits in the remote server, whereas the MPS simulator uses efficient compression techniques
and can simulate large-scale circuits either exactly (if entanglement is bound), or approximately. In the latter case, a fidelity helps the user estimate the accuracy of the approximation.

The circuits are executed remotely, using a Cloud Service that gives the user access to large resources and high-performance hardware.
Details on the cloud interface are discussed in the [cloud execution page](remote_execution.md).

MIMIQ uses its own `Protobuf` based format to export and import circuits defined through the MIMIQ language.
However, it also allows to import and execute circuits from files written in `OpenQASM` or `Stim` format. This is all discussed in the [import-export page](import_export.md).

The [last section](special_topics.md) discuss some special topics such as bitstrings.