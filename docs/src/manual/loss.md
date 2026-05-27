# Qubit Loss on MIMIQ

MIMIQ supports explicit qubit loss for simulations where a physical qubit may
leave the computational space instead of only accumulating ordinary gate or
measurement noise. This is useful when testing quantum algorithms against more
realistic near-term hardware behavior, especially in workflows where missing
qubits should change the later circuit execution.

In the Julia API, loss can be represented directly in a circuit. You can insert
stochastic loss events, mark a qubit as lost deterministically, reload it later,
write its loss status into classical bits, and rewrite partially affected
instructions with a [`LossModel`](@ref).

Loss can also be part of a custom Kraus channel. A [`Kraus`](@ref) channel
becomes loss-aware when one or more branches are tagged with
[`LossyOperator`](@ref), which lets the channel separate survival branches from
branches that lose a qubit.

## Summary of Loss Functionality

**Loss operations:** [`LossErr`](@ref), [`QubitLoss`](@ref),
[`QubitReload`](@ref), [`CheckLoss`](@ref), [`MeasureCheckLoss`](@ref).

**Loss processing:** [`sample_losses`](@ref) with [`LossModel`](@ref).

**Loss-model rules:** [`DropRule`](@ref), [`ReplaceRule`](@ref),
[`DecorateRule`](@ref), [`CustomRule`](@ref).

**Loss-aware Kraus:** [`LossyOperator`](@ref) branches inside [`Kraus`](@ref),
inspected with [`hasloss`](@ref), [`lossoperators`](@ref),
[`survivaloperators`](@ref), and [`losseffect`](@ref).

## Loss operations

Loss in MIMIQ is represented explicitly in the circuit. You can add operations that mark a qubit as lost, sample stochastic loss events, reload a lost qubit, or query whether a qubit is still present.

### Loss error

[`LossErr`](@ref) represents a probabilistic loss event. At that point in the circuit, the qubit is lost with probability `p`.

```@example loss
using MimiqCircuits

c = Circuit()
push!(c, LossErr(0.1), 1)
```

The loss probability can also be symbolic, but it must be numeric before calling [`sample_losses`](@ref).

### Deterministic loss

[`QubitLoss`](@ref) marks a qubit as lost unconditionally.

```@example loss
c = Circuit()
push!(c, QubitLoss(), 2)
```

Once a qubit is lost, subsequent operations touching that qubit are ignored by [`sample_losses`](@ref) until the qubit is reloaded.

### Reloading a lost qubit

[`QubitReload`](@ref) marks a lost qubit as present again. At the point where it is applied, the qubit is reset to ``|0\rangle``.

```@example loss
c = Circuit()
push!(c, QubitLoss(), 1)
push!(c, QubitReload(), 1)
push!(c, GateX(), 1)
```

### Checking for loss

MIMIQ provides two operations to query the loss status of a qubit.

[`CheckLoss`](@ref) writes one classical bit:

- `1` if the qubit is present
- `0` if the qubit is lost

It does not measure the quantum state.

```@example loss
c = Circuit()
push!(c, CheckLoss(), 1, 1)
```

[`MeasureCheckLoss`](@ref) both measures the qubit and reports whether it is present.

```@example loss
c = Circuit()
push!(c, MeasureCheckLoss(), 1, 1, 2)
```

The first classical bit stores the measurement result, and the second classical bit stores the loss status.

## Sampling loss events

To process loss operations in a circuit, use [`sample_losses`](@ref). This function walks through the circuit, samples the stochastic [`LossErr`](@ref) events, tracks which qubits are lost, and rewrites the circuit accordingly.

The `rng` argument is a random number generator. It is only used to make the random loss samples reproducible. You can omit it if you do not need the same random result every time.

```@example loss
using Random

rng = MersenneTwister(42)

c = Circuit()
push!(c, LossErr(0.2), 1)
push!(c, GateH(), 1)
push!(c, CheckLoss(), 1, 1)

csampled = sample_losses(c; rng=rng)
```

The basic behavior is:

- [`LossErr`](@ref) may emit a [`QubitLoss`](@ref)
- [`QubitLoss`](@ref) marks a qubit as lost
- [`QubitReload`](@ref) makes the qubit available again
- [`CheckLoss`](@ref) and [`MeasureCheckLoss`](@ref) are always kept
- Instructions acting only on lost qubits are dropped

If an instruction acts on some lost qubits but not all of them, then [`sample_losses`](@ref) consults a [`LossModel`](@ref).

## Loss models

### Why Loss Models Exist

A [`LossModel`](@ref) is the user-defined policy used by
[`sample_losses`](@ref) when an instruction is only partially affected by loss.
This happens, for example, when a two-qubit gate is scheduled but one of its
qubits has already been lost while the other one is still present.

MIMIQ can detect this situation, but it should not guess the physics for the
remaining qubits. Different hardware models and approximations can lead to
different choices: drop the instruction entirely, apply a one-qubit error
channel to each surviving qubit, keep a side-effect before or after the
attempted operation, or generate custom replacement instructions. A
`LossModel` is where you specify that choice explicitly.

