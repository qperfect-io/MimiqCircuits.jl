#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

"""
    execute(connection, circuit[; kwargs...])
    execute(connection, circuits[; kwargs...])

Execute a quantum circuit on the MIMIQ remote services.

The circuit is applied to the zero state and the resulting state is measured via sampling.
Optionally amplitudes corresponding to few selected bit states (or bitstrings) can be returned from the computation.

## Keyword Arguments

* `label::String`: mnemonic name to give to the simulation, will be visible on the [web interface](https://mimiq.qperfect.io)
* `algorithm`: algorithm to use by the compuation. By default `"auto"` will select the fastest algorithm between `"statevector"` or `"mps"`.
* `nsamples::Integer`: number of times to sample the circuit (default: 1000, maximum: 2^16)
* `bitstrings::Vector{BitString}`: list of bit states to compute the amplitudes for (default: `BitString[]`)
* `timelimit`: number of minutes before the computation is stopped (default: maximum allowed or 30 minutes)
* `bonddim::Int`: bond dimension for the MPS algorithm (default: 256, maximum: 4096)
* `entdim::Int`: parameter to control pre compression of the circuit. Higher value makes simulations slower. (default: 16, minimum:4, maximum: 64)
* `seed::Int`: a seed for running the simulation (default: random seed)
"""
function execute end

execute(conn, c::Circuit; kwargs...) = execute(conn, [c]; kwargs...)
execute(conn, c::String; kwargs...) = execute(conn, [c]; kwargs...)

function _file_is_openqasm2(f::AbstractString)
    open(f, "r") do io
        while true
            line = readline(io)
            # if line starts with // or if the line has only spaces
            if startswith(line, "//") || isempty(line) || all(isspace, line)
                continue
            end

            # if the next line starts with OPENQASM 2.0;
            # then it is a open qasm 2 file, otherwise it is not
            return startswith(line, "OPENQASM 2.0;")
        end
    end
end

function _file_may_be_stim(f::AbstractString)
    STIM_KEYWORDS = [
        # Pauli Gates
        "I",
        "X",
        "Y",
        "Z",
        # Single Qubit Clifford Gates
        "C_XYZ",
        "C_ZYX",
        "H",
        "H_XY",
        "H_XZ",
        "H_YZ",
        "S",
        "SQRT_X",
        "SQRT_X_DAG",
        "SQRT_Y",
        "SQRT_Y_DAG",
        "SQRT_Z",
        "SQRT_Z_DAG",
        "S_DAG",
        # Two Qubit Clifford Gates
        "CNOT",
        "CX",
        "CXSWAP",
        "CY",
        "CZ",
        "CZSWAP",
        "ISWAP",
        "ISWAP_DAG",
        "SQRT_XX",
        "SQRT_XX_DAG",
        "SQRT_YY",
        "SQRT_YY_DAG",
        "SQRT_ZZ",
        "SQRT_ZZ_DAG",
        "SWAP",
        "SWAPCX",
        "SWAPCZ",
        "XCX",
        "XCY",
        "XCZ",
        "YCX",
        "YCY",
        "YCZ",
        "ZCX",
        "ZCY",
        "ZCZ",
        # Noise Channels
        "CORRELATED_ERROR",
        "DEPOLARIZE1",
        "DEPOLARIZE2",
        "E",
        "ELSE_CORRELATED_ERROR",
        "HERALDED_ERASE",
        "HERALDED_PAULI_CHANNEL_1",
        "PAULI_CHANNEL_1",
        "PAULI_CHANNEL_2",
        "X_ERROR",
        "Y_ERROR",
        "Z_ERROR",
        # Collapsing Gates
        "M",
        "MR",
        "MRX",
        "MRY",
        "MRZ",
        "MX",
        "MY",
        "MZ",
        "R",
        "RX",
        "RY",
        "RZ",
        # Pair Measurement Gates
        "MXX",
        "MYY",
        "MZZ",
        # Generalized Pauli Product Gates
        "MPP",
        "SPP",
        "SPP_DAG",
        # Control Flow
        "REPEAT",
        # Annotations
        "DETECTOR",
        "MPAD",
        "OBSERVABLE_INCLUDE",
        "QUBIT_COORDS",
        "SHIFT_COORDS",
        "TICK",
    ]
    open(f, "r") do io
        while true
            line = readline(io)
            # if line starts with // or if the line has only spaces
            if startswith(line, "#") || isempty(line) || all(isspace, line)
                continue
            end

            # now check if the first word is a STIM keyword
            return first(split(line, r"\s+")) ∈ STIM_KEYWORDS
        end
    end
