# Qubit Loss on MIMIQ

MIMIQ supports explicit qubit loss for simulations where a physical qubit may
leave the computational space instead of only accumulating ordinary gate or
measurement noise. This is useful when testing quantum algorithms against more
realistic near-term hardware behavior, especially in workflows where missing
qubits should change the later circuit execution.

In the Julia API, loss can be represented directly in a circuit. You can insert
loss events, reload a lost qubit, write its loss status into classical bits, and
rewrite partially affected instructions with a [`LossModel`](@ref).

Loss can also be part of a custom Kraus channel. A [`Kraus`](@ref) channel
becomes loss-aware when one or more branches are tagged with
[`LossyOperator`](@ref), which lets the channel separate survival branches from
branches that lose a qubit.

## Summary of Loss Functionality

**Loss operations:** [`Loss`](@ref), [`Reload`](@ref), [`Check`](@ref),
[`MeasureCheck`](@ref).

**Loss processing:** [`sample_losses`](@ref) draws the random loss events,
[`lower_losses`](@ref) rewrites loss into primitives, and
[`resolve_losses`](@ref) does both and is the usual entry point. Use
[`sample_loss_scenario`](@ref) to force a specific set of loss sites.

**Loss-model rules:** [`DropRule`](@ref), [`ReplaceRule`](@ref),
[`DecorateRule`](@ref), [`CustomRule`](@ref), applied to one instruction by
[`lossmodel_rewrite`](@ref).

**Loss markers:** [`Lost`](@ref) and [`Reloaded`](@ref) are passive annotations
that record where loss landed in a resolved circuit.

**Loss-aware Kraus:** [`LossyOperator`](@ref) branches inside [`Kraus`](@ref),
inspected with [`hasloss`](@ref), [`lossoperators`](@ref),
[`survivaloperators`](@ref), and [`losseffect`](@ref). The lost qubits of a
branch are given by [`lossyqubits`](@ref) and [`lossytargets`](@ref).

**Lossy mixed unitaries:** [`MixedUnitary`](@ref) branches marked with the
`lossy` keyword, detected with [`haslossybranch`](@ref).

## Loss operations

Loss in MIMIQ is represented explicitly in the circuit. You can add operations
that mark a qubit as lost, reload a lost qubit, or query whether a qubit is still
present.

### Losing a qubit

[`Loss`](@ref) represents a loss event: at that point in the circuit the qubit is
lost with probability `p`. `Loss()` is `Loss(1.0)`, a certain loss.

```@example loss
using MimiqCircuits

c = Circuit()
push!(c, Loss(0.1), 1)
```

The probability may also be symbolic, but it must be numeric before the loss is
resolved.

Once a qubit is lost, later instructions touching that qubit are dropped while
resolving, until the qubit is reloaded.

### Reloading a lost qubit

[`Reload`](@ref) makes a qubit available again. It always re-initialises the
qubit to ``|0\rangle``, whether or not it was lost, so later operations can use
it.

```@example loss
c = Circuit()
push!(c, Loss(), 1)
push!(c, Reload(), 1)
push!(c, GateX(), 1)
```

### Checking for loss

MIMIQ provides two operations to query the loss status of a qubit.

[`Check`](@ref) writes one classical bit:

- `1` if the qubit is present
- `0` if the qubit is lost

It does not touch the quantum state.

```@example loss
c = Circuit()
push!(c, Check(), 1, 1)
```

[`MeasureCheck`](@ref) measures the qubit if it is present and reports whether it
is still present.

```@example loss
c = Circuit()
push!(c, MeasureCheck(), 1, 1, 2)
```

The first classical bit stores the measurement result (`0` if the qubit is lost),
and the second classical bit stores the loss status.

## Resolving loss

A circuit that contains loss operations is not yet runnable: the random events
must be drawn and every loss operation rewritten into ordinary primitives.
[`resolve_losses`](@ref) does this in one step. It first draws each
[`Loss`](@ref), then lowers the result into `Reset`, `Measure`, `SetBit0` and
`SetBit1`, plus passive [`Lost`](@ref) and [`Reloaded`](@ref) markers. The
returned circuit contains no loss operations.

The `rng` keyword is a random number generator, used only to make the random
loss samples reproducible. Omit it if you do not need the same result every time.

```@example loss
using Random

rng = MersenneTwister(42)

c = Circuit()
push!(c, Loss(0.2), 1)
push!(c, GateH(), 1)
push!(c, Check(), 1, 1)

resolve_losses(c; rng=rng)
```

The basic behavior while resolving is:

- [`Loss`](@ref) is drawn; a loss that fires emits a [`Lost`](@ref) marker
- [`Reload`](@ref) becomes a `Reset` plus a [`Reloaded`](@ref) marker
- [`Check`](@ref) and [`MeasureCheck`](@ref) become `SetBit0` or `SetBit1` (and
  a `Measure` for a `MeasureCheck` on a present qubit)
