# Import and export circuits

In this section we introduce different options to import and export circuits.
In particular, MIMIQ allows to import circuits in well-known languages such as OpenQASM and Stim, as well as save and import circuits using its own ProtoBuf structure.

- [Import and export circuits](#import-and-export-circuits)
  - [ProtoBuf](#protobuf)
    - [Export ProtoBuf files from MIMIQ](#export-protobuf-files-from-mimiq)
    - [Import ProtoBuf file to MIMIQ](#import-protobuf-file-to-mimiq)
  - [OpenQASM](#openqasm)
    - [Execute OpenQASM file in MIMIQ](#execute-openqasm-file-in-mimiq)
      - [Behaviour of include files](#behaviour-of-include-files)
      - [Relations between OpenQASM registers and MIMIQ indices](#relations-between-openqasm-registers-and-mimiq-indices)
  - [Stim](#stim)
    - [Execute Stim file on MIMIQ](#execute-stim-file-on-mimiq)

## ProtoBuf

### Export ProtoBuf files from MIMIQ

After building a circuit in MIMIQ you can export it into a ProtoBuf format using the [saveproto](@ref) function. You need to give it two arguments, the name of the file to create (`.pb` format) and the circuit to save.

```julia
saveproto("my_circuit.pb", circuit)
```

The same method allows you to save your simulation results in a ProtoBuf file.

```julia
# get the results
results = getresults(conn, job)
# save the results
saveproto("my_results.pb", results)
```

!!! note
    ProtoBuf is a serialized file format developed by google. It is very lightweight and efficient to parse. Check the  [ProtoBuf repository](https://github.com/protocolbuffers/protobuf) for more information.

!!! note
    You can only export a circuit into ProtoBuf format and cannot export an OpenQASM or Stim file in the current version of MIMIQ.

### Import ProtoBuf file to MIMIQ

MIMIQ allows you to import ProtoBuf files using the [loadproto](@ref) function.
With this function you can get previously saved circuit or get previous simulation results.
You need to give this function the name of the file to parse and the type of object to parse.

```julia
# Import circuit from ProtoBuf to MIMIQ
circuit = loadproto("my_circuit.pb", Circuit) # Do not instatiate the Circuit

# Import results from ProtoBuf to MIMIQ
results = loadproto("my_results.pb", QCSResults)
```

!!! details
    Alternatively to import results you can also use the [loadresults](@ref) function.

The circuit imported with [loadproto](@ref) can be manipulated like any other circuit on MIMIQ to add or insert gates, see [circuit](circuits.md) page.

## OpenQASM

Open Quantum Assembly Language is a programming language designed for describing quantum circuits and algorithms for execution on quantum computers. It is a very convenient middle ground for different quantum computer architectures to interpret and execute circuits.

### Execute OpenQASM file in MIMIQ

The remote MIMIQ services can readily process and execute OpenQASM files, thanks to fast and feature-complete Julia and C++ parsers and interpreters.

Here is a simple comprehensive example of executing a QASM file on MIMIQ.

```@example qasm
using MimiqCircuits # hide
using Plots # hide
str_name = get(ENV, "MIMIQCLOUD", nothing) # hide
new_url = # hide
    str_name == "QPERFECT_CLOUD" ? QPERFECT_CLOUD : # hide
    str_name == "QPERFECT_DEV" ? QPERFECT_DEV : # hide
    isnothing(str_name) ? QPERFECT_CLOUD : # hide
    str_name # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=new_url) # hide
# after connecting to MIMIQ
#
# ...

qasm = """
// Implementation of Deutsch algorithm with two qubits for f(x)=x
// taken from https://github.com/pnnl/QASMBench/blob/master/small/deutsch_n2/deutsch_n2.qasm
OPENQASM 2.0;
include "qelib1.inc";

qreg q[2];
creg c[2];

x q[1];
h q[0];
h q[1];
cx q[0],q[1];
h q[0];
measure q[0] -> c[0];
measure q[1] -> c[1];
"""

# Write the OPENQASM as a file
open("/tmp/deutsch_n2.qasm", "w") do io
    write(io, qasm)
end

# actual execution of the QASM file
job = executeqasm(conn, "/tmp/deutsch_n2.qasm"; algorithm="statevector")
res = getresult(conn, job)
plot(res)
```

For more informations, read the documentation of [`execute`](@ref) and check the [remote execution](remote_execution.md) page.

#### Behaviour of include files

A common file used by many QASM files is the `qelib1.inc` file.
This file is not defined as being part of OpenQASM 2.0, but its usage is so widespread that it might be considered as de-facto part of the specifications.

!!! details
    We remind the careful reader that OpenQASM 2.0 specifications only define 6 operations:
    `U`,`CX`, `measure`, `reset`, `barrier` and `if`.

If we were to parse every file together with `qelib1.inc`, we would have at the end just a list of simple `U` and `CX` gates, leaving behind any speed improvement that we would gain by using more complex gates as blocks. For this reason, if you don't explicitly provide the include files, MIMIQ will not parse the usual `qelib1.inc` file but will instead use a simplified version of it, where almost all gate definitions are replaced by `opaque` definitions. These opaque definitions will be converted to the corresponding MIMIQ gates listed in [`GATES`](@ref).

Another alternative is to use the `mimiqlib.inc` directly in your file. For now it's almost a copy of the modified `qelib1.inc` but in the future it will be extended to contain more gates and operations, diverging from `qelib1.inc`.

#### Relations between OpenQASM registers and MIMIQ indices

During the parsing of the QASM file, we will assign a unique index to each qubit and classical bit. This index will be used to identify the qubit or bit in the MIMIQ service.
The indices are assigned in the following way:

- The first qubit is assigned index `1` (Julia), the second `2`, and so on.
- All registers retain the same ordering as in the QASM file.
- Qubits and classical bits behave similarly but each has its own sequence of indices, starting from `1`.

A simple example will clarify this behaviour:

```qasm
OPENQASM 2.0;
qreg q[2];
creg m[10];
qreg a[10];
creg g[2];
```

Will be parsed as:

| QASM name | MIMIQ Qubit index | MIMIQ Bit index |
| --- | --- | --- |
| `q[0]` | `1` | |
| `q[1]` | `2` | |
| `a[0]` | `3` | |
| `a[1]` | `4` | |
| ... | ... | ... |
| `a[9]` | `12` | |
| `m[0]` | | `1` |
| `m[1]` | | `2` |
| ... | ... | ... |
| `m[9]` | | `10` |
| `g[0]` | | `11` |
| `g[1]` | | `12` |

## Stim

### Execute Stim file on MIMIQ

[Stim](https://github.com/quantumlib/Stim) is a fast stabilizer circuit simulator commonly used for Clifford circuit simulation. Stim allows users to export their circuit to a text format usually with the `.stim` extension.
The remote MIMIQ services can readily process and execute Stim files as follows:

```julia
job = execute(conn, "my_stim_circuit.stim")
```

!!! warning
    The support of Stim is still in progress and some of the most specific Stim features are not supported. For instance, detectors will be completely ignored by MIMIQ at exectution time.

The results of the simulation can be accessed as usual on MIMIQ, see [remote execution](remote_execution.md) page.
