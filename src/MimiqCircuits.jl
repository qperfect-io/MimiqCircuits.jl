#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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

module MimiqCircuits

using Reexport
using SHA
using JSON
using MimiqLink
import Pkg

@reexport using MimiqCircuitsBase
@reexport using MimiqLink:
    connect,
    savetoken,
    loadtoken,
    isjobdone,
    isjobfailed,
    isjobstarted,
    requestinfo,
    stopexecution,
    Connection,
    Execution,
    QPERFECT_CLOUD,
    QPERFECT_CLOUD2

export execute
export executeqasm
export getinputs
export getresults

# maximum number of samples allowed
const MAX_SAMPLES = 2^16

# default value for the number of samples
const DEFAULT_SAMPLES = 1000

# minimum and maximum bond dimension allowed
const MIN_BONDDIM = 1
const MAX_BONDDIM = 2^12

# default bond dimension
const DEFAULT_BONDDIM = 256

# default time limit
const DEFAULT_TIME_LIMIT = 5 * 60

const RESULTSPB_FILE = "results.pb"
const CIRCUITPB_FILE = "circuit.pb"
const CIRCUITQASM_FILE = "circuit.qasm"

function _gethash(f::AbstractString)
    open(f, "r") do io
        bytes2hex(sha2_256(io))
    end
end

"""
    execute(connection, circuit[; kwargs...])

Execute a quantum circuit on the MIMIQ remote services.

The circuit is applied to the zero state and the resulting state is measured via sampling.
Optionally amplitudes corresponding to few selected bit states (or bitstrings) can be returned from the computation.

## Keyword Arguments

* `label::String`: mnemonic name to give to the simulation, will be visible on the [web interface](https://mimiq.qperfect.io)
* `algorithm`: algorithm to use by the compuation. By default `"auto"` will select the fastest algorithm between `"statevector"` or `"mps"`.
* `nsamples::Integer`: number of times to sample the circuit (default: 1000, maximum: 2^16)
* `bitstrings::Vector{BitString}`: list of bit states to compute the amplitudes for (default: `BitString[]`)
* `timelimit`: number of seconds before the computation is stopped (default: 300 seconds or 5 minutes)
* `bonddim::Int64`: bond dimension for the MPS algorithm (default: 256, maximum: 4096)
* `seed::Int64`: a seed for running the simulation (default: random seed)
"""
function execute(
    conn::Connection,
    c::Circuit;
    label::AbstractString="circuitsimu",
    algorithm::String="auto",
    nsamples=DEFAULT_SAMPLES,
    bitstrings::Vector{BitString}=BitString[],
    timelimit=DEFAULT_TIME_LIMIT,
    bonddim::Union{Nothing, Integer}=nothing,
    seed::Int64=rand(0:typemax(Int64)),
)
    if nsamples > MAX_SAMPLES
        throw(ArgumentError("Number of samples should be less than 2^16"))
    end

    tempdir = mktempdir(; prefix="mimiq_")

    # write the circuit to a file
    circuitfile = joinpath(tempdir, CIRCUITPB_FILE)
    saveproto(circuitfile, c)

    circuitsha = _gethash(circuitfile)

    nq = numqubits(c)

    if any(b -> numbits(b) != nq, bitstrings)
        throw(
            ArgumentError(
                "bitstrings should have the same number of qubits of the circuit.",
            ),
        )
    end

    # prepare the parameters

    pars = Dict(
        "algorithm" => algorithm,
        "bitstrings" => string.(bitstrings),
        "samples" => nsamples,
        "seed" => seed,
    )

    if algorithm == "auto" || algorithm == "mps"
        if isnothing(bonddim)
            pars["bondDimension"] = DEFAULT_BONDDIM
        else
            if bonddim < MIN_BONDDIM || bonddim > MAX_BONDDIM
                throw(ArgumentError(("Bond dimension should be ∈[1,4096]")))
            end
            pars["bondDimension"] = bonddim
        end
    end

    if VERSION >= v"1.9"
        apiversion = pkgversion(@__MODULE__)
        circuitsapiversion = pkgversion(MimiqCircuitsBase)
    else
        apiversion = VersionNumber(
            Pkg.TOML.parsefile(joinpath(pkgdir(@__MODULE__), "Project.toml"))["version"],
        )
        circuitsapiversion = VersionNumber(
            Pkg.TOML.parsefile(joinpath(pkgdir(MimiqCircuitsBase), "Project.toml"))["version"],
        )
    end

    # prepare the request
    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "files" => [Dict("name" => CIRCUITPB_FILE, "hash" => circuitsha)],
        "parameters" => pars,
        "apilang" => "julia",
        "apiversion" => apiversion,
        "circuitsapiversion" => circuitsapiversion,
    )

    # write the request to a file
    reqfile = joinpath(tempdir, "parameters.json")

    open(reqfile, "w") do io
        write(io, JSON.json(req))
    end

    type = "CIRC"

    return MimiqLink.request(conn, type, algorithm, label, timelimit, reqfile, circuitfile)
end

# checks if a file is a valid qasm 2 file
function _check_file_qasm2(f::AbstractString)
    open(f, "r") do io
        while true

            line = readline(io)

            # if line starts with // or if the line has only spaces
            if startswith(line, "//") || isempty(line) || all(isspace, line)
                continue
            end

            if !startswith(line, "OPENQASM 2.0;")
                throw(ArgumentError("File is not a valid QASM 2.0 file"))
            end

            # if startswith(line, "OPENQASM 2.0;")
            break
        end
    end
