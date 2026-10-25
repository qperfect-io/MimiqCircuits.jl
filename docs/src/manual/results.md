# Analyzing results

Every circuit executed on MIMIQ produces a [`QCSResults`](@ref) object. You get
one from [`getresult`](@ref), a vector of them from [`getresults`](@ref) (see
[Cloud Execution](remote_execution.md)), or by loading a results file with
[`loadproto`](@ref). This page explains what it contains and how to turn it into
counts, probabilities and plots.

The examples build a `QCSResults` by hand, so that they run without a
connection to MIMIQ. A result returned by the service works in exactly the
same way.

## A results object

[`QCSResults`](@ref) can be constructed from its fields, in this order:
simulator name, simulator version, fidelities, average gate errors, classical
register samples, Z-register contents, amplitudes and timings.

```@example results
using MimiqCircuits
using Random

# Fake the output of a 3-qubit GHZ circuit measured 1000 times: the two
# outcomes 000 and 111 appear with equal probability, and a few samples have
# one bit flipped, as a noisy device would produce.
rng = MersenneTwister(42)
cstates = map(1:1000) do _
    bits = fill(rand(rng, Bool), 3)
    if rand(rng) < 0.05
        k = rand(rng, 1:3)
        bits[k] = !bits[k]
    end
    BitString(bits)
end

res = QCSResults(
    "MIMIQ-StateVector",                       # simulator
    "x.y.z",                                   # simulator version
    [1.0],                                     # one fidelity per execution
    [0.0],                                     # one gate error per execution
    cstates,                                   # one BitString per sample
    [ComplexF64[0.9]],                         # Z-register, one vector per execution
    Dict(bs"000" => 1 / sqrt(2) + 0im),        # requested amplitudes
    Dict("total" => 0.012, "apply" => 0.004, "sample" => 0.006),
)
```

Printing a result shows a summary: simulator, timings, fidelity, the five most
frequent samples and the number of executions, amplitudes and samples.

## Fields

| Field | Type | Content |
|:------|:-----|:--------|
| `simulator` | `String` | name of the simulator that ran the circuit |
| `version` | `String` | version of that simulator |
| `fidelities` | `Vector{Float64}` | fidelity estimate of each execution, see [Fidelity and Error estimates](@ref) |
| `avggateerrors` | `Vector{Float64}` | average multi-qubit gate error of each execution |
| `cstates` | `Vector{BitString}` | the classical register of each sample |
| `zstates` | `Vector{Vector{ComplexF64}}` | the Z-register of each execution |
| `amplitudes` | `Dict{BitString,ComplexF64}` | amplitudes requested with the `bitstrings` keyword of [`submit`](@ref) |
| `timings` | `Dict{String,Float64}` | time in seconds spent in each stage, under `"total"` the whole run |

How many entries `fidelities`, `avggateerrors` and `zstates` hold depends on
how the circuit was sampled (see [Understanding sampling](@ref)).
A circuit without mid-circuit measurements or other non-unitary operations is
executed once and sampled many times, so these vectors have one entry. A
circuit that needs one execution per sample has one entry per sample.

```@example results
# Number of samples, and the first few of them.
length(res.cstates), res.cstates[1:3]
```

```@example results
# Lowest fidelity over all executions.
minimum(res.fidelities)
```

```@example results
# Total run time in seconds.
res.timings["total"]
```

## Counts and probabilities

`histsamples` counts how many times each classical-register value was
sampled and returns a `Dict{BitString,Int}`:

```@example results
counts = histsamples(res)
```

Sort it to find the most frequent outcomes, and divide by the number of
samples to estimate probabilities:

```@example results
nsamples = length(res.cstates)
probs = Dict(b => n / nsamples for (b, n) in counts)

# Outcomes from most to least likely.
sort(collect(probs); by=last, rev=true)
```

The outcomes are [`BitString`](@ref)s, so the bitstring helpers apply to them.
Bit `i` of the BitString is the classical bit `i` of the circuit:

```@example results
b = bs"011"
b[1], nonzeros(b), to01(b), bitstring_to_integer(b)
```

[`bitstring_to_integer`](@ref) reads bit 1 as the least significant bit.

Estimates of observables follow directly from the samples. For example, the
expectation value of ``Z_1 Z_2`` is the average of ``(-1)^{b_1 + b_2}``:

```@example results
zz = sum(s -> (-1)^(s[1] + s[2]), res.cstates) / nsamples
```

## Z-register and amplitudes

Operations such as [`ExpectationValue`](@ref), [`Amplitude`](@ref) or
[`VonNeumannEntropy`](@ref) write their output into the Z-register (see
[Statistical Operations](statistical_ops.md)). Each element of `zstates` is the
content of the Z-register at the end of one execution, indexed like the
`zvars` of the circuit:

```@example results
# Value written to Z-register 1 in the first (here the only) execution.
res.zstates[1][1]
```

When there is one execution per sample, average over them to get the
estimate:

```@example results
sum(z -> z[1], res.zstates) / length(res.zstates)
```

Amplitudes requested through the `bitstrings` keyword of [`submit`](@ref) are
stored in `amplitudes`, keyed by bitstring:

```@example results
abs2(res.amplitudes[bs"000"])
```

## Plotting

A `QCSResults` can be plotted directly with `Plots`. The plot is a bar chart of
the most frequent outcomes.

```@example results
using Plots
plot(res)
savefig("results_plot.png"); nothing # hide
```

![Bar chart of the sampled outcomes](results_plot.png)

The keyword `max_outcomes` (default 15) sets how many outcomes are shown, and
`endianess` (`:big` by default, or `:little`) sets the order in which the bits
of each outcome are written on the axis.

```@example results
plot(res; max_outcomes=4, endianess=:little)
savefig("results_plot_little.png"); nothing # hide
```

![Bar chart of the four most frequent outcomes](results_plot_little.png)

## Saving and loading

Results are saved in the protobuf format with [`saveproto`](@ref) and read back
with [`loadproto`](@ref). This is also the format of the result files you can
download from the MIMIQ web interface.

```@example results
fname = joinpath(mktempdir(), "results.pb")
saveproto(fname, res)

loaded = loadproto(fname, QCSResults)
histsamples(loaded) == histsamples(res)
```

[`saveresults`](@ref) and [`loadresults`](@ref) do the same with shorter
calls: `saveresults(fname, res)` and `loadresults(fname)`.

`saveproto` writes one result per file, so save each element of the vector
returned by [`getresults`](@ref) separately.
