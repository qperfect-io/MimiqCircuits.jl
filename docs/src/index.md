# Introduction

MIMIQ Circuits is a quantum computing framework and high performance simulator
developed by QPerfect that allows you to develop and run your quantum
algorithms beyond the limits of today's noisy intermediate scale quantum (NISQ)
computers.

# Quick Start

`MimiqCircuits.jl` is a [Julia Language](https://julialang.org) package containing all the utilities and programming interfaces (APIs) to build quantum systems, connect and execute simulation on [QPerfect's MIMIQ-CIRC](https://qperfect.io) large scale quantum circuit simulator.

To install `MimiqCircuits`, please [open Julia's interactive session (REPL)](https://docs.julialang.org/en/v1/manual/getting-started/), then press the `]` to start using the package manager mode, then type the following commands.

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

Check the [installation](installation.md) page, for more details, and our first [tutorial](tutorial.md) for sample usage.
