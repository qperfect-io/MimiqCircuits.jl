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
using QCSR
using MimiqLink
using RecipesBase
using PrettyTables
using Printf
import Measures

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
    Execution

export Results
export execute
export printreport
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

# maximum time limit allowed
const MAX_TIME_LIMIT = 30 * 60

# default time limit
const DEFAULT_TIME_LIMIT = 5 * 60

struct Results
    ex::Execution
    results::Dict
    samples::Dict{BitState, Int64}
    amplitudes::Dict{BitState, ComplexF64}
end

function _ptime(time::Number)
    if time < 1e-6
        return @sprintf "%.3gns" time * 1e9
    end
    if time < 1e-3
        return @sprintf "%.3gµs" time * 1e6
    end
    if time < 1e0
        return @sprintf "%.3gms" time * 1e3
    end
    return @sprintf "%.3gs" time
end

function Base.show(io::IO, r::Results)
    tot_time = sum(values(r.results["time"]))
    println(io, "Results of execution $(r.ex.id):")
    println("├── algorithm: ", r.results["algorithm"])
    println("├── time: ", _ptime(tot_time))
    println("├── fidelity: ", r.results["fidelity"])
    println("├── sampled $(length(r.samples)) bitstrings")
    print("└── returned $(length(r.amplitudes)) amplitudes")
end

function _to_iobuffer(s::AbstractString)
    io = IOBuffer()
    write(io, s)
    seekstart(io)
    hash = bytes2hex(sha2_256(io))
    seekstart(io)

    return io, hash
end

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
* `bitstates::Vector{BitState}`: list of bit states to compute the amplitudes for (default: `BitState[]`)
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
    bitstates::Vector{BitState}=BitState[],
    timelimit=DEFAULT_TIME_LIMIT,
    bonddim::Union{Nothing, Integer}=nothing,
    seed::Int64=rand(0:typemax(Int64)),
)
    if nsamples > MAX_SAMPLES
        throw(ArgumentError("Number of samples should be less than 2^16"))
    end

    tempdir = mktempdir(; prefix="mimiq_")

    # write the circuit to a file
    circuitfile = joinpath(tempdir, "circuit.json")

    open(circuitfile, "w") do io
        write(io, MimiqCircuitsBase.tojson(c))
    end

    circuitsha = _gethash(circuitfile)


    nq = numqubits(c)
    if any(b -> numqubits(b) != nq, bitstates)
        throw(
            ArgumentError(
                "Bitstates should have the same number of qubits of the circuit.",
            ),
        )
    end

    # prepare the parameters 

    pars = Dict(
        "algorithm" => algorithm,
        "bitstates" => bitstates,
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
    if timelimit > MAX_TIME_LIMIT
        throw(ArgumentError("Time limit should be less than 30 minutes"))
    end

    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "files" => [Dict("name" => "circuit.json", "hash" => circuitsha)],
        "parameters" => pars,
    )

    # write the request to a file
    reqfile = joinpath(tempdir, "parameters.json")

    open(reqfile, "w") do io
        write(io, JSON.json(req))
    end

    type = "example-type-1"
    MimiqLink.request(conn, type, algorithm, label, timelimit, reqfile, circuitfile)
end

"""
    getinputs(connection, execution)

Returns the circuit and parameters for the given execution.
"""
function getinputs(conn::Connection, ex::Execution)
    tmpdir = mktempdir(; prefix="mimiq_in_")
    names = MimiqLink.downloadjobfiles(conn, ex, tmpdir)

    if ["parameters.json", "circuit.json"] ⊈ basename.(names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    parameters = JSON.parsefile(joinpath(tmpdir, "parameters.json"))
    circuit = MimiqCircuitsBase.fromjson(JSON.parsefile(joinpath(tmpdir, "circuit.json")))

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
        error("Remote job errored.")
    end

    tmpdir = mktempdir(; prefix="mimiq_res_")

    names = MimiqLink.downloadresults(conn, ex, tmpdir)

    if ["results.json", "samples.qcsr", "amplitudes.qcsr"] ⊈ basename.(names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    results = JSON.parsefile(joinpath(tmpdir, "results.json"))

    samples = Dict(
        map(
            b -> BitState(first(b)) => last(b),
            QCSR.load(joinpath(tmpdir, "samples.qcsr")),
        ),
    )

    amplitudes = Dict(
        map(
            b -> BitState(first(b)) => last(b),
            QCSR.load(joinpath(tmpdir, "amplitudes.qcsr")),
        ),
    )

    Results(ex, results, samples, amplitudes)
end

@recipe function f(res::Results; endianess=:big, max_outcomes=15)
    x = []
    y = []
    for (bs, s) in res.samples
        push!(x, to01(bs; endianess=endianess))
        push!(y, s)
    end
    ps = sortperm(y; rev=true)
    permute!(x, ps)
    permute!(y, ps)

    # NOTE: this should come before the truncation
    nsamples = sum(y)

    x = x[1:min(length(x), max_outcomes)]
    nbars = length(x)

    y = y[1:nbars]

    nq = length(first(x))

    size := (800, 400 + 10 * nq)
    margin := 10Measures.mm
    bottom_margin := nq * 1.7Measures.mm

    @series begin
        seriestype := :bar
        yguide := "Counts / $nsamples"
        xguide := "Bit State"
        legend := nothing
        xrotation := 90
        xticks := ((1:nbars) .- 0.5, x)
        fill := "#0c7e8f"
        return x, y
    end
end


"""
    printreport(res::MimiqCircuits.Results; kwargs...)

Print a report on the MIMIQ simulation results `res`

## Keyword Arguments
* `max_outcomes`: the maximum number of unique measurement outcomes to display (default 8)
"""
function printreport(res::MimiqCircuits.Results; max_outcomes::Int=8)
    # pretty_table format
    tf = TextFormat(
        up_right_corner='=',
        up_left_corner='=',
        bottom_left_corner='=',
        bottom_right_corner='=',
        up_intersection=' ',
        left_intersection='=',
        right_intersection='=',
        middle_intersection=' ',
        bottom_intersection=' ',
        column=' ',
        row='=',
        hlines=[:begin, :header],
    )

    @printf "===========================\n"
    @printf "Simulation report\n"
    @printf "===========================\n"
    @printf "Algorithm:         %s\n" res.results["algorithm"]
    @printf "Execution time:    %s\n" _ptime(res.results["time"]["apply"])
    @printf "Sampling time:     %s\n" _ptime(res.results["time"]["sampling"])
    @printf "Fidelity estmate:  %.3f (avg. gate error %.4f)\n" res.results["fidelity"] res.results["averageGateError"]

    if length(res.samples) > 0
        outcomes =
            sort(collect(res.samples), by=x -> x.second, rev=true)[1:min(end, max_outcomes)]

        @printf "\n"
        @printf "Measurement results\n"

        table = permutedims(hcat([[to01(k), v] for (k, v) in outcomes]...))
        pretty_table(table, header=["state", "samples"], tf=tf)
        if length(outcomes) >= max_outcomes
            @printf "results limited to %i items, see `res.samples` for a full list\n" max_outcomes
        end
    end

    if length(res.amplitudes) > 0
        @printf "\n"
        @printf "Statevector amplitudes\n"

        table = permutedims(hcat([[to01(k), v] for (k, v) in res.amplitudes]...))
        pretty_table(table, header=["state", "amplitude"], tf=tf)
    end
end

end # module MimiqCircuits
