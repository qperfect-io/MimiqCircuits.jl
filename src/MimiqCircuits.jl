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
export execute

struct Results
    ex::Execution
    results::Dict
    samples::Dict{BitState, Int64}
    amplitudes::Dict{BitState, Float64}
end

function Base.show(io::IO, r::Results)
    println(io, "Results of execution $(r.ex):")
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
Optionally amplitudes corresponding to few selected bitstrings (or bit states) can be returned from the computation.

## Keyword Arguments

* `label`: mnemonic name to give to the simulation, will be visible on the [web interface](https://mimiq.qperfect.io)
* `algorithm`: algorithm to use by the compuation. By default `"automode"` will select the fastest algorithm between `"statevector"` or `"mps"`.
* `nsamples`: number of times to sample the circuit (default: 1000)
* `timelimit`: number of seconds before the computation is stopped (default: 300 seconds or 5 minutes)
* `bonddim`: bond dimension for the MPS algorithm (default: 256)
"""
function execute(
    conn::Connection,
    c::Circuit;
    label::AbstractString="circuitsimu",
    algorithm::String="automode",
    nsamples=1000,
    bs::Vector{BitState}=BitState[],
    timelimit=5 * 60,
    bonddim::Union{Nothing, Int64}=nothing,
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

    pars = Dict("algorithm" => algorithm, "bitstrings" => bs, "samples" => nsamples)

    if timelimit > 30 * 60
        error("Time limit should be less than 30 minutes")
    end

    if !isnothing(bonddim)
        if bonddim < 0 || bonddim > 2^12
            error("Bond dimension should be positive and maximum 4096")
        end
        pars["bondDimension"] = bonddim
    end

    req = Dict(
        "executor" => "Circuits",
        "timelimit" => timelimit,
        "files" => [Dict("name" => "circuit.json", "hash" => circuitsha)],
        "parameters" => pars,
    )

    # write the parameters to a file
    reqfile = joinpath(tempdir, "parameters.json")

    open(reqfile, "w") do io
        write(io, JSON.json(req))
    end

    MimiqLink.request(conn, algorithm, label, reqfile, circuitfile)
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
    while !isjobdone(conn, ex)
        sleep(interval)
    end

    infos = MimiqLink.requestinfo(conn, ex)

    if infos["status"] == "ERROR"
        error("Remote job errored.")
    end

    tmpdir = mktempdir(; prefix="mimiq_res_")

    names = MimiqLink.downloadresults(conn, ex, tmpdir)

    if ["results.json", "samples.bson", "amplitudes.bson"] ⊈ basename.(names)
        error("$ex is not a valid execution for MimiqCircuits: missing files")
    end

    results = JSON.parsefile(joinpath(tmpdir, "results.json"))
    samples = BSON.load(joinpath(tmpdir, "samples.bson"))
    amplitudes = BSON.load(joinpath(tmpdir, "amplitudes.bson"))

    Results(ex, results, samples, amplitudes)
end

end # module MimiqCircuits