If no rule is provided, MIMIQ uses the conservative behavior and drops
instructions that touch lost qubits. Add rules when your hardware model or
simulation workflow has a more specific response to partial loss.

### When rules are used

During [`sample_losses`](@ref), MIMIQ tracks which qubits are currently lost and rewrites the circuit as follows:

- If an instruction touches no lost qubits, it is kept unchanged.
- If an instruction touches only lost qubits, it is dropped.
- If an instruction touches both lost and surviving qubits, the [`LossModel`](@ref) is consulted.
- If no rule in the model matches, the instruction is dropped.

Rules are evaluated by priority and then by insertion order. A [`DropRule`](@ref) has higher priority than replacement or decoration rules, so it can be used to exclude specific operations before a broader salvage rule is applied. Once a rule matches, MIMIQ builds the rule's output and filters out any generated instruction that still touches a lost qubit.

This last filtering step is important. A one-qubit replacement such as `Depolarizing1(0.2)` is broadcast to the targets of the matched gate, and the copies on lost qubits are removed. A multi-qubit replacement that still touches a lost qubit is removed entirely.

You can create an empty model and add rules to it:

```@example loss
model = LossModel(; name="My Loss Model")
```

The helper functions are:

- [`add_drop!`](@ref)
- [`add_replace!`](@ref)
- [`add_decorate!`](@ref)

### Replacing a partially lost gate

Use [`ReplaceRule`](@ref) when the original instruction should be removed and replaced by another operation on the surviving qubits. In this example, a `CX` whose target qubit has been lost is replaced by a one-qubit depolarizing channel on the remaining control qubit.

```@example loss
c = Circuit()
push!(c, QubitLoss(), 2)
push!(c, GateCX(), 1, 2)

model = LossModel()
add_replace!(model, GateCX() => Depolarizing1(0.2))

sample_losses(c; lossmodel=model)
```

If the lost qubit is the control instead, the same rule keeps the replacement on the surviving target qubit.

```@example loss
c = Circuit()
push!(c, QubitLoss(), 1)
push!(c, GateCX(), 1, 2)

sample_losses(c; lossmodel=model)
```

### Drop rules

[`DropRule`](@ref) removes matching instructions when they touch lost qubits. Use this when a partially affected operation should not be salvaged. A `DropRule` without an operation is a catch-all rule.

```@example loss
model = LossModel()
add_drop!(model, GateSWAP())
```

Because drop rules have higher priority, they can override broader replacement rules:

```@example loss
model = LossModel([
    ReplaceRule(GateSWAP(), GateX()),
    DropRule(GateSWAP()),
])
```

### Decorating a partially lost gate

[`DecorateRule`](@ref) adds another operation before or after the matched instruction. In a loss model, generated instructions touching lost qubits are filtered out, so if the original gate still touches a lost qubit it is removed and only surviving decorations remain.

```@example loss
model = LossModel()
add_decorate!(model, GateCZ() => Depolarizing1(0.01); before=true)
```

Use decoration when your model says that the attempted operation still causes a side effect, such as a local error channel on the qubits that were present.

### Custom rules

Use [`CustomRule`](@ref) when the rewrite depends on more than the operation type. The generator receives the matched instruction and the current loss map. It may return `nothing` to drop the instruction, one [`Instruction`](@ref), or a vector of instructions.

In Julia, the custom generator should also accept the keyword `rng`. This is the same random number generator used by [`sample_losses`](@ref). Include it even if the rule does not need randomness.

```@example loss
c = Circuit()
push!(c, QubitLoss(), 2)
push!(c, GateCX(), 1, 2)

model = LossModel([
    CustomRule(
        inst -> getoperation(inst) isa GateCX,
        (inst, lost; rng=nothing) -> [
            Instruction(GateZ(), q)
            for q in getqubits(inst)
            if !get(lost, q, false)
        ],
    ),
])

sample_losses(c; lossmodel=model)
```

For most workflows, prefer [`DropRule`](@ref), [`ReplaceRule`](@ref), or [`DecorateRule`](@ref) because those rules are simpler to inspect and serialize. [`CustomRule`](@ref) is the escape hatch for policies that cannot be expressed with the built-in rule types.

## Loss-aware Kraus channels

Custom [`Kraus`](@ref) channels can also model loss. A Kraus channel becomes loss-aware when one or more of its branches are tagged with [`LossyOperator`](@ref).

```@example loss
k = Kraus([
    [1 0; 0 sqrt(0.9)],
    LossyOperator([0 sqrt(0.1); 0 0]),
])
```

You can inspect such channels using:

```@example loss
hasloss(k)
```

```@example loss
lossoperators(k)
```

```@example loss
survivaloperators(k)
```

```@example loss
losseffect(k)
```

[`losseffect`](@ref) returns the operator describing the total loss probability carried by the lossy branches.

If you only need the general Kraus formalism, see the [Kraus operators](noise.md#kraus-operators) section.
