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

struct QCSError <: Exception
    msg::String
end

"""
    getinputs(connection, execution)

Returns the circuits and parameters for the given execution.

See also [`getinput`](@ref), [`getresults`](@ref), [`getresult`](@ref).
"""
function getinputs(conn, ex::Execution)
    tmpdir = mktempdir(; prefix="mimiq_in_")
    names = MimiqLink.downloadjobfiles(conn, ex, tmpdir)

    if "circuits.json" ∉ basename.(names)
        error(
            "$ex is not a valid execution for MimiqCircuits: missing 'circuits.json'. Downloaded files: $(basename.(names))",
        )
    end
    @info "Downloaded files: $(basename.(names))"

    parameters = JSON.parsefile(joinpath(tmpdir, "circuits.json"))

    circuits = []

    for circuit_info in parameters["circuits"]
        file = circuit_info["file"]
        file_path = joinpath(tmpdir, file)

        if endswith(file, EXTENSION_PROTO)
            push!(circuits, loadproto(file_path, Circuit))
        elseif endswith(file, EXTENSION_QASM)
            push!(circuits, file_path)
        elseif endswith(file, EXTENSION_STIM)
            push!(circuits, file_path)
        else
            error("Unsupported circuit file type for file: $file")
        end
    end

    return circuits, parameters
end

getinputs(conn, ex::String) = getinputs(conn, Execution(ex))

"""
    getinput(connection, execution)

Returns the first circuit and parameters for the given execution.

See also [`getinputs`](@ref), [`getresults`](@ref), [`getresult`](@ref).
"""
function getinput(conn, ex::Execution)
    circuits, parameters = getinputs(conn, ex)

    if length(circuits) > 1
        @warn "Multiple circuits found. Returning the first one."
    end

    return circuits[1], parameters
end

getinput(conn, ex::String) = getinput(conn, Execution(ex))

"""
    getresults(connection, execution[; interval=1])

Block until the given execution is finished and return the results.

##  Keyword Arguments

* `interval`: time interval in seconds to check for job completion (default: 1)

See also [`getinputs`](@ref), [`getinput`](@ref), [`getresult`](@ref).
"""
function getresults(conn, ex::Execution; interval=1)
    # wait for the job to finish
    while !isjobdone(conn, ex)
        sleep(interval)
    end

    infos = MimiqLink.requestinfo(conn, ex)

    if infos["status"] == "ERROR"
        if haskey(infos, "errorMessage")
            msg = infos["errorMessage"]
            error("Remote job errored: $msg")
        else
            error("Remote job errored. If the error persists, please contact support.")
        end
    elseif infos["status"] == "CANCELED"
        error("Remote job canceled.")
    end

    tmpdir = mktempdir(; prefix="mimiq_res_")

    # Download results and parse them
    names = MimiqLink.downloadresults(conn, ex, tmpdir)

    if RESULTS_FNAME ∉ basename.(names)
        error("No results found in $ex.")
    end

    results = JSON.parsefile(joinpath(tmpdir, RESULTS_FNAME))

    return map(results) do r
        if haskey(r, "error")
            return QCSError(r["error"])
        end

        fname = joinpath(tmpdir, r["file"])

        if !isfile(fname)
            error("Missing result file $fname")
        end
        return loadproto(joinpath(tmpdir, fname), QCSResults)
    end
end

getresults(conn, ex::String; kwargs...) = getresults(conn, Execution(ex); kwargs...)

"""
    getresult(connection, execution)

Returns the first circuit and parameters for the given execution.

See also [`getinputs`](@ref), [`getinput`](@ref), [`getresults`](@ref).
"""
function getresult(conn, ex::Execution; kwargs...)
    results = getresults(conn, ex; kwargs...)
    if length(results) > 1
        @warn "Multiple results found. Returning the first one."
    end
    return first(results)
end

getresult(conn, ex::String; kwargs...) = getresult(conn, Execution(ex); kwargs...)