end

"""
    executeqasm(connection, qasmfilepath[; kwargs...])

Execute a quantum circuit on the MIMIQ remote services.

The circuit is applied to the zero state and the resulting state is measured via sampling.
Optionally amplitudes corresponding to few selected bit states (or bitstrings) can be returned from the computation.

## Keyword Arguments

* `label::String`: mnemonic name to give to the simulation, will be visible on the [web interface](https://mimiq.qperfect.io)
* `algorithm`: algorithm to use by the compuation. By default `"auto"` will select the fastest algorithm between `"statevector"` or `"mps"`.
* `nsamples::Integer`: number of times to sample the circuit (default: 1000, maximum: 2^16)
* `bitstrings::Vector{BitString}`: list of bit states to compute the amplitudes for (default: `BitString[]`)
* `timelimit`: number of seconds before the computation is stopped (default: 300 seconds or 5 minutes)
* `bonddim::Int64`: bond dimension for the MPS algorithm (default: 256, maximum: 4096)
* `seed::Int64`: a seed for running the simulation (default: random seed)
"""
function executeqasm(
    conn::Connection,
    qasmfilepath::AbstractString;
    label::AbstractString="circuitsimu",
    algorithm::String="auto",
    nsamples=DEFAULT_SAMPLES,
    bitstrings::Vector{BitString}=BitString[],
    timelimit=DEFAULT_TIME_LIMIT,
    bonddim::Union{Nothing, Integer}=nothing,
    seed::Int64=rand(0:typemax(Int64)),
)
    if nsamples > MAX_SAMPLES
        throw(ArgumentError("Number of samples should be less than 2^16"))
    end

    tempdir = mktempdir(; prefix="mimiq_")

    # check if the file exists
    if !isfile(qasmfilepath)
        throw(ArgumentError("File does not exist"))
    end

    # checks if the file is a valid qasm 2 file
    _check_file_qasm2(qasmfilepath)

    # copy the file away
    circuitfile = joinpath(tempdir, CIRCUITQASM_FILE)
    cp(qasmfilepath, circuitfile)
    circuitsha = _gethash(circuitfile)

    if any(b -> numbits(b) != numbits(first(bitstrings)), bitstrings)
        throw(ArgumentError("Inconsistent bitstrings length."))
    end

    # prepare the parameters
    pars = Dict(
        "algorithm" => algorithm,
        "bitstrings" => bitstrings,
        "samples" => nsamples,
        "seed" => seed,
    )

    if algorithm == "auto" || algorithm == "mps"
        if isnothing(bonddim)
            pars["bondDimension"] = DEFAULT_BONDDIM
        else
            if bonddim < MIN_BONDDIM || bonddim > MAX_BONDDIM
                throw(ArgumentError(("Bond dimension should be ∈[1,4096]")))
            end
            pars["bondDimension"] = bonddim
        end
    end

    # prepare the request
    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "files" => [Dict("name" => CIRCUITQASM_FILE, "hash" => circuitsha)],
        "parameters" => pars,
    )

    # write the request to a file
    reqfile = joinpath(tempdir, "parameters.json")

    open(reqfile, "w") do io
        write(io, JSON.json(req))
    end

    type = "CIRC"

    return MimiqLink.request(conn, type, algorithm, label, timelimit, reqfile, circuitfile)
end

"""
    getinputs(connection, execution)

Returns the circuit and parameters for the given execution.
"""
function getinputs(conn::Connection, ex::Execution)
    tmpdir = mktempdir(; prefix="mimiq_in_")
    names = MimiqLink.downloadjobfiles(conn, ex, tmpdir)

    if "parameters.json" ∉ basename.(names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    parameters = JSON.parsefile(joinpath(tmpdir, "parameters.json"))

    if CIRCUITPB_FILE in basename.(names)
        circuit = loadproto(joinpath(tmpdir, CIRCUITPB_FILE), Circuit)
    elseif CIRCUITQASM_FILE in basename.(names)
        circuit = joinpath(tmpdir, CIRCUITQASM_FILE)
        @info "Downloaded QASM input as $circuit"
    else
        error("No valid circuit file found. Input parameters not valid.")
    end

    return circuit, parameters
end

"""
    getresults(connection, execution; kwargs...)

Block until the given execution is finished and return the results.

#  Keyword Arguments

* `interval`: time interval in seconds to check for job completion (default: 10)
"""
function getresults(conn::Connection, ex::Execution; interval=10)
    # wait for the job to finish
    while !isjobdone(conn, ex)
        sleep(interval)
    end

    infos = MimiqLink.requestinfo(conn, ex)

    if infos["status"] == "ERROR"
        msg = get(infos, "message", nothing)
        if isnothing(msg)
            error("Remote job errored.")
        else
            error("Remote job errored: $msg.")
        end
    end

    tmpdir = mktempdir(; prefix="mimiq_res_")

    names = MimiqLink.downloadresults(conn, ex, tmpdir)

    if RESULTSPB_FILE ∉ basename.(names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    res = loadproto(joinpath(tmpdir, RESULTSPB_FILE), QCSResults)

    return res
end

end # module MimiqCircuits
