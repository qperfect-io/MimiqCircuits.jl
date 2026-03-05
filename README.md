
# MimiqCircuits.jl

[![Build Status](https://github.com/qperfect-io/MimiqCircuits.jl/workflows/CI/badge.svg)](https://github.com/qperfect-io/MimiqCircuits.jl/actions)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://docs.qperfect.io/MimiqCircuits.jl/stable/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

**MimiqCircuits.jl** is the main Julia package for building, simulating, and executing quantum circuits on QPerfect's MIMIQ Virtual Quantum Computer. It provides a complete interface for quantum algorithm development, from circuit construction to remote execution on high-performance simulators.

Part of the [MIMIQ](https://qperfect.io) ecosystem by [QPerfect](https://qperfect.io).

## Features

- 🔧 **Build quantum circuits** with an intuitive Julia API
- ☁️ **Execute on MIMIQ cloud services** with automatic job management
- 📊 **Retrieve and visualize results** with built-in plotting capabilities
- 🔄 **Import/Export OpenQASM** for interoperability with other quantum frameworks
- 🎯 **Multiple simulation algorithms** (state vector, MPS)
- 📈 **Expectation values and measurements** for quantum observables
- 🌐 **Remote execution** with authentication and connection management

## Installation

First, add the QPerfect registry to your Julia installation:

```julia
using Pkg
Pkg.Registry.add("General")  # Add General registry if not already added
Pkg.Registry.add(RegistrySpec(url="https://github.com/qperfect-io/QPerfectRegistry.git"))
```

Then install MimiqCircuits:

```julia
Pkg.add("MimiqCircuits")
```

## Quick Start

### Building a Simple Circuit

```julia
using MimiqCircuits

# Create a Bell state circuit
c = Circuit()
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2)
push!(c, Measure(), 1:2, 1:2)

# Visualize the circuit
draw(c)
```

### Remote Execution

```julia
using MimiqCircuits

# Connect to MIMIQ cloud services
conn = connect()  # Opens browser for authentication

# Create and execute a circuit
c = Circuit()
push!(c, GateH(), 1)
push!(c, GateCX(), 1, 2:10)
push!(c, Measure(), 1:10, 1:10)

# Execute on MIMIQ remote services
job = execute(conn, c; algorithm="auto", nsamples=1000)

# Wait for completion and retrieve results
res = getresults(conn, job)

# Visualize results
using Plots
plot(res)
```

### Executing OpenQASM Files

```julia
# Execute a QASM file directly
job = executeqasm(conn, "path/to/circuit.qasm"; algorithm="statevector")
res = getresults(conn, job)
```

## Related Libraries

MimiqCircuits.jl is built on top of and works together with:

- **[MimiqCircuitsBase.jl](https://github.com/qperfect-io/MimiqCircuitsBase.jl)** - Core circuit building and gate definitions
- **[MimiqLink.jl](https://github.com/qperfect-io/MimiqLink.jl)** - Authentication and connection to MIMIQ services

For Python users:

- **[mimiqcircuits-python](https://github.com/qperfect-io/mimiqcircuits-python)** - Python version of this library

## Access to MIMIQ

To execute circuits on MIMIQ's remote services, you need an active subscription.

- **[Register for MIMIQ](https://qperfect.io)** to get started
- Contact us at <contact@qperfect.io> for organizational subscriptions
- If your organization has a subscription, contact your account administrator

## Contributing

We welcome contributions! Please see our contributing guidelines for more information.

## Support

- 📧 Email: <mimiq.support@qperfect.io>
- 🐛 Issues: [GitHub Issues](https://github.com/qperfect-io/MimiqCircuits.jl/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/qperfect-io/MimiqCircuits.jl/discussions)

## COPYRIGHT

Copyright © 2022-2023 University of Strasbourg

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
