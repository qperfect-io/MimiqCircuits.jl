# Installation

Julia is required to use `MimiqCircuits.jl`. If you do not have it on your system, please refer to the [official website](https://julialang.org). We recommend to install Julia via the [juliaup tool](https://github.com/julialang/juliaup#installation), which will manage updates and multiple versions of Julia on the same system automatically.

To install the latest version of `MimiqCircuitsBase.jl`, use the Julia's built-in package manager (accessed by pressing `]` in the Julia REPL command prompt).

Before installing the package itself, since we didn't add it to the public Julia General registry, make sure to have installed QPerfect's own package registry.

```julia
julia> ]
(v1.9) pkg> registry update
(v1.9) pkg> registry add https://github.com/qperfect-io/QPerfectRegistry.git
(v1.9) pkg> add MimiqCircuits
```

!!! note
    The `] registry update` command will make sure, if this is your first time
    starting up Julia, to install and download the Julia General registry,
    where most packages are registered.

## Jupyter

If you want to use Jupyter, you need to install the Julia Jupyter kernel. This can be easily accomplished by running the following command in the julia session:

```julia
julia> ]
(v1.9) pkg> add IJulia
```

## Extras

Thanks to the Julia's package manager features such as _weak dependencies_, and _extensions_ features, you can install extra packages that will extend the functionalities of MIMIQ-CIRC. For example, if you want to use the `Quantikz` package to draw quantum circuits, you can install it by running the following command in the julia session:

```julia
julia> ]
(v1.9) pkg> add Quantikz
```

```@example
using MimiqCircuits
using ImageShow # hide
using Quantikz

# build a simple GHZ(4) circuit
c = push!(Circuit(), GateH(), 1)
push!(c, GateCX(), 1, 2:4)

# or displaycircuit(c) if your environment supports it
circuit2image(c)
```

With these steps completed, you are now ready to explore the features and
capabilities of MIMIQ-CIRC with Julia. Happy coding!
