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

"""
    executeqasm(connection, qasmfilepath[, incfilepath[, incfilepath[, ...]]][; kwargs...])

Execute a quantum circuit on the MIMIQ remote services.

Optionally, additional include files can be provided to the computation.
These will be used instead of the default ones provided (and cached) by the service.
**NOTE**: Including standard files such as 'qelib1.inc' is not necessary, and might lead to slower computation.

The circuit is applied to the zero state and the resulting state is measured via sampling.
Optionally amplitudes corresponding to few selected bit states (or bitstrings) can be returned from the computation.

## Keyword Arguments

* `label::String`: mnemonic name to give to the simulation, will be visible on the [web interface](https://mimiq.qperfect.io)
* `algorithm`: algorithm to use by the compuation. By default `"auto"` will select the fastest algorithm between `"statevector"` or `"mps"`.
* `nsamples::Integer`: number of times to sample the circuit (default: 1000, maximum: 2^16)
* `bitstrings::Vector{BitString}`: list of bit states to compute the amplitudes for (default: `BitString[]`)
* `timelimit`: number of minutes before the computation is stopped (default: 5 minutes)
* `bonddim::Int`: bond dimension for the MPS algorithm (default: 256, maximum: 4096)
* `entdim::Int`: parameter to control pre compression of the circuit. Higher value makes simulations slower. (default: 16, minimum:4, maximum: 64)
* `seed::Int`: a seed for running the simulation (default: random seed)
"""
function executeqasm(
    conn::Connection,
    qasmfilepath::AbstractString,
    includefiles...;
    label::AbstractString="jlapi_$(_pkgversion(@__MODULE__))",
    algorithm::String=DEFAULT_ALGORITHM,
    nsamples=DEFAULT_SAMPLES,
    bitstrings::Vector{BitString}=BitString[],
    timelimit=DEFAULT_TIME_LIMIT,
    bonddim::Union{Nothing, Integer}=nothing,
    entdim::Union{Nothing, Integer}=nothing,
    seed::Int=rand(0:typemax(Int)),
)
    if nsamples > MAX_SAMPLES
        throw(ArgumentError("Number of samples should be less than 2^16"))
    end

    tempdir = mktempdir(; prefix="mimiq_")

    # check if the file exists
    if !isfile(qasmfilepath)
        throw(ArgumentError("$qasmfilepath: does not exist"))
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

    newincs = map(includefiles) do f
        if !isfile(f)
            throw(ArgumentError("$f: does not exist"))
        end

        incfile = joinpath(tempdir, basename(f))

        # copy the include file
        cp(f, incfile)

        return incfile
    end

    # prepare the parameters
    pars = Dict(
        "algorithm" => algorithm,
        "bitstrings" => string.(bitstrings),
        "samples" => nsamples,
        "seed" => seed,
    )

    # set the bond and entangling dimensions
    # pars["bondDimension"] = DEFAULT_BONDDIM or bonddim
    # pars["entDimension"] = DEFAULT_ENTDIM or entdim
    _setmpsdims!(pars, algorithm, bonddim, entdim)

    files = [Dict("name" => CIRCUITQASM_FILE, "hash" => circuitsha)]
    for f in newincs
        push!(files, Dict("name" => basename(f), "hash" => _gethash(f)))
    end

    # prepare the request
    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "files" => files,
        "parameters" => pars,
        "apilang" => "julia",
        "apiversion" => _pkgversion(@__MODULE__),
        "circuitsapiversion" => _pkgversion(MimiqCircuitsBase),
    )

    # write the request to a file
    reqfile = joinpath(tempdir, "parameters.json")

    open(reqfile, "w") do io
        write(io, JSON.json(req))
    end

    type = "CIRC"

    return MimiqLink.request(
        conn,
        type,
        algorithm,
        label,
        timelimit,
        reqfile,
        circuitfile,
        newincs...,
    )
end
