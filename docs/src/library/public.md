# Public Documentation

Documentation for `MimiqCircuits.jl`'s public interface.

See the Internals section of the manual for internal package docs.

## Modules

```@autodocs
Modules = [MimiqCircuits]
Private = false
Pages   = ["MimiqCircuits.jl"]
```

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["MimiqCircuitsBase.jl"]
```

```@autodocs
Modules = [MimiqLink]
Private = false
Pages   = ["MimiqLink.jl"]
```

## Quantum Circuits and Instructions

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["instruction.jl", "circuit.jl", "circuit_extras.jl"]
```

## Operations

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["operation.jl"]
```

### Gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["gate.jl"]
```

#### Single qubit gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["singlequbit.jl", "singlequbitpar.jl"]
```

#### Two-qubit gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["twoqubit.jl", "twoqubitpar.jl"]
```

#### Multi-qubit

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["multiqubit.jl"]
```

#### Custom gates

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["custom.jl"]
```

### Non-unitary operations

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["reset.jl", "measure.jl"]
```

### No-ops

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["barrier.jl"]
```

### Composite operations

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["ifstatement.jl", "control.jl", "parallel.jl"]
```

## Bit States

```@autodocs
Modules = [MimiqCircuitsBase]
Private = false
Pages   = ["bitstates.jl"]
```