end

function execute(
    conn,
    circuits::Vector;
    label::AbstractString="jlapi_$(_pkgversion(@__MODULE__))",
    algorithm::String=DEFAULT_ALGORITHM,
    nsamples=DEFAULT_SAMPLES,
    bitstrings::Vector{BitString}=BitString[],
    timelimit=_gettimelimit(conn),
    bonddim::Union{Nothing, Integer}=nothing,
    entdim::Union{Nothing, Integer}=nothing,
    force::Bool=false,
    seed::Int=rand(0:typemax(Int)),
    kwargs...,
)

    if isempty(circuits)
        throw(ArgumentError("Empty circuit list is not allowed"))
    end

    for c in circuits
        if isempty(c)
            throw(ArgumentError("Empty circuit element is not allowed"))
        end
    end

    if length(circuits) > 1 && algorithm == "auto"
        throw(
            ArgumentError(
                "The 'auto' algorithm is not supported in batch mode. Please specify 'mps' or 'statevector' for batch executions.",
            ),
        )
    end


    if nsamples > MAX_SAMPLES
        throw(ArgumentError("Number of samples should be less than 2^16"))
    end

    maxtimelimit = _gettimelimit(conn)

    if timelimit > maxtimelimit
        throw(ArgumentError("Time limit should be less than $(maxtimelimit) minutes"))
    end

    tempdir = mktempdir(; prefix="mimiq_")

    # prepare the parameters
    pars = Dict(
        "algorithm" => algorithm,
        "bitstrings" => string.(bitstrings),
        "samples" => nsamples,
        "seed" => seed,
    )

    pars["circuits"] = Dict{String, Any}[]
    circuitspath = String[]

    for (i, c) in enumerate(circuits)
        if c isa Circuit
            # write the circuit to a file
            circuitfname = "$(CIRCUIT_FNAME)$i.$(EXTENSION_PROTO)"
            circuitpath = joinpath(tempdir, circuitfname)
            saveproto(circuitpath, c)

            # add the circuits to the parameters
            push!(
                pars["circuits"],
                Dict{String, Any}("file" => circuitfname, "type" => TYPE_PROTO),
            )
            push!(circuitspath, circuitpath)
        elseif c isa AbstractString

            if !isfile(c)
                throw(ArgumentError("$c: no such file"))
            end

            if _file_is_openqasm2(c)
                # write the circuit to a file
                circuitfname = "$(CIRCUIT_FNAME)$i.$(EXTENSION_QASM)"
                circuitpath = joinpath(tempdir, circuitfname)
                cp(c, circuitpath)
                # add the circuits to the parameters
                push!(
                    pars["circuits"],
                    Dict{String, Any}("file" => circuitfname, "type" => TYPE_QASM),
                )
                push!(circuitspath, circuitpath)
            elseif _file_may_be_stim(c)
                # write the circuit to a file
                circuitfname = "$(CIRCUIT_FNAME)$i.$(EXTENSION_STIM)"
                circuitpath = joinpath(tempdir, circuitfname)
                cp(c, circuitpath)
                # add the circuits to the parameters
                push!(
                    pars["circuits"],
                    Dict{String, Any}("file" => circuitfname, "type" => TYPE_STIM),
                )
                push!(circuitspath, circuitpath)
            else
                throw(ArgumentError("File is not a valid QASM 2.0 or STIM file"))
            end
        else
            throw(
                ArgumentError(
                    "Circuit should be a valid QASM 2.0 or STIM file or a MIMIQ Circuit object",
                ),
            )
        end
    end

    # set the bond and entangling dimensions
    _setmpsdims!(pars, algorithm, bonddim, entdim; force=force)
    _setextraargs!(pars, kwargs...)

    # write the parameters to a file
    parsfile = joinpath(tempdir, "circuits.json")

    open(parsfile, "w") do io
        write(io, JSON.json(pars))
    end

    # prepare the request
    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "apilang" => "julia",
        "apiversion" => _pkgversion(@__MODULE__),
        "circuitsapiversion" => _pkgversion(MimiqCircuitsBase),
    )

    # write the request to a file
    reqfile = joinpath(tempdir, "request.json")

    open(reqfile, "w") do io
        write(io, JSON.json(req))
    end

    type = "CIRC"

    sleep(0.1)

    return MimiqLink.request(
        conn,
        type,
        algorithm,
        label,
        timelimit,
        reqfile,
        parsfile,
        circuitspath...,
    )
end
