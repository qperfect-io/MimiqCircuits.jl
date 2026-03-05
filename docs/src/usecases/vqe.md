# Variational Optimization

MIMIQ includes a lightweight workflow to optimize symbolic circuits against
a scalar cost accumulated in the Z-register (e.g., the expectation value of a Hamiltonian).
This enables a broad class of Variational Quantum Algorithms (VQAs), including
the Variational Quantum Eigensolver (VQE) and related variational tasks.

---

- [Variational Optimization](#variational-optimization)
  - [Concepts](#concepts)
  - [Quick Start: VQE in MIMIQ](#quick-start-vqe-in-mimiq)
  - [Running Optimization on Cloud](#running-optimization-on-cloud)

---

## Concepts

**Variational Quantum Algorithms (VQAs)** are hybrid quantum–classical methods that
optimize a parameterized quantum circuit against a classical cost function. Different
choices of cost define different algorithms (e.g., **QAOA**, variational classifiers), and
**VQE** is one such example.

**Variational Quantum Eigensolver (VQE)** approximates the ground-state energy of a
Hamiltonian \(H\) and is a specific instance of the broader VQA family.

The method relies on:

- A **parameterized ansatz** \(|\psi(\vec{\theta})\rangle\) prepared by a quantum circuit
- A **cost function** given by the energy expectation value

```math
E(\vec{\theta}) \;=\;
\langle \psi(\vec{\theta}) \,|\, H \,|\, \psi(\vec{\theta}) \rangle
```

The parameters \(\vec{\theta}\) are updated by a **classical optimizer** to minimize
\(E(\vec{\theta})\). At convergence, the variational principle guarantees

```math
E(\vec{\theta}^*) \;\geq\; E_0
```

where \(E_0\) is the true ground-state energy of \(H\).

---

## Quick Start: VQE in MIMIQ

We use the **1D Ising Hamiltonian** and define a simple RX/RY ansatz. Then we define the cost as the **energy** \(\langle H \rangle\) and optimize it.

**Build the Ising Hamiltonian**

```@example vqe
using MimiqCircuits # hide

N = 4          # number of spins / qubits
J = 1.0        # interaction strength
h = 0.5        # transverse field

H = Hamiltonian()
for j in 1:(N-1)
    push!(H, -J, PauliString("ZZ"), j, j+1)
end

for j in 1:N
    push!(H, -h, PauliString("X"), j)
end

display(H)
```

**Define a symbolic ansatz \( |\psi(\theta)\rangle \)**

```@example vqe

x = [variable(Symbol("x_$i")) for i in 1:N]
y = [variable(Symbol("y_$i")) for i in 1:N]

c = Circuit()
for q in 1:N
    push!(c, GateRX(x[q]), q)
    push!(c, GateRY(y[q]), q)
end

display(c)
```

**Append the cost (accumulate ⟨H⟩ into z[1])**

```@example vqe

push_expval!(c, H, 1:N..., firstzvar=1)
display(c)
```

The expectation value of the Hamiltonian is accumulated in the Z-register.
This defines the cost function for optimization.

**Create the `OptimizationExperiment`**

An `OptimizationExperiment` specifies:

- the **symbolic quantum circuit**,
- the **initial parameter values**,
- the **classical optimizer** to use,
- and additional **experiment settings** (such as label, maximum iterations, and
  the Z-register index where the cost is accumulated).

```@example vqe

init = Dict(v => 0.0 for v in listvars(c))

exp = OptimizationExperiment(c, init, optimizer  = "COBYLA",maxiters   = 50, zregister  = 1,)

display(exp)
```

## Running Optimization on Cloud

You can submit a single `OptimizationExperiment` or a list of them
to the MIMIQ Cloud. The return type depends on the `history` flag:

- If `history=true` you will receive an `OptimizationResults`,
  which contains the best run and the full history of runs.
- If `history=false` (default), you will receive only the best
  `OptimizationRun`.

An `OptimizationRun` represents a **single evaluation of the cost
function** during optimization. It contains:

- the **final cost value** for the given parameters,
- the **parameter values** used in that evaluation,
- and the **raw execution results** (`QCSResults`) from the quantum
  simulation or hardware.

An `OptimizationResults` collects all runs into a history and
tracks the **best run** found during the optimization.

---

The snippet below **assumes** you already constructed `exp` as in the Ising
example above.

**Connect to the cloud**

```julia
conn = connect()
```

**Submit the optimization job (choose backend/algorithm)**

```julia
job = optimize(conn, exp; algorithm="mps", history=true, label="ising_vqe")
```

**Retrieve results (blocks until the job finishes)**

```julia
optres = getresult(conn, job)   # use getresults(conn, job) for a batch
```

**Inspect best run and history**

```julia
best = getbest(optres)
println(best)
```

**Optional. Access raw results objects for each evaluation**

```julia
history_results = getresultsofhistory(optres)
println(length(history_results))
```
