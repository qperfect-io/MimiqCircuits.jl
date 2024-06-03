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
    execute(connection, circuit[; kwargs...])

Execute a quantum circuit on the MIMIQ remote services.

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
function execute(
    conn::Connection,
    c::Circuit;
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

    # set the bond and entangling dimensions
    # pars["bondDimension"] = DEFAULT_BONDDIM or bonddim
    # pars["entDimension"] = DEFAULT_ENTDIM or entdim
    _setmpsdims!(pars, algorithm, bonddim, entdim)

    # prepare the request
    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "files" => [Dict("name" => CIRCUITPB_FILE, "hash" => circuitsha)],
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

    return MimiqLink.request(conn, type, algorithm, label, timelimit, reqfile, circuitfile)
end
