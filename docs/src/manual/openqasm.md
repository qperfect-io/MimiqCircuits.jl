# OpenQASM in MIMIQ-CIRC

The remote MIMIQ-CIRC services can can readily process and execute OpenQASM files, thanks to fast and feature-complete Julia and C++ parsers and interpreters.

Here is a simple comprehensive example of executing a QASM file on MIMIQ.

```@example qasm
using MimiqCircuits # hide
using Plots # hide
conn = connect(ENV["MIMIQUSER"], ENV["MIMIQPASS"]; url=QPERFECT_CLOUD2) # hide
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
res = getresults(conn, job)
plot(res)
```

For more informations, read the documentation of [`MimiqCircuits.executeqasm`](@ref).

## Behaviour of include files

A common file used by many QASM files is the `qelib1.inc` file.
This file is not defined as being part of OpenQASM 2.0, but its usage is so widespread that it might be considered as de-facto part of the specifications.

!!! details
    We remind the careful reader that OpenQASM 2.0 specifications only define 6 operations:
    `U`,`CX`, `measure`, `reset`, `barrier` and `if`.

If we would parse every file together with `qelib1.inc`, we would have at the end just a list of simple `U` and `CX` gates, leaving behind any speed improvement that we would gain by using more complex gates as a block. For this reason, if you do not provide us explicitly the include files, we would not parse the common `qelib1.inc` but a simplified version of it, where almost all gate definitions are replaced by `opaque` definitions. These opaque definitions will be converted to the corresponding MIMIQ-CIRC gates listed in [`MimiqCircuitsBase.GATES`](@ref).

Another alternative is to use the `mimiqlib.inc` directly in your file. For now is almost a copy of the modified `qelib1.inc` but in the future it will be extended to contain more gates and operations, diverging from `qelib1.inc`.

## Relations between OpenQASM registers and MIMIQ indices

During the parsing of the QASM file, we will assign a unique index to each qubit and classical bit. This index will be used to identify the qubit or bit in the MIMIQ-CIRC service.
The indices are assigned in the following way:

* The first qubit is assigned index `1` (Julia), the second `2`, and so on.
* All registers retain the same ordering as in the QASM file.
* Qubits and classical bits behave similarly but have they have each other its own sequence from indices, starting from `1`.

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