- a `Measure` on a lost qubit becomes `SetBit0`, so a lost qubit reads 0
- instructions acting only on lost qubits are dropped

If an instruction touches some lost qubits but not all of them, resolving
consults a [`LossModel`](@ref).

If you need the two halves separately, [`sample_losses`](@ref) returns a circuit
with the random events drawn but the loss bookkeeping still present, and
[`lower_losses`](@ref) lowers an already-sampled circuit into primitives.

### Forcing a loss scenario

To study a specific outcome, [`sample_loss_scenario`](@ref) forces the chosen
[`Loss`](@ref) sites, counted in circuit order, to fire, and resolves the others
as not lost.

```@example loss
c = Circuit()
push!(c, Loss(0.2), 1)
push!(c, GateCX(), 1, 2)
push!(c, Loss(0.4), 2)

sample_loss_scenario(c, 2)
```

## Loss models

### Why Loss Models Exist

A [`LossModel`](@ref) is the user-defined policy used while resolving loss
when an instruction is only partially affected.
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

While resolving, MIMIQ tracks which qubits are currently lost and rewrites the circuit as follows:

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
push!(c, Loss(), 2)
push!(c, GateCX(), 1, 2)

model = LossModel()
add_replace!(model, GateCX() => Depolarizing1(0.2))

resolve_losses(c; lossmodel=model)
```

If the lost qubit is the control instead, the same rule keeps the replacement on the surviving target qubit.

```@example loss
c = Circuit()
push!(c, Loss(), 1)
push!(c, GateCX(), 1, 2)

resolve_losses(c; lossmodel=model)
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

[`DecorateRule`](@ref) adds another operation before or after the matched instruction. While resolving, generated instructions touching lost qubits are filtered out, so if the original gate still touches a lost qubit it is removed and only surviving decorations remain.

```@example loss
model = LossModel()
add_decorate!(model, GateCZ() => Depolarizing1(0.01); before=true)
```

Use decoration when your model says that the attempted operation still causes a side effect, such as a local error channel on the qubits that were present.

### Custom rules

Use [`CustomRule`](@ref) when the rewrite depends on more than the operation type. The generator receives the matched instruction and the current loss map. It may return `nothing` to drop the instruction, one [`Instruction`](@ref), or a vector of instructions.

In Julia, the custom generator should also accept the keyword `rng`. This is the same random number generator passed to [`resolve_losses`](@ref). Include it even if the rule does not need randomness.

```@example loss
c = Circuit()
push!(c, Loss(), 2)
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

resolve_losses(c; lossmodel=model)
```

### Applying a model to one instruction

[`lossmodel_rewrite`](@ref) applies a model to a single instruction, given a
dictionary that says which qubits are lost. It returns the instructions that
replace it, after removing those that touch a lost qubit. This is the step
[`lower_losses`](@ref) performs for each partially lost instruction, and is
useful to check what a model does before resolving a whole circuit.

```@example loss
model = LossModel()
add_replace!(model, GateCX() => Depolarizing1(0.2))

# qubit 2 is lost, qubit 1 is present
lossmodel_rewrite(Instruction(GateCX(), 1, 2), Dict(1 => false, 2 => true), model; rng=nothing)
```

An empty vector means that the instruction is dropped, as happens when no rule
matches:

```@example loss
lossmodel_rewrite(Instruction(GateCX(), 1, 2), Dict(2 => true), LossModel(); rng=nothing)
```

The `rng` keyword is required, and is passed on to the generator of a
[`CustomRule`](@ref).

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

A [`LossyOperator`](@ref) records which of its qubits are lost when its branch is selected. [`lossyqubits`](@ref) returns them in the operator's own `1:N` numbering, and [`lossytargets`](@ref) translates them to the qubits of the instruction the operator is applied to:

```@example loss
# a 2-qubit branch that loses its second qubit
op = LossyOperator(zeros(4, 4), 2)

lossyqubits(op)
```

```@example loss
# applied to qubits 3 and 7, the branch loses qubit 7
lossytargets(op, (3, 7))
```

### Lossy mixed unitaries

A [`MixedUnitary`](@ref) channel can also lose qubits. The `lossy` keyword lists, for each branch, the qubits it loses; an empty list keeps the branch lossless. [`haslossybranch`](@ref) tells whether any branch loses qubits.

```@example loss
# with probability 0.1, apply X and lose the qubit
mu = MixedUnitary([0.9, 0.1], [GateID(), GateX()]; lossy=[Int[], [1]])

haslossybranch(mu)
```

When [`sample_mixedunitaries`](@ref) draws a lossy branch, it adds a [`Loss`](@ref) on the lost qubits after the branch's gate, which [`resolve_losses`](@ref) then processes as usual.

```@example loss
c = Circuit()
push!(c, mu, 1)
push!(c, GateH(), 1)

# with this seed the lossy branch is drawn
sample_mixedunitaries(c; rng=MersenneTwister(17))
```

If you only need the general Kraus formalism, see the [Kraus operators](noise.md#kraus-operators) section.
