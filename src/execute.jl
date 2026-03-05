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
    submit(connection, circuit[; kwargs...])
    submit(connection, circuits[; kwargs...])
    submit(connection, circuit, noisemodel[; kwargs...])
    submit(connection, circuits, noisemodel[; kwargs...])

Submit and schedule a quantum circuit execution on the MIMIQ remote services.
Returns a Job object (non-blocking).

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
* `mpscutoff::Float64`: singular value truncation cutoff for MPS simulation. Smaller values give higher accuracy at increased cost. (default: up to remote)
* `remove_swaps::Bool`: whether or not to remove SWAP gates while permuting the qubits (default: up to remote)
* `canonicaldecompose::Bool`: whether or not to decompose the circuit into GateU and GateCX (default: up to remote)
* `fuse::Bool`: whether or not to fuse the gates in the circuit (default: up to remote)
* `reorderqubits`: whether or not to reorder the qubits in the circuit. Can be `true` (default reordering), `false` (no reordering), or a `Symbol`/`String` for a specific method (e.g., `:greedy`, `:spectral`, `:rcm`, `:sa_warm_start`, `:sa_only`, `:memetic`, `:multilevel`, `:grasp`, `:hybrid`). (default: up to remote)
* `reorderqubits_seed::Union{Nothing, Integer}`: independent seed for the qubit reordering RNG, allowing reproducible reordering independently of the simulation seed. (default: `nothing`, uses main seed)
* `seed::Int`: a seed for running the simulation (default: random seed)
* `mpsmethod::Symbol`: method to use for MPO application in MPS simulations. Can be `:dmpo` for direct application or `:vmpoa`/`:vmpob` for variational search. (default: up to remote)
* `mpotraversal::Symbol`: method to traverse the circuit while compressing it into MPOs. Can be `:sequential` (default) or `:bfs` (Breadth-First Search). (default: up to remote)
* `streaming::Bool`: whether or not to use the streaming simulator (default: `false`)

"""
submit(conn, c::Circuit; kwargs...) = submit(conn, [c]; kwargs...)
submit(conn, c::String; kwargs...) = submit(conn, [c]; kwargs...)

submit(conn, c::Circuit, nm::NoiseModel; kwargs...) = submit(conn, apply_noise_model(c, nm); kwargs...)
submit(conn, c::String, nm::NoiseModel; kwargs...) = throw(ArgumentError("Cannot apply NoiseModel to a file directly. Load the circuit first."))

function submit(conn, circuits::Vector, nm::NoiseModel; kwargs...)
    noisy_circuits = []
    for c in circuits
        if c isa Circuit
            push!(noisy_circuits, apply_noise_model(c, nm))
        else
            throw(ArgumentError("Cannot apply NoiseModel to non-Circuit objects in batch mode. Load circuits first."))
        end
    end
    return submit(conn, noisy_circuits; kwargs...)
end

function submit(conn, ex::CircuitTesterExperiment; kwargs...)
    c = build_circuit(ex)
    return submit(conn, c; kwargs...)
end

"""
    check_equivalence(conn, ex::CircuitTesterExperiment; kwargs...)

Executes the circuit tester experiment and verifies the results.
Blocks until the execution is complete.
"""
function check_equivalence(conn, ex::CircuitTesterExperiment; kwargs...)
    job = submit(conn, ex; kwargs...)
    results = getresult(conn, job)
    return interpret_results(ex, results)
end

function execute(conn, args...; kwargs...)
    @warn "execute(conn, ...) is deprecated and will be blocking in the future. Use submit(conn, ...) for non-blocking execution." maxlog =
        1
    return submit(conn, args...; kwargs...)
end

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

function submit(
    conn,
    circuits::Vector;
    label::AbstractString="jlapi_$(_pkgversion(@__MODULE__))",
    algorithm::String=DEFAULT_ALGORITHM,
    nsamples=DEFAULT_SAMPLES,
    bitstrings::Vector{BitString}=BitString[],
    timelimit=_gettimelimit(conn),
    bonddim::Union{Nothing, Integer}=nothing,
    entdim::Union{Nothing, Integer}=nothing,
    mpscutoff::Union{Nothing, Real}=nothing,
    remove_swaps::Union{Nothing, Bool}=nothing,
    canonicaldecompose::Union{Nothing, Bool}=nothing,
    fuse::Union{Nothing, Bool}=nothing,
    reorderqubits::Union{Nothing, Bool, Symbol, String}=nothing,
    reorderqubits_seed::Union{Nothing, Integer}=nothing,
    force::Bool=false,
    seed::Int=rand(0:typemax(Int)),

    mpsmethod::Union{Nothing, Symbol}=nothing,
    mpotraversal::Union{Nothing, Symbol}=nothing,
    streaming::Union{Nothing, Bool}=nothing,
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



    if !isnothing(mpsmethod)
        if mpsmethod in (:vmpoa, :vmpob, :dmpo)
            pars["mpsMethod"] = mpsmethod
        else
            throw(ArgumentError("Unknown MPS method: $mpsmethod"))
        end
    end

    if !isnothing(mpotraversal)
        if mpotraversal in (:sequential, :bfs)
            pars["mpoTraversal"] = mpotraversal
        else
            throw(ArgumentError("Unknown MPO traversal method: $mpotraversal"))
        end
    end

    if !isnothing(remove_swaps)
        pars["removeSwaps"] = remove_swaps
    end

    if !isnothing(canonicaldecompose)
        pars["canonicalDecompose"] = canonicaldecompose
    end

    if !isnothing(fuse)
        pars["fuse"] = fuse
    end

    if !isnothing(reorderqubits)
        pars["reorderQubits"] = reorderqubits
    end

    if !isnothing(reorderqubits_seed)
        pars["reorderQubitsSeed"] = reorderqubits_seed
    end

    if !isnothing(streaming)
        pars["streaming"] = streaming
    end

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
    _setmpsdims!(pars, algorithm, bonddim, entdim, mpscutoff; force=force)

    # write the parameters to a file
    parsfile = joinpath(tempdir, CIRCUITS_MANIFEST)

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
        circuitspath...,
    )
end
