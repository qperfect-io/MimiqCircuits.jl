module MimiqCircuits

using Reexport
using SHA
using BSON
using JSON
using MimiqLink

@reexport using Circuits
@reexport using MimiqLink:
    connect,
    savetoken,
    loadtoken,
    isjobdone,
    isjobfailed,
    isjobstarted,
    Connection,
    Execution

export Results
export simulate_clam
export simulate_csx

struct Results
    ex::Execution
    results::Dict
    sampled::Dict{BitVector, Int64}
    bitstrings::Dict{BitVector, Float64}
end

function Base.show(io, r::Results)
    println(io, "Results of execution $(r.ex):")
    println("├── fidelity: ", r.results["fidelity"])
    println("├── sampled $(length(r.sampled)) bitstrings")
    print("└── returned amplitudes of $(length(r.bitstrings)) bitstrings")
end

function _to_iobuffer(s::AbstractString)
    io = IOBuffer()
    write(io, s)
    seekstart(io)
    hash = sha2_256(io)
    seekstart(io)

    return io, hash
end

function _gethash(f::AbstractString)
    open(f, "r") do io
        sha2_256(io)
    end
end

"""
    simulate_csx(circuit; kwargs...)

# Keyword Arguments

* `nsamples`: Number of samples to take (default: 1000)
* `bs`: bitstrings for which we want to know the amplitudes (default: none)
* `timelimit` : time limit in seconds (default: 30 minutes)
"""
function simulate_csx(conn::Connection, c::Circuit, label::AbstractString; kwargs...)
    if haskey(kwargs, :bonddim)
        @warn "Bond dimension `bonddim` is not used for CSX"
    end

    _simulate("CSX", conn, c, label; kwargs...)
end

"""
    simulate_clam(circuit; kwargs...)

# Keyword Arguments

* `nsamples`: Number of samples to take (default: 1000)
* `bs`: bitstrings for which we want to know the amplitudes (default: none)
* `timelimit` : time limit in seconds (default: 30 minutes)
* `bonddim` : bond dimension (default: 256)
"""
function simulate_clam(
    conn::Connection,
    c::Circuit,
    label::AbstractString;
    bonddim::Union{Nothing, Int64}=256,
    kwargs...,
)
    _simulate("CLAM", conn, c, label; bonddim=bonddim, kwargs...)
end

function _simulate(
    emulator::String,
    conn::Connection,
    c::Circuit,
    label::AbstractString;
    nsamples=1000,
    bs::Vector{BitVector}=[],
    timelimit=30 * 60,
    bonddim::Union{Nothing, Int64}=Nothing,
)
    tempdir = mktempdir(; prefix="mimiq_")

    # write the circuit to a file
    circuitfile = joinpath(tempdir, "circuit.json")

    open(circuitfile, "w") do io
        write(io, Circuits.tojson(c))
    end

    circuitsha = _gethash(circuitfile)

    # prepare the parameters 
    if nsamples > 2^16
        error("Number of samples should be less than 2^16")
    end

    pars = Dict("emulator" => emulator, "bitstrings" => bs, "samples" => nsamples)

    if timelimit > 30 * 60
        error("Time limit should be less than 30 minutes")
    end

    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "files" => [Dict("name" => "circuit.json", "hash" => circuitsha)],
        "parameters" => pars,
    )

    if !isnothing(bonddim)
        if bonddim < 0 || bonddim > 2^12
            error("Bond dimension should be positive and maximum 4096")
        end
        req["bondDimension"] = bonddim
    end

    # write the parameters to a file
    reqfile = joinpath(tempdir, "parameters.json")

    open(reqfile) do io
        write(io, JSON.json(req))
    end

    MimiqLink.request(conn, emulator, label, reqfile, circuitfile)
end

"""
    getinputs(connection, execution)

Returns the circuit and parameters for the given execution.
"""
function getinputs(conn::Connection, ex::Execution)
    tmpdir = mktempdir(; prefix="mimiq_in_")
    names = MimiqLink.downloadjobfiles(conn, ex, tmpdir)

    if !("parameters.json" in names) || !("circuit.json" in names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    parameters = JSON.parsefile(joinpath(tmpdir, "parameters.json"))
    circuit = Circuits.fromjson(JSON.parsefile(joinpath(tmpdir, "circuit.json")))

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
    while !isjobdone(ex)
        sleep(interval)
    end

    infos = MimiqLink.requestinfo(conn, ex)

    if infos["status"] == "ERROR"
        error("Remote job errored.")
    end

    tmpdir = mktempdir(; prefix="mimiq_res_")

    names = MimiqLink.downloadresults(conn, ex, tmpdir)

    if !("results.json" in names) ||
       !("sampled.bson" in names) ||
       !("bitstrings.json" in names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    results = JSON.parsefile(joinpath(tmpdir, "results.json"))
    sampled = BSON.load(joinpath(tmpdir, "sampled.bson"))
    bitstrings = BSON.load(joinpath(tmpdir, "bitstrings.bson"))

    Results(ex, results, sampled, bitstrings)
end

end # module MimiqCircuits
