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
    optimize(connection, experiment[; kwargs...])
    optimize(connection, experiments[; kwargs...])

Run a classical optimization experiment using MIMIQ remote services.

This method uploads one or more `OptimizationExperiment`s to the server and launches a classical optimizer to find the best parameter values minimizing a cost function derived from quantum circuit measurements.

## Keyword Arguments

* `label::String`: mnemonic name for the optimization job (default: `"julia_"` + version string)
* `algorithm::String`: name of the optimization algorithm to use (default: `"auto"`)
* `nsamples::Int`: number of samples to collect per function evaluation (default: 1000, maximum: 2^16)
* `timelimit::Int`: maximum wall-clock time (in minutes) allowed for the job (default: connection limit or 30)
* `bonddim::Int`: bond dimension used by the MPS backend if applicable (default: 256, maximum: 4096)
* `entdim::Int`: entanglement dimension used to control circuit pre-compression (default: 16, range: 4–64)
* `mpscutoff::Float64`: singular value truncation cutoff for MPS simulation. Smaller values give higher accuracy at increased cost. (default: up to remote)
* `fuse::Bool`: whether to fuse gates prior to simulation (default: remote service decides)
* `reorderqubits::Bool`: whether to reorder qubits for improved simulation performance (default: remote service decides)
* `seed::Int`: random seed for reproducibility (default: random)
* `force::Bool`: force dimension parameters (default: false)
* `history::Bool`: whether to return the full optimization history (default: false)
"""

function optimize(
    conn::MimiqConnection,
    exs::Union{OptimizationExperiment, Vector{<:OptimizationExperiment}};
    label::AbstractString="julia_$(_pkgversion(@__MODULE__))",
    algorithm::String=DEFAULT_ALGORITHM,
    nsamples::Int=DEFAULT_SAMPLES,
    timelimit=_gettimelimit(conn),
    bonddim::Union{Nothing, Integer}=nothing,
    entdim::Union{Nothing, Integer}=nothing,
    mpscutoff::Union{Nothing, Real}=nothing,
    fuse::Union{Nothing, Bool}=nothing,
    reorderqubits::Union{Nothing, Bool}=nothing,
    force::Bool=false,
    seed::Int=rand(0:typemax(Int)),
    history::Bool=false,
)
    if nsamples > MAX_SAMPLES
        throw(ArgumentError("Number of samples should be ≤ $(MAX_SAMPLES)"))
    end

    maxtime = _gettimelimit(conn)
    if timelimit > maxtime
        throw(ArgumentError("Time limit exceeds maximum allowed ($maxtime minutes)"))
    end

    tempdir = mktempdir(; prefix="mimiq_opt_")

    # Always treat exs as a list
    exlist = exs isa OptimizationExperiment ? [exs] : exs

    experfiles = String[]
    experentries = Dict{String, Any}[]

    for (i, ex) in enumerate(exlist)
        fname = "experiment_$i.$EXTENSION_PROTO"
        fpath = joinpath(tempdir, fname)
        saveproto(fpath, ex)
        push!(experfiles, fpath)
        push!(experentries, Dict("file" => fname, "type" => TYPE_PROTO))
    end

    # Prepare parameter dictionary
    pars = Dict(
        "experiments" => experentries,
        "algorithm" => algorithm,
        "samples" => nsamples,
        "seed" => seed,
        "history" => history,
    )

    if !isnothing(fuse)
        pars["fuse"] = fuse
    end

    if !isnothing(reorderqubits)
        pars["reorderQubits"] = reorderqubits
    end

    _setmpsdims!(pars, algorithm, bonddim, entdim, mpscutoff; force=force)

    # Write parameter file
    parsfile = joinpath(tempdir, OPTIMIZE_MANIFEST)
    open(parsfile, "w") do io
        write(io, JSON.json(pars))
    end

    # Write request metadata
    req = Dict(
        "executor" => "Optimize",
        "timelimit" => timelimit,
        "apilang" => "julia",
        "apiversion" => _pkgversion(@__MODULE__),
        "circuitsapiversion" => _pkgversion(MimiqCircuitsBase),
    )

    reqfile = joinpath(tempdir, REQUEST_MANIFEST)
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
        experfiles...,
    )
end
